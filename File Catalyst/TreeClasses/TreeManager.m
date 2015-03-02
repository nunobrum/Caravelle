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

@implementation TreeManager

-(TreeManager*) init {
    self->iArray = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileSystemChangePath:) name:notificationDirectoryChange object:nil];
    return self;
}

-(BOOL) startAccessToURL:(NSURL*)url {
#if (APP_IS_SANDBOXED==YES)
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
#if (APP_IS_SANDBOXED==YES)
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

-(TreeBranch*) addTreeItemWithURL:(NSURL*)url {
    NSUInteger index=0;
    TreeBranch *answer=nil;
    BOOL iArrayChanged = NO;
    id parent =  nil;
    while (index < [self->iArray count]) {
        TreeBranch *item = self->iArray[index++];
        enumPathCompare comparison = [item relationToPath:[url path]];
        if (comparison == pathIsSame) {
            return item;
        }
        else if (comparison == pathIsChild) {
            TreeItem *aux = [item addURL:url];
            if (aux) {
                if ([aux isKindOfClass:[TreeBranch class]])
                    return (TreeBranch*)aux;
                else if ([aux parent]) {
                    if ([[aux parent] isKindOfClass:[TreeBranch class]])
                    return (TreeBranch*)[aux parent];
                }
                else {
                    NSLog(@"TreeManager.addTreeItemWithURL: - Error: The URL was not created");
                }
            }
            index++;
        }
        else if (comparison==pathIsParent) {
            NSURL *url_allowed;
#if (APP_IS_SANDBOXED==YES)
            url_allowed =[self secScopeContainer:url];
            // checks if part of the allowed urls
            if (url_allowed==nil) {
                // if fails then will open it with a Powerbox
                NSString *title = [NSString stringWithFormat:@"Access Denied! Please grant access to Folder %@", [url path]];
                url = [self powerboxOpenFolderWithTitle:title];
                if (url!=nil) {
                    url_allowed = url;
                }
            }
#else
            url_allowed = url;
#endif
            if (url_allowed!=nil) {
                /* Will add this to the node being inserted */
                NSUInteger level = [[url_allowed pathComponents] count]; // Get the level above the new root;
                NSArray *pathComponents = [[item url] pathComponents];
                NSUInteger top_level = [pathComponents count]-1;
                if (parent==nil) {
                    parent =[TreeItem treeItemForURL:url parent:nil];
                }
                if ([parent isKindOfClass:[TreeBranch class]]) {
                    [parent setTag:tagTreeItemDirty]; // Will force the refresh
                    answer = parent;
                    TreeBranch *cursor = parent;
                    while (level < top_level) {
                        NSString *path = pathComponents[level];
                        TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
                        if (child==nil) {
                            NSRange rng;
                            rng.location=0;
                            rng.length = level+1;
                            NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                            child = [cursor addURL:newURL];
                        }
                        if ([child isBranch]) {
                            cursor = (TreeBranch*)child;
                            [cursor setTag:tagTreeItemDirty];
                            level++;
                        }
                        else
                            return nil; //Failing here is serious . Giving up search
                    }
                    [cursor addChild:item]; // Finally add the node
                    @synchronized(self) {
#if (APP_IS_SANDBOXED==YES)

                        TreeBranch *item_to_release = [self->iArray objectAtIndex:index-1];
                        [[item_to_release url] stopAccessingSecurityScopedResource];
#endif
                        [self->iArray removeObjectAtIndex:index-1]; // Remove the node, 1 is subtracted since one was already added
                        iArrayChanged = YES;
                    }
                }
            }
        }
    }
    if (answer==nil) { // If not found in existing trees will create it
        NSURL *url_allowed;
#if (APP_IS_SANDBOXED==YES)
        url_allowed =[self secScopeContainer:url];
        // checks if part of the allowed urls
        if (url_allowed==nil) {
            // if fails then will open it with a Powerbox
            NSString *title = [NSString stringWithFormat:@"Access Denied! Please grant access to Folder %@", [url path]];
            url = [self powerboxOpenFolderWithTitle:title];
            if (url!=nil) {
                url_allowed = url;
            }
        }
#else
        url_allowed = url;
#endif
        if (url_allowed) {
            id aux = [TreeItem treeItemForURL:url_allowed parent:nil];
            [aux setTag:tagTreeItemDirty]; // Forcing its update
            // But will only return it if is a Branch Like
            if ([aux isBranch]) {
                if (pathIsSame == url_relation(url_allowed,url)) {
                    answer = aux;
                }
                else {
                    TreeItem *ti;
                    ti = [aux getNodeWithURL:url];
                    if (ti==nil) // didn't find, will have to create it
                        ti = (TreeBranch*)[aux addURL:url];
                    // sanity check before assigning
                    if (ti!=nil && [ti isKindOfClass:[TreeBranch class]])
                        answer = (TreeBranch*) ti;
                }
#if (APP_IS_SANDBOXED==YES)
                [[aux url] startAccessingSecurityScopedResource];
#endif
                @synchronized(self) {
                    [self->iArray addObject:aux]; // Adds the Security Scope Element
                }
                iArrayChanged = YES;
            }
        }
    }
    else if (parent!=nil) { // There is a new parent
#if (APP_IS_SANDBOXED==YES)
        [[parent url] startAccessingSecurityScopedResource];
#endif
        @synchronized(self) {
            [self->iArray addObject:parent];
        }
        iArrayChanged = YES;
    }
    if (iArrayChanged) { // Will changed the monitored directories

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

-(void) addTreeBranch:(TreeBranch*)node {
    TreeBranch *cursor=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item canContainURL:[node url]]) {
            cursor = item;
            break;
        }
    }
    if (cursor) { // There is already a root containing this node. Will find it and add it
        NSUInteger level = [[[cursor url] pathComponents] count]; // Get the level of the root;
        NSArray *pathComponents = [[node url] pathComponents];
        NSUInteger top_level = [pathComponents count]-1;
        while (level < top_level) {
            NSString *path = pathComponents[level];
            TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
            if (child==nil) {
                NSRange rng;
                rng.location=0;
                rng.length = level;
                NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                child = [TreeItem treeItemForURL:newURL parent:cursor];
                [child setTag:tagTreeItemDirty];
            }
            level++;
            cursor = (TreeBranch*)child;
        }
        [cursor addChild:node]; // Finally add the node
    }
    else {
        [self->iArray addObject:node];
    }
}

