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
        TreeBranch *dest = [_taskInfo objectForKey:kDropDestinationKey];
        int opDone = 0;

        if (items==nil || op==nil) {
            /* Should it be decided to inform */
        }
        else {
            if ([op isEqualToString:opSendRecycleBinOperation]) {
                for (id item in items) {
                    BOOL ok = NO;
                    if ([item isKindOfClass:[NSURL class]]) {
                        // !!! TODO
                    }
                    else if ([item isKindOfClass:[TreeItem class]]) {
                        ok = sendToRecycleBin([item url]);
                    }
                    if (ok) {
                        [item removeItem];
                        opDone++;
                    }
                    if ([self isCancelled]) break;
                }

            }
            else if (![dest isKindOfClass:[TreeBranch class]]) {
                if ([op isEqualToString:opCopyOperation]) {
                    for (id item in items) {
                        BOOL ok = NO;
                        if ([item isKindOfClass:[NSURL class]])
                            ok = copyFileTo(item, [dest url]);
                        else if ([item isKindOfClass:[TreeItem class]])
                            ok = copyFileTo([item url], [dest url]);
                        if (ok) {
                            [dest addItem:[TreeItem treeItemForURL:item parent:dest]];
                            opDone++;
                        }
                        if ([self isCancelled]) break;
                    }
                }
                else if ([op isEqualToString:opMoveOperation]) {
                    for (id item in items) {
                        BOOL ok = NO;
                        if ([item isKindOfClass:[NSURL class]])
                            ok = moveFileTo(item, [dest url]);
                        else if ([item isKindOfClass:[TreeItem class]])
                            ok = moveFileTo([item url], [dest url]);
                        if (ok) {
                            [dest addItem:[TreeItem treeItemForURL:item parent:dest]];
                            opDone++;
                        }
                        if ([self isCancelled]) break;
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
