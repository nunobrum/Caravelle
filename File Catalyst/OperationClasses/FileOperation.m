//
//  FileOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileOperation.h"
#import "FileUtils.h"

//#define UPDATE_TREE


NSString *notificationFinishedFileOperation = @"FinishedFileOperation";

@implementation FileOperation

-(void) main {
    BOOL  OK = NO;  // Assume it will go wrong until proven otherwise
    BOOL send_notification=YES;
    NSError *error = nil;
    if (![self isCancelled])
	{
        NSArray *items = [_taskInfo objectForKey: kDFOFilesKey];
        NSString *op = [_taskInfo objectForKey: kDFOOperationKey];
        statusCount = 0;

        if (items==nil || op==nil) {
            /* Question: send notification or not */
            send_notification = NO;
        }
        else {
            if ([op isEqualToString:opSendRecycleBinOperation]) {
                NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:[items count]];
                for (id item in items) {
                    if ([item isKindOfClass:[NSURL class]]) {
                        [urls addObject:item];
                    }
                    else if ([item isKindOfClass:[TreeItem class]]) {
                        [urls addObject:[item url]];
                    }
                }
                if (![self isCancelled]) {

                    // No need to send notification. It will be sent on the completion handler
                    send_notification=NO;

                    [[NSWorkspace sharedWorkspace]
                     recycleURLs:urls // Using the completion block to send the notification
                     completionHandler:^(NSDictionary *newurls, NSError *blk_error) {
                         BOOL blk_OK;
                         if (blk_error==nil) {
                             blk_OK = YES;
#ifdef UPDATE_TREE
                             for (id item in items) {
                                 if ([item isKindOfClass:[TreeItem class]]) {
                                     [item removeItem];
                                 }
                             }
#endif //UPDATE_TREE
                         }
                         else
                             blk_OK = NO;
                         NSDictionary *OKError = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  [NSNumber numberWithBool:blk_OK], kDFOOkKey,
                                                  blk_error, kDFOErrorKey,
                                                   nil];
                         [_taskInfo addEntriesFromDictionary:OKError];

                         [[NSNotificationCenter defaultCenter]
                          postNotificationName:notificationFinishedFileOperation
                          object:nil
                          userInfo:_taskInfo];
                     }];
                }
            }
            else if ([op isEqualToString:opEraseOperation]) {
                for (id item in items) {
                    if ([item isKindOfClass:[NSURL class]])
                        OK = eraseFile(item, error);
                    else if ([item isKindOfClass:[TreeItem class]]) {
                        OK = eraseFile([item url], error);
#ifdef UPDATE_TREE
                        if (OK) {
                            [item removeItem];
                        }
#endif //UPDATE_TREE
                        statusCount++;
                    }
                    if ([self isCancelled]) break;
                }
            }

            // Its a rename or a file new
            else if ([op isEqualToString:opRename] ||
                     [op isEqualToString:opNewFolder]) {

                // Check whether it is a rename or a New File/Folder. Both required an edit of a name.
                // To distinguish from the two, if the file/folder exists is a rename, else is a new
                for (id item in items) {
                    NSURL *checkURL = NULL;
                    if ([item isKindOfClass:[NSURL class]]) {
                        checkURL = item;
                    }
                    else if ([item isKindOfClass:[TreeItem class]]) {
                        checkURL = [item url];
                    }
                    else {
                        assert(NO); // Unknown type
                    }

                    // Creating a new URL, works for either the new File or a Rename
                    NSString *newName = [_taskInfo objectForKey:kDFORenameFileKey];
                    // create a new Folder.

                    if ([op isEqualToString:opNewFolder]) {
                        NSURL *parentURL;
                        id destObj = [_taskInfo objectForKey:kDFODestinationKey];
                        if (destObj!=nil) {
                            if ([destObj isKindOfClass:[TreeBranch class]])
                                parentURL = [(TreeBranch*)destObj url];
                            else if ([destObj isKindOfClass:[NSURL class]])
                                parentURL = destObj;
                            OK = createDirectoryAtURL(newName, parentURL, error);
                        }
                        // Adjust to the correct operation
                        [_taskInfo setObject:opNewFolder forKey:kDFOOperationKey];
                    }
                    // NOTE: No Files are created with this application, at most it
                    // could in the future launch applications with a path, so they
                    // will create it.

                    else { 
                        // Do a Rename
                        NSURL *newURL = urlWithRename(checkURL, newName);
                        OK = moveFileTo(checkURL, newURL, error);

//#ifdef UPDATE_TREE  // Always update the tree, as otherwise it will have weird effect on the window
                        // If OK it will Update the URL so that no funky updates are done in the window
                        if (OK && [item isKindOfClass:[TreeItem class]]) {
                            [(TreeItem*)item setUrl:newURL];
                        }
//#endif // UPDATE_TREE
                        // Adjust to the correct Operation
                        [_taskInfo setObject:opRename forKey:kDFOOperationKey];
                    }



                    statusCount++;
                    if ([self isCancelled]) break;
                }
            }

            // this is the move or copy
            else {
                id destObj = [_taskInfo objectForKey:kDFODestinationKey];

                if (destObj!=nil && [destObj isKindOfClass:[TreeBranch class]]) {
                    TreeBranch *dest = destObj;
                    // Sees if there is a rename associated with the copy
                    NSString *newName = [_taskInfo objectForKey:kDFORenameFileKey];

                    // Assuming all will go well, and revert to No if anything happens
                    OK = YES;
                    if ([op isEqualToString:opCopyOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]])
                                newURL = copyFileToDirectory(item, [dest url], newName, error);
                            else if ([item isKindOfClass:[TreeItem class]])
                                newURL = copyFileToDirectory([item url], [dest url], newName, error);
                            if (newURL) {
#ifdef UPDATE_TREE
                                [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
#endif //UPDATE_TREE
                            }
                            else
                                OK = NO;

                            statusCount++;
                            if ([self isCancelled] || OK==NO) break;
                        }
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]]) {
                                newURL = moveFileToDirectory(item, [dest url], newName, error);
                                if (newURL) {
#ifdef UPDATE_TREE
                                    [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
#endif //UPDATE_TREE
                                }
                                else
                                    OK = NO;
                                statusCount++;
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = moveFileToDirectory([item url], [dest url], newName, error);
                                if (newURL) {
#ifdef UPDATE_TREE
                                    [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
                                    // Remove itself from the former parent
                                    [(TreeItem*)item removeItem];
#endif //UPDATE_TREE
                                }
                                else
                                    OK = NO;
                                statusCount++;
                            }
                            if ([self isCancelled] || OK==NO) break;
                        }
                    }
                }
                else if (destObj!=nil && [destObj isKindOfClass:[NSURL class]]) {
                    NSURL *dest = destObj;
                    if ([op isEqualToString:opCopyOperation]) {
                        for (id item in items) {
                            if ([item isKindOfClass:[NSURL class]])
                                OK=copyFileTo(item, dest, error);
                            else if ([item isKindOfClass:[TreeItem class]])
                                OK=copyFileTo([item url], dest, error);
                            statusCount++;
                            if ([self isCancelled] || error!=nil) break;
                        }
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        for (id item in items) {
                            if ([item isKindOfClass:[NSURL class]])
                                OK=moveFileTo(item, dest, error);

                            else if ([item isKindOfClass:[TreeItem class]])
                                OK=moveFileTo([item url], dest, error);
                            statusCount++;
                            if ([self isCancelled] || OK == NO) break;
                        }
                    }
                }
            }

            // Sending notification to AppDelegate
            if (send_notification) {
                NSDictionary *OKError = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithBool:OK], kDFOOkKey,
                                         error, kDFOErrorKey, nil];
                [_taskInfo addEntriesFromDictionary:OKError];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedFileOperation object:nil userInfo:_taskInfo];
            }
        }
    }
}