-(void) removeTreeBranch:(TreeBranch*)node {
    @synchronized(self) {
        [self->iArray removeObject:node];
    }
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

                if ([itemToRefresh respondsToSelector:@selector(refreshBranchOnQueue:)]) {
                    [itemToRefresh setTag:tagTreeItemDirty];
                    [itemToRefresh refreshBranchOnQueue:operationsQueue];
                }
                else {
                        NSLog(@"TreeManager:fileSystemChangePath: Not implemented ! Not expected to receive non branches.\nReceived ""%@""", changedPath);
                    }
            }
            else
            {
                //NSLog(@"TreeManager.fileSystemChangePath: - Refreshing (%@)", changedPath);
                if ([itemToRefresh respondsToSelector:@selector(refreshContentsOnQueue:)]) {
                    [itemToRefresh setTag:tagTreeItemDirty];
                    [itemToRefresh refreshContentsOnQueue:operationsQueue];
                }
                else { // It will try to refresh the parent
                    id itemParent = [itemToRefresh parent];
                    if ([itemParent respondsToSelector:@selector(refreshContentsOnQueue:)]) {
                        [itemParent setTag:tagTreeItemDirty];
                        [itemParent refreshContentsOnQueue:operationsQueue];
                    }
                }
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
#if (APP_IS_SANDBOXED==YES)
        NSError *error;
        // Store the Bookmark for another Application Launch
        NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                         includingResourceValuesForKeys:urlKeyFieldsToStore()
                                          relativeToURL:nil error:&error];
        if (error==nil) {
            // Add the the User Defaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *secScopeBookmarks = [defaults objectForKey:@"SecurityScopeBookmarks"];
            NSMutableArray *updtSecScopeBookmarks =[NSMutableArray arrayWithArray:secScopeBookmarks];
            [updtSecScopeBookmarks addObject:bookmark];
            [defaults setObject:updtSecScopeBookmarks forKey:@"SecurityScopeBookmarks"];
        }
#endif
        return url;

    }
    return nil;
}

- (NSURL*) secScopeContainer:(NSURL*) url {
    NSURL *url_accessible = nil;
    NSArray *secBookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"SecurityScopeBookmarks"];

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
            enumPathCompare compare = url_relation(allowedURL, url);
            if (compare==pathIsChild || compare == pathIsSame) {
                url_accessible = allowedURL;
                break;
            }
        }
    }
    return url_accessible;
}

@end
