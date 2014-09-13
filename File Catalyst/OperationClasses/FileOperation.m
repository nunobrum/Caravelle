//
//  FileOperation.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileOperation.h"
#import "FileUtils.h"

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
                             for (id item in items) {
                                 if ([item isKindOfClass:[TreeItem class]]) {
                                     [item removeItem];
                                 }
                             }
                         }
                         [[NSNotificationCenter defaultCenter]
                          postNotificationName:notificationFinishedFileOperation
                          object:nil
                          userInfo:_taskInfo];
                     }];
                }
            }
            else {
                if ([op isEqualToString:opEraseOperation]) {
                    for (id item in items) {
                        BOOL ok = NO;
                        if ([item isKindOfClass:[NSURL class]])
                            ok = eraseFile(item);
                        else if ([item isKindOfClass:[TreeItem class]]) {
                            ok = eraseFile([item url]);
                            if (ok) {
                                [item removeItem];
                            }
                            opDone++;
                        }
                        if ([self isCancelled]) break;
                    }
                }
                else {
                    TreeBranch *dest = [_taskInfo objectForKey:kDropDestinationKey];

                    if (dest!=nil && [dest isKindOfClass:[TreeBranch class]]) {
                        if ([op isEqualToString:opCopyOperation]) {
                            for (id item in items) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]])
                                    newURL = copyFileTo(item, [dest url]);
                                else if ([item isKindOfClass:[TreeItem class]])
                                    newURL = copyFileTo([item url], [dest url]);
                                if (newURL) {
                                    [dest addItem:[TreeItem treeItemForURL:newURL parent:dest]];
                                }
                                else {
                                    // Just refresh the Folder
                                    [dest refreshContentsOnQueue:operationsQueue];
                                }
                                opDone++;
                                if ([self isCancelled]) break;
                            }
                        }
                        else if ([op isEqualToString:opMoveOperation]) {
                            for (id item in items) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]])
                                    newURL = moveFileTo(item, [dest url]);
                                else if ([item isKindOfClass:[TreeItem class]])
                                    newURL = moveFileTo([item url], [dest url]);
                                if (newURL) {
                                    [dest addItem:[TreeItem treeItemForURL:newURL parent:dest]];
                                    opDone++;
                                }
                                if ([self isCancelled]) break;
                            }
                        }
                    }
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedFileOperation object:nil userInfo:_taskInfo];
            }
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



BOOL copyItemToBranch(TreeItem *item, TreeBranch *folder) {
    NSArray *items = [NSArray arrayWithObject:item];
    return copyItemsToBranch(items, folder);
}

BOOL moveItemToBranch(TreeItem *item, TreeBranch *folder) {
    NSArray *items = [NSArray arrayWithObject:item];
    return moveItemsToBranch(items, folder);
}

BOOL sendItemToRecycleBin(TreeItem *item) {
    NSArray *items = [NSArray arrayWithObject:item];
    return sendItemsToRecycleBin(items);
}

BOOL eraseItem(TreeItem *item) {
    NSArray *items = [NSArray arrayWithObject:item];
    return eraseItems(items);
}
