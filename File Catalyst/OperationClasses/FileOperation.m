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
        NSArray *items = [_taskInfo objectForKey: kSelectedFilesKey];
        NSString *op = [_taskInfo objectForKey: kDropOperationKey];
        TreeBranch *dest = [_taskInfo objectForKey:kDropDestinationKey];

        if (items==nil || op==nil || ![dest isKindOfClass:[TreeBranch class]]) {
            /* Should it be decided to inform */
        }
        else {
            for (id item in items) {
                if ([item isKindOfClass:[NSURL class]]) {
                    if ([op isEqualToString:opCopyOperation]) {
                        BOOL ok = copyFileTo(item, [dest url]);
                        if (ok) {
                            [dest addItem:[TreeItem treeItemForURL:item parent:dest]];
                        }
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        BOOL ok = moveFileTo(item, [dest url]);
                        if (ok) {
                            /* Since source is unknown, there is no need to move the object */
                            [dest addItem:[TreeItem treeItemForURL:item parent:dest]];
                        }
                    }                }
                else if ([item isKindOfClass:[TreeItem class]])
                {
                    if ([op isEqualToString:opCopyOperation]) {
                        BOOL ok = copyFileTo([item url], [dest url]);
                        if (ok) {
                            [dest addItem:item];
                        }
                    }
                    else if ([op isEqualToString:opMoveOperation]) {
                        BOOL ok = moveFileTo([item url], [dest url]);
                        if (ok) {
                            [dest moveItem:item];
                        }
                    }
                }
                if ([self isCancelled]) {
                    break;
                }
            }
            if (![self isCancelled])
            {

                [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedFileOperation object:nil userInfo:_taskInfo];
            }
        }
    }
}

@end


BOOL copyItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opCopyOperation, kDropOperationKey,
                              items, kSelectedFilesKey,
                              folder, kDropDestinationKey,
                              nil];
    FileOperation *operation = [[FileOperation alloc ] initWithInfo:taskinfo];
    BOOL answer = [operation isReady];
    [operationsQueue addOperation:operation];
    return answer;
}

extern BOOL moveItemsToBranch(NSArray *items, TreeBranch *folder) {
    NSDictionary *taskinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              opMoveOperation, kDropOperationKey,
                              items, kSelectedFilesKey,
                              folder, kDropDestinationKey,
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
