//
//  TreeManager.m
//  File Catalyst
//
//  Created by Nuno Brum on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeManager.h"
//#import "TreeBranch_TreeBranchPrivate.h"
#import "FileUtils.h"
#import "MyDirectoryEnumerator.h"

NSString *notificationRefreshViews = @"RefreshViews";

TreeManager *appTreeManager;


@interface PathObserver : NSObject
@property id<PathObserverProtocol>  observer;
@property NSString *path;
-(instancetype) initWithPath:(NSString*)path observer:(id)Observer;
@end

@implementation PathObserver
-(instancetype) initWithPath:(NSString*)path observer:(id)Observer {
    self = [super init];
    self.path = path;
    self.observer = Observer;
    return self;
}

@end

@implementation TreeManager {
    NSMutableArray *pathObservers;
}

-(TreeManager*) init {
    self = [super init];
    self->iArray = [[NSMutableArray alloc] init];
    self->pathObservers = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileSystemChangePath:) name:notificationDirectoryChange object:nil];
    return self;
}

-(BOOL) startAccessToURL:(NSURL*)url {
#if (APP_IS_SANDBOXED==1)
    for (TreeBranch *item in self->iArray) {
        if ([item canContainURL: url]) {
            [[item url] startAccessingSecurityScopedResource];
            return YES;
        }
    }
#endif
    return NO;
}


-(void) stopAccesses {
#if (APP_IS_SANDBOXED==1)
    for (TreeBranch *item in self->iArray) {
        [[item url] stopAccessingSecurityScopedResource];
    }
#endif
}

-(void) dealloc {
    [self stopAccesses];
    //self->iArray = nil;
    //[super dealloc];
}


-(TreeBranch*) addTreeItemWithURL:(NSURL*)url askIfNeeded:(BOOL)askIfNeeded {
    NSUInteger index=0;
    TreeBranch *answer=nil;

    while (index < [self->iArray count]) {
        TreeBranch *item = self->iArray[index];
        enumPathCompare comparison = [item relationToPath:[url path]];
        if (comparison == pathIsSame) {
            return item;
        }
        else if (comparison == pathIsChild) {
            TreeItem *aux = [item addURL:url];
            if (aux) {
                // NOTE: isKindOfClass is preferred over itemType.
                if ([aux isKindOfClass:[TreeBranch class]])
                    return (TreeBranch*)aux;
                else if ([aux parent]) {
                    // NOTE: isKindOfClass is preferred over itemType.
                    if ([[aux parent] isKindOfClass:[TreeBranch class]])
                    return (TreeBranch*)[aux parent];
                }
                else {
                    NSAssert(NO, @"TreeManager.addTreeItemWithURL: - Error: Invalid Class ""%@""", [aux class]);
                }
            }
            else {
                NSAssert(NO, @"TreeManager.addTreeItemWithURL: - Error: The URL was not created");
            }
            break;
        }
        else if (comparison==pathIsParent) {
            if (answer==nil) {
                // creates the new node and replaces the existing one.
                // It will inclose the former in itself.
                // If the path is a parent, then inherently it should be a Branch
                answer = (TreeBranch*)[self sandboxTreeItemFromURL:url askIfNeeded:askIfNeeded];
                if (answer!=nil) {
                    BOOL OK = [self addTreeItem:item To:(TreeBranch*)answer];
                    if (OK) {
                        // answer can now replace item in iArray.
                        @synchronized(self) {
#if (APP_IS_SANDBOXED==1)
                            [[item url] stopAccessingSecurityScopedResource];
#endif
                            [self->iArray setObject:answer atIndexedSubscript:index];
                        }
                    }
                }
                else {
                    return nil; // The user refused, or authorization doesn't exist. Exiting. no use to continue
                }
                index++; // Since the item was replaced, move on to the next
            }
            else {
                // In this case, what happens is that the item can be removed and added into answer
                BOOL OK = [self addTreeItem:item To:(TreeBranch*)answer];
                if (OK) {
                    // answer can now replace item in iArray.
                    @synchronized(self) {
#if (APP_IS_SANDBOXED==1)
                        [[item url] stopAccessingSecurityScopedResource];
#endif
                        [self->iArray removeObjectAtIndex:index];
                    }
                }
                else {
                    return nil; // Failed to create the parent
                }
            }
        }
        else {
            index++; // If paths are unrelated just increment to the next item
        }

    }
    if (answer==nil) { // If not found in existing trees will create it
        answer = (TreeBranch*)[self sandboxTreeItemFromURL:url askIfNeeded:askIfNeeded];
        if (answer) {
            @synchronized(self) {
                [self->iArray addObject:answer]; // Adds the Security Scope Element
            }
        }
    }

    if (answer!=nil) { //
#if (APP_IS_SANDBOXED==1)
        [[answer url] startAccessingSecurityScopedResource];
#endif

        // If the thread exist kill it
        if (FSMonitorThread!=nil) {
            [FSMonitorThread cancel];
        }
        FSMonitorThread = [[FileSystemMonitoring alloc] init];

        // Change the list of surveilances
        [FSMonitorThread configureFSEventStream:iArray];
        //Start the loop
        [FSMonitorThread start];
    }
    enumPathCompare comparison = url_relation([answer url], url);
    if (comparison == pathIsChild) {
        // If in the case that the user selected a parent of the desired URL
        return (TreeBranch*)[answer addURL:url];
    }
    return answer;
}

