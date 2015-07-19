//
//  FileOperation.m
//  Caravelle
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileOperation.h"
#import "FileUtils.h"

#define UPDATE_TREE


NSString *notificationFinishedFileOperation = @"FinishedFileOperation";

@implementation FileOperation

-(void) main {
    BOOL  OK = NO;  // Assume it will go wrong until proven otherwise
    BOOL send_notification=YES;
    NSInteger okCount = 0;
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
                if (![self isCancelled]) {

                    // No need to send notification. It will be sent on the completion handler
                    OK = YES; // Will change to no if one delete is failed
                    NSError *loop_error;
                    for (id item in items) {
                        NSURL *url;
                        if ([item isKindOfClass:[NSURL class]]) {
                            url = item;
                        }
                        else if ([item isKindOfClass:[TreeItem class]]) {
                            url = [item url];
                        }

                        BOOL blk_OK = [appFileManager trashItemAtURL:url resultingItemURL:nil error:&loop_error];
                        if (blk_OK) {
                            okCount++;
#ifdef UPDATE_TREE
                            if ([item isKindOfClass:[TreeItem class]]) {
                                [item removeItem];
                            }
#endif //UPDATE_TREE
                        }
                        else {
                            error = loop_error;
                            OK = NO; // Memorizes error
                        }
                        statusCount++;
                        if ([self isCancelled]) break;
                    }
                    if (error==nil) { //
                        error = loop_error;
                    }
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
                    }
                    statusCount++;
                    if (OK) okCount++;
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
                        if (destObj!=nil && ([destObj isKindOfClass:[TreeItem class]])) {
                            if ([destObj itemType] == ItemTypeBranch)
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
                        NSURL *newURL = renameFile(checkURL, newName, error);
                        if (newURL) {
                            OK = YES;
                            //#ifdef UPDATE_TREE  // Always update the tree, as otherwise it will have weird effect on the window
                            // If OK it will Update the URL so that no funky updates are done in the window
                            if ([item isKindOfClass:[TreeItem class]]) {
                                [(TreeItem*)item setUrl:newURL];
                            }
                            //#endif // UPDATE_TREE
                        }
                        else {
                            OK = NO;
                        }
                        // Adjust to the correct Operation
                        [_taskInfo setObject:opRename forKey:kDFOOperationKey];
                    }
                    statusCount++;
                    if (OK) {
                        okCount++;
                    }
                    if ([self isCancelled]) break;
                }
            }

            // this is the move or copy
            else {
                id destObj = [_taskInfo objectForKey:kDFODestinationKey];
                // Sees if there is a rename associated with the copy
                NSString *newName = [_taskInfo objectForKey:kDFORenameFileKey];

                if (destObj!=nil && ([destObj isKindOfClass:[TreeItem class]])) {
                    if ([destObj itemType] == ItemTypeBranch) {
                        TreeBranch *dest = destObj;

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
                                    okCount++;
#ifdef UPDATE_TREE
                                    [dest addURL:newURL];
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
                                        okCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
#endif //UPDATE_TREE
                                    }
                                    else
                                        OK = NO;
                                    statusCount++;
                                }
                                else if ([item isKindOfClass:[TreeItem class]]) {
                                    newURL = moveFileToDirectory([item url], [dest url], newName, error);
                                    if (newURL) {
                                        okCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
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
                        else if ([op isEqualToString:opReplaceOperation]) {
                            for (id item in items) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]]) {
                                    newURL = replaceFileWithFile(item, [dest url], newName, error);
                                    if (newURL) {
                                        okCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
#endif //UPDATE_TREE
                                    }
                                    else
                                        OK = NO;
                                    statusCount++;
                                }
                                else if ([item isKindOfClass:[TreeItem class]]) {
                                    newURL = replaceFileWithFile([item url], [dest url], newName, error);
                                    if (newURL) {
                                        okCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
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
                    else {
                        NSAssert(NO, @"Unexpected Class received. Expected TreeBranch, received %@",[destObj class]);
                    }
                }
                else if (destObj!=nil && [destObj isKindOfClass:[NSURL class]]) {
                    NSURL *dest = destObj;
                    // Assuming all will go well, and revert to No if anything happens
                    OK = YES;
                    if ([op isEqualToString:opCopyOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]])
                                newURL = copyFileToDirectory(item, dest, newName, error);
                            else if ([item isKindOfClass:[TreeItem class]])
                                newURL = copyFileToDirectory([item url], dest, newName, error);

                            if (newURL)
                                okCount++;
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
                                newURL = moveFileToDirectory(item, dest, newName, error);
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = moveFileToDirectory([item url], dest, newName, error);
                            }

                            if (newURL)
                                okCount++;
                            else
                                OK = NO;
                            statusCount++;

                            if ([self isCancelled] || OK==NO) break;
                        }
                    }

                    else if ([op isEqualToString:opReplaceOperation]) {
                        for (id item in items) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]]) {
                                newURL = replaceFileWithFile(item, dest, newName, error);
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = replaceFileWithFile([item url], dest, newName, error);
                            }
                            if (newURL)
                                okCount++;
                            else
                                OK = NO;
                            statusCount++;
                            if ([self isCancelled] || OK==NO) break;
                        }
                    }
                }
            }

            // Sending notification to AppDelegate
            if (send_notification) {
                NSDictionary *OKError = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInteger:okCount], kDFOOkCountKey,
                                         [NSNumber numberWithInteger:statusCount], kDFOStatusCountKey,
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

