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

NSString *notificationRefreshViews = @"RefreshViews";

TreeManager *appTreeManager;

@implementation TreeManager

-(TreeManager*) init {
    self->iArray = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileSystemChangePath:) name:notificationDirectoryChange object:nil];
    return self;
}


-(TreeBranch*) addTreeItemWithURL:(NSURL*)url {
    NSUInteger index=0;
    TreeBranch *answer=nil;
    BOOL iArrayChanged = NO;
    id parent =  nil;
    while (index < [self->iArray count]) {
        TreeBranch *item = self->iArray[index];
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
            /* Will add this to the node being inserted */
            NSUInteger level = [[url pathComponents] count]; // Get the level above the new root;
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
                    [self->iArray removeObjectAtIndex:index]; // Remove the node, It will
                    iArrayChanged = YES;
                }
            }
            else {
                index++;
            }
        }
        else
            index++;
    }
    if (answer==nil) { // If not found in existing trees will create it
        id aux = [TreeItem treeItemForURL:url parent:nil];
        [aux setTag:tagTreeItemDirty]; // Forcing its update
        // But will only return it if is a Branch Like
        if ([aux isBranch]) {
            answer = aux;
            @synchronized(self) {
                [self->iArray addObject:answer];
            }
            iArrayChanged = YES;
        }
    }
    else if (parent!=nil) { // There is a new parent
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

        NSURL *aURL = [NSURL fileURLWithPath:changedPath isDirectory:YES]; // Assuming that we are always going to receive directories.
        id itemToRefresh = [self getNodeWithURL:aURL];

        if  (itemToRefresh != nil) { // Its already being monitored
            BOOL scanSubdirs = (flags &
                                (kFSEventStreamEventFlagMustScanSubDirs |
                                 kFSEventStreamEventFlagUserDropped |
                                 kFSEventStreamEventFlagKernelDropped))!=0;
            if (scanSubdirs) {
                NSLog(@"TreeManager.fileSystemChangePath: - System is asking a full rescan of the tree:\n%@", changedPath);

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
                NSLog(@"TreeManager.fileSystemChangePath: - Refreshing (%@)", changedPath);
                if ([itemToRefresh respondsToSelector:@selector(refreshContentsOnQueue:)]) {
                    [itemToRefresh setTag:tagTreeItemDirty];
                    [itemToRefresh refreshContentsOnQueue:operationsQueue];
                }
                else {
                    NSLog(@"TreeManager:fileSystemChangePath: Not implemented ! Not expected to receive non branches.\nReceived ""%@""", changedPath);
                }
            }
        }
    }
}

@end