-(TreeItem*) getNodeWithURL:(NSURL*)url {
    TreeItem *answer=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item canContainURL:url]) {
            answer = [item getNodeWithURL:url];
            break;
        }
    }
    return answer;
}

-(TreeItem*) getNodeWithPath:(NSString*)path {
    TreeItem *answer=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item canContainPath:path]) {
            answer = [item getNodeWithPath:path];
            break;
        }
    }
    return answer;
}

-(BOOL) addTreeItem:(TreeItem*)node To:(TreeBranch*)destination{
    if ([destination canContainURL:[node url]]) {
        NSUInteger level = [[[destination url] pathComponents] count]; // Get the level of the root;
        NSArray *pathComponents = [[node url] pathComponents];
        NSUInteger top_level = [pathComponents count]-1;
        TreeBranch *cursor = destination;

        while (level < top_level) {
            NSString *path = pathComponents[level];
            TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
            if (child==nil) {
                NSRange rng;
                rng.location=0;
                rng.length = level+1;
                NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                child = [TreeItem treeItemForURL:newURL parent:cursor];
                [child setTag:tagTreeItemDirty];
            }
            level++;
            cursor = (TreeBranch*)child;
        }
        [cursor addChild:node]; // Finally add the node
        return YES;
    }
    else
        return NO;
}


-(void) fileSystemChangePath:(NSNotification *)note {
    NSDictionary *info = [note userInfo];
    NSString *changedPath = [info objectForKey:pathsKey];
    NSInteger flags = [[info objectForKey:flagsKey] integerValue];

    if (flags & kFSEventStreamEventFlagRootChanged) { // When the parent is moved deleted or renamed.
        // Delete this from iArray and send messages to BrowserControllers for the objects to be deleted
        // Strategy : Mark item with a deletion mark and notify App->Browser Views
        NSURL *aURL = [NSURL fileURLWithPath:changedPath isDirectory:YES]; // Assuming that we are always going to receive directories.

        TreeItem *itemToRelease = [self getNodeWithURL:aURL];
        [itemToRelease setTag:tagTreeItemRelease]; // In case there are objects using it it will be deleted

        if ([itemToRelease parent]!=nil)
            [itemToRelease removeItem]; // Removes it from its parent
        else { // otherwise its on iArray
            [itemToRelease deinit];
            [iArray removeObject:itemToRelease]; // In this case BrowserTrees must be updated
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationRefreshViews object:self userInfo:nil];
        }

    }
    else if (flags & ( // Ignored Flags
            kFSEventStreamEventFlagEventIdsWrapped | //When the EventId wraps around on the 64 bit counter
            kFSEventStreamEventFlagHistoryDone      // When using the "EventsSinceDate" Not used.
            )) {

        /* Do Nothing Here. This condition is here for further implementation */

    }
    else { // Will make a refresh
        /* Other events that can be processed
         kFSEventStreamEventFlagItemCreated,
         kFSEventStreamEventFlagItemRemoved,
         kFSEventStreamEventFlagItemInodeMetaMod,
         kFSEventStreamEventFlagItemRenamed ,
         kFSEventStreamEventFlagItemModified,
         kFSEventStreamEventFlagItemFinderInfoMod,
         kFSEventStreamEventFlagItemChangeOwner,
         kFSEventStreamEventFlagItemXattrMod,
         kFSEventStreamEventFlagItemIsFile,
         kFSEventStreamEventFlagItemIsDir,
         kFSEventStreamEventFlagItemIsSymlink,
         kFSEventStreamEventFlagOwnEvent,
         kFSEventStreamEventFlagMount,           | // When a mount is done underneath the paths being monitored.
         kFSEventStreamEventFlagUnmount, // When a device is unmounted underneath the path being monitored.
         */

        //NSLog(@"FSEvent %@", changedPath);
        //LogFlags(flags);

        id itemToRefresh = [self getNodeWithPath:changedPath];
        if (itemToRefresh==nil) {// This could be because its a new File
            // Then force a refresh to the parent directory
            itemToRefresh = [self getNodeWithPath:[changedPath stringByDeletingLastPathComponent]];
        }

        if  (itemToRefresh != nil) { // Its already being monitored
            BOOL scanSubdirs = (flags &
                                (kFSEventStreamEventFlagMustScanSubDirs |
                                 kFSEventStreamEventFlagUserDropped |
                                 kFSEventStreamEventFlagKernelDropped))!=0;
            if (scanSubdirs) {
                //NSLog(@"TreeManager.fileSystemChangePath: - System is asking a full rescan of the tree:\n%@", changedPath);

                if ([itemToRefresh respondsToSelector:@selector(forceRefreshOnBranch)]) {
                    [itemToRefresh forceRefreshOnBranch];
                }
                else {
                        NSLog(@"TreeManager:fileSystemChangePath: Not implemented ! Not expected to receive non branches.\nReceived ""%@""", changedPath);
                    }
            }
            else
            {
//                if (applicationMode & ApplicationModeDupBrowser) {
//                    // TODO:!!!!!! Remove this mute
//                    NSLog(@"Muting refresh on folder (%@)", changedPath);
//                }
//                else {
                //NSLog(@"TreeManager.fileSystemChangePath: - Refreshing (%@)", changedPath);
                if ([itemToRefresh respondsToSelector:@selector(refresh)]) {
                    [itemToRefresh setTag:tagTreeItemDirty];
                    [itemToRefresh refresh];
                }
                else {
                    // It will try to refresh the parent
                    id itemParent = [itemToRefresh parent];
                    if ([itemParent respondsToSelector:@selector(refresh)]) {
                        [itemParent setTag:tagTreeItemDirty];
                        [itemParent refresh];
                    }
                }
                //}
            }
        }
        // Now Going to process the observers
        for (PathObserver *elem in self->pathObservers) {
            enumPathCompare pc = path_relation(elem.path, changedPath);
            if (pc == pathIsChild) {
                [elem.observer pathHasChanged:changedPath];
            }
        }
    }
}