@end

BOOL putInQueue(NSDictionary *taskInfo) {
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskInfo];
    BOOL answer = [operation isReady];
    if (answer==YES)
        [operationsQueue addOperation:operation];
    return answer;
}


BOOL copyItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              folder, kDFODestinationKey,
                              nil];
    return putInQueue(taskinfo);
}

BOOL moveItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              folder, kDFODestinationKey,
                              nil];
    return putInQueue(taskinfo);
}

BOOL copyURLToURL(NSURL *source, NSURL *dest) {
    NSArray *items = [NSArray arrayWithObject:source];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              dest, kDFODestinationKey,
                              nil];
    return putInQueue(taskinfo);
}

BOOL moveURLToURL(NSURL *source, NSURL *dest) {
    NSArray *items = [NSArray arrayWithObject:source];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              dest, kDFODestinationKey,
                              nil];
    return putInQueue(taskinfo);
}

BOOL sendItemsToRecycleBin(NSArray *items) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opSendRecycleBinOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              nil];
    return putInQueue(taskinfo);
}

BOOL eraseItems(NSArray *items) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opEraseOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              nil];
    return putInQueue(taskinfo);
}



BOOL copyItemToBranch(TreeItem *item, TreeBranch *folder, NSString *newName) {
    NSArray *items = [NSArray arrayWithObject:item];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              folder, kDFODestinationKey,
                              newName, kDFORenameFileKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;

    return copyItemsToBranch(items, folder);
}

BOOL moveItemToBranch(TreeItem *item, TreeBranch *folder, NSString *newName) {
    NSArray *items = [NSArray arrayWithObject:item];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDFOOperationKey,
                              items, kDFOFilesKey,
                              folder, kDFODestinationKey,
                              newName, kDFORenameFileKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL sendItemToRecycleBin(TreeItem *item) {
    NSArray *items = [NSArray arrayWithObject:item];
    return sendItemsToRecycleBin(items);
}

BOOL eraseItem(TreeItem *item) {
    NSArray *items = [NSArray arrayWithObject:item];
    return eraseItems(items);
}

BOOL copyURLToBranch(NSURL* item, TreeBranch *folder) {
    NSArray *items = [NSArray arrayWithObject:item];
    return copyItemsToBranch(items, folder);
}

BOOL moveURLToBranch(NSURL* item, TreeBranch *folder) {
    NSArray *items = [NSArray arrayWithObject:item];
    return moveItemsToBranch(items, folder);
}

