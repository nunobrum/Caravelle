//
//  FileOperation.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileOperation.h"
#import "FileUtils.h"

//#define UPDATE_TREE


NSString *notificationFinishedFileOperation = @"FinishedFileOperation";

@implementation FileOperation

-(void) main {
    if (![self isCancelled])
	{
        NSArray *items = [_taskInfo objectForKey: kDroppedFilesKey];
        NSString *op = [_taskInfo objectForKey: kDropOperationKey];
        int opDone = 0;

        if (items==nil || op==nil) {
            /* Should it be decided to inform */
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
                    [[NSWorkspace sharedWorkspace]
                     recycleURLs:urls // Using the completion block to send the notification
                     completionHandler:^(NSDictionary *newurls, NSError *error) {
                         if (error==nil) {
#ifdef UPDATE_TREE
                             for (id item in items) {
                                 if ([item isKindOfClass:[TreeItem class]]) {
                                     [item removeItem];
                                 }
                             }
#endif //UPDATE_TREE
                         }
                         [[NSNotificationCenter defaultCenter]
                          postNotificationName:notificationFinishedFileOperation
                          object:nil
                          userInfo:_taskInfo];
                     }];
                }
            }
            else if ([op isEqualToString:opEraseOperation]) {
                for (id item in items) {
                    BOOL ok = NO;
                    if ([item isKindOfClass:[NSURL class]])
                        ok = eraseFile(item);
                    else if ([item isKindOfClass:[TreeItem class]]) {
                        ok = eraseFile([item url]);
#ifdef UPDATE_TREE
                        if (ok) {
                            [item removeItem];
                        }
#endif //UPDATE_TREE
                        opDone++;
                    }
                    if ([self isCancelled]) break;
                }
            }
            else {
                id destObj = [_taskInfo objectForKey:kDropDestinationKey];

                if (destObj!=nil && [destObj isKindOfClass:[TreeBranch class]]) {
                    TreeBranch *dest = destObj;
                    // Sees if there is a rename associated with the copy
                    NSString *newName = [_taskInfo objectForKey:kRenameFileKey];

                    if ([op isEqualToString:opCopyOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]])
                                newURL = copyFileToDirectory(item, [dest url], newName);
                            else if ([item isKindOfClass:[TreeItem class]])
                                newURL = copyFileToDirectory([item url], [dest url], newName);
#ifdef UPDATE_TREE
                            if (newURL) {
                                [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
                            }
#endif //UPDATE_TREE
                            opDone++;
                            if ([self isCancelled]) break;
                        }
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]]) {
                                newURL = moveFileToDirectory(item, [dest url], newName);
#ifdef UPDATE_TREE
                                if (newURL) {
                                    [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
                                }
#endif //UPDATE_TREE
                                opDone++;
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = moveFileToDirectory([item url], [dest url], newName);
#ifdef UPDATE_TREE
                                if (newURL) {
                                    [dest addChild:[TreeItem treeItemForURL:newURL parent:dest]];
                                    // Remove itself from the former parent
                                    [(TreeItem*)item removeItem];
                                }
#endif //UPDATE_TREE
                                opDone++;
                            }
                            if ([self isCancelled]) break;
                        }
                    }
                }
                else if (destObj!=nil && [destObj isKindOfClass:[NSURL class]]) {
                    NSURL *dest = destObj;
                    if ([op isEqualToString:opCopyOperation]) {
                        id item = [items firstObject];
                        BOOL OK;
                        if ([item isKindOfClass:[NSURL class]])
                            OK=copyFileTo(item, dest);
                        else if ([item isKindOfClass:[TreeItem class]])
                            OK=copyFileTo([item url], dest);
                        opDone++;
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        id item = [items firstObject];
                        BOOL OK;
                        if ([item isKindOfClass:[NSURL class]])
                            OK=moveFileTo(item, dest);
                        else if ([item isKindOfClass:[TreeItem class]])
                            OK=moveFileTo([item url], dest);
                        opDone++;
                    }
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedFileOperation object:nil userInfo:_taskInfo];
        }
    }
}


@end


BOOL copyItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              folder, kDropDestinationKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL moveItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              folder, kDropDestinationKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL copyURLToURL(NSURL *source, NSURL *dest) {
    NSArray *items = [NSArray arrayWithObject:source];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              dest, kDropDestinationKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL moveURLToURL(NSURL *source, NSURL *dest) {
    NSArray *items = [NSArray arrayWithObject:source];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              dest, kDropDestinationKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL sendItemsToRecycleBin(NSArray *items) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opSendRecycleBinOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

BOOL eraseItems(NSArray *items) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opEraseOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}



BOOL copyItemToBranch(TreeItem *item, TreeBranch *folder, NSString *newName) {
    NSArray *items = [NSArray arrayWithObject:item];
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              folder, kDropDestinationKey,
                              newName, kRenameFileKey,
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
                              opMoveOperation, kDropOperationKey,
                              items, kDroppedFilesKey,
                              folder, kDropDestinationKey,
                              newName, kRenameFileKey,
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