-(NSURL*) powerboxOpenFolderWithTitle:(NSString*)dialogTitle {
    NSOpenPanel *SelectDirectoryDialog = [NSOpenPanel openPanel];
    [SelectDirectoryDialog setTitle:dialogTitle];
    [SelectDirectoryDialog setCanChooseFiles:NO];
    [SelectDirectoryDialog setCanChooseDirectories:YES];
    NSInteger returnOption =[SelectDirectoryDialog runModal];
    if (returnOption == NSFileHandlingPanelOKButton) {
        /* Will get a new node from shared tree Manager and add it to the root */
        /* This addTreeBranchWith URL will retrieve from the treeManager if not creates it */

        NSURL *url = [SelectDirectoryDialog URL];
#if (APP_IS_SANDBOXED==1)
        // Verify if the URL is already on the list
        if ([self secScopeContainer:url]==nil) {
            // it isnt on the list, going to add it
            [self->authorizedURLs addObject:url];

            // First check if the Bookmarks already exists, if it doesnt, then it creates it
            if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_STORE_BOOKMARKS]) {
                NSError *error;
                // Store the Bookmark for another Application Launch
                NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                 includingResourceValuesForKeys:urlKeyFieldsToStore()
                                                  relativeToURL:nil error:&error];
                if (error==nil) {
                    // Add the the User Defaults
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    NSArray *secScopeBookmarks = [defaults arrayForKey:USER_DEF_SECURITY_BOOKMARKS];
                    NSMutableArray *updtSecScopeBookmarks =[NSMutableArray arrayWithArray:secScopeBookmarks];
                    [updtSecScopeBookmarks addObject:bookmark];
                    [defaults setObject:updtSecScopeBookmarks forKey:USER_DEF_SECURITY_BOOKMARKS];
                    [defaults synchronize];
                }
            }
        }
#endif
        return url;

    }
    return nil;
}


// This selector verifies if an URL is authorized or not, if yes, it returns a security approved version of it
// otherwise it returns nil
- (NSURL*) secScopeContainer:(NSURL*) url {
    // First check if the allowedURLs is already loaded
    if (self->authorizedURLs==nil) {
        // load it from the NS User Defaults
        NSArray *secBookmarks = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_SECURITY_BOOKMARKS];
        self->authorizedURLs = [NSMutableArray arrayWithCapacity:[secBookmarks count]];

        // Retrieve allowed URLs
        for (NSData *bookmark in secBookmarks) {
            BOOL dataStalled;
            NSError *error;
            NSURL *allowedURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                          options:NSURLBookmarkResolutionWithSecurityScope
                                                    relativeToURL:nil
                                              bookmarkDataIsStale:&dataStalled
                                                            error:&error];
            if (error==nil && dataStalled==NO) {
                [self->authorizedURLs addObject:allowedURL]; // Store it for future use
            }
        }
    }
    for (NSURL *allowedURL in self->authorizedURLs) {
        enumPathCompare compare = url_relation(allowedURL, url);
        if (compare==pathIsChild || compare == pathIsSame) {
            return  allowedURL;
        }
    }
    return nil;
}

-(NSURL*) validateURSecurity:(NSURL*) url {
    NSURL *url_allowed;
#if (BEFORE_POWERBOX_ALERT==1)
    // if fails then will open it with a Powerbox
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Proceed"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSString *friendlyTitle = pathFriendly(url);
    NSString *title = [NSString stringWithFormat:@"Caravelle was requested to access to Folder\n%@", friendlyTitle];
    
    [alert setMessageText:title];
    [alert setInformativeText:@"Caravelle respects Apple security guidelines, and in order to proceed it requires you to formally grant access to the folder indicated. Accesses can be revoked in the preferences panel."];
    
    [alert setAlertStyle:NSWarningAlertStyle];
    NSModalResponse reponse = [alert runModal];
    if (reponse == NSAlertFirstButtonReturn) {
        title = [NSString stringWithFormat:@"Please grant access to Folder %@", friendlyTitle];
        url_allowed = [self powerboxOpenFolderWithTitle:title];
    }
#else
    NSString *title = [NSString stringWithFormat:@"Please grant access to Folder %@", friendlyTitle];
    url_allowed = [self powerboxOpenFolderWithTitle:title];
#endif
#if (AFTER_POWERBOX_INFORMATION==1)
    // TODO:!! Make this a information with a checkbox to skip future messages
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    
    [alert setMessageText:@"Information"];
    [alert setInformativeText:@"Authorizations given to Caravelle can be revoked in the User Preferences Menu."];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
    
#endif
    
    return url_allowed;
}

- (TreeItem*) sandboxTreeItemFromURL:(NSURL*) url askIfNeeded:(BOOL)askIfNeeded {
    TreeItem *answer = nil;
    NSURL *url_allowed;
#if (APP_IS_SANDBOXED==1)
    url_allowed =[self secScopeContainer:url];
    // checks if part of the allowed urls
    if (url_allowed==nil && askIfNeeded) {
        url_allowed =[self validateURSecurity:url];
    }
#else
    url_allowed = url;
#endif
    if (url_allowed) {
        enumPathCompare comp = url_relation(url_allowed, url);
        if (comp!=pathIsChild && comp != pathIsSame) {
            // NSAlert telling that the program will proceed with this new URL
            NSAlert *info = [[NSAlert alloc] init];
            [info setMessageText:@"Proceeding with indicated Folder"];
            [info addButtonWithTitle:@"OK"];
            [info setInformativeText:@"The Opened Folder is different from requested"];
            [info setAlertStyle:NSInformationalAlertStyle];
            [info runModal];
             
        }
        answer = [TreeItem treeItemForURL:url_allowed parent:nil];
        [answer setTag:tagTreeItemDirty]; // Forcing its update
    }
    return answer;
}

-(void) addActivityObserver:(NSObject<PathObserverProtocol>*)obj path:(NSString*)path {
    // Assure that path is already being observed.
    if ([self getNodeWithPath:path]==nil) {
        // This means it is not being obeserved
        // The next instruction a
        TreeBranch *branch = [self addTreeItemWithURL:[NSURL fileURLWithPath:path isDirectory:NO] askIfNeeded:NO];
        NSAssert(branch!=nil,@"TreeManager.addActivityObserver:path: Failed to create an observing for path:%@", path);
    }
    PathObserver *observeElem = [[PathObserver alloc] initWithPath:path observer:obj];
    [self->pathObservers addObject:observeElem];
}

-(void) removeActivityObserver:(id)obj {
    NSInteger i = 0;
    while (i < [self->pathObservers count]) {
        PathObserver *elem = self->pathObservers[i];
        if ([elem.observer isEqual:obj])
            [self->pathObservers removeObjectAtIndex:i];
        else
            i++;
    }
}

@end
