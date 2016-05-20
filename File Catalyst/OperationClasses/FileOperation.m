//
//  FileOperation.m
//  Caravelle
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//
#include "Definitions.h"
#import "FileOperation.h"
#import "FileUtils.h"
#import "TreeBranch.h"

#define UPDATE_TREE



@implementation FileOperation

- (id)initWithInfo:(NSDictionary*)info {
    self = [super initWithInfo:info];
    if (self)
    {
        files = [_taskInfo objectForKey: kDFOFilesKey];
        totalFileCount = [files count];
        op = [_taskInfo objectForKey: kDFOOperationKey];
        fileCount = 0;
        
    }
    return self;
}

-(void) main {
    BOOL  OK = NO;  // Assume it will go wrong until proven otherwise
    BOOL send_notification=YES;
    fileOKCount = 0;
    NSError *error = nil;
    if (![self isCancelled])
	{
        // Initialized with a dummy String.
        NSString *statusText = @"Invalid Status";
        
        if (files==nil || op==nil) {
            /* Question: send notification or not */
            send_notification = NO;
        }
        else {
            if ([op isEqualTo:opSendRecycleBinOperation]) {
                if (![self isCancelled]) {

                    // No need to send notification. It will be sent on the completion handler
                    OK = YES; // Will change to no if one delete is failed
                    NSError *loop_error;
                    for (id item in files) {
                        NSURL *url;
                        if ([item isKindOfClass:[NSURL class]]) {
                            url = item;
                        }
                        else if ([item isKindOfClass:[TreeItem class]]) {
                            url = [item url];
                        }

                        BOOL blk_OK = [appFileManager trashItemAtURL:url resultingItemURL:nil error:&loop_error];
                        if (blk_OK) {
                            fileOKCount++;
#ifdef UPDATE_TREE
                            if ([item isKindOfClass:[TreeItem class]]) {
                                [item removeItem];
                            }
#endif //UPDATE_TREE
                        }
                        else {
                            error = loop_error;
                            OK = NO; // Memorizes error
                            break;
                        }
                        fileCount++;
                        if ([self isCancelled]) break;
                    }
                    if (error==nil) { //
                        error = loop_error;
                    }
                }
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%ld Files Trashed", (long)fileOKCount];
                else
                    statusText = @"Trash Failed";

            }
            else if ([op isEqualTo:opEraseOperation]) {
                for (id item in files) {
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
                    fileCount++;
                    if (OK) fileOKCount++;
                    else break;
                    if ([self isCancelled]) break;
                }
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%lu Files Trashed", fileOKCount];
                else
                    statusText = @"Trash Failed";

            }

            // Its a rename or a file new
            else if ([op isEqualTo:opRename] ||
                     [op isEqualTo:opNewFolder]) {

                // Check whether it is a rename or a New File/Folder. Both required an edit of a name.
                // To distinguish from the two, if the file/folder exists is a rename, else is a new
                for (id item in files) {
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

                    if ([op isEqualTo:opNewFolder]) {
                        NSURL *parentURL;
                        id destObj = [_taskInfo objectForKey:kDFODestinationKey];
                        if (destObj!=nil && ([destObj isKindOfClass:[TreeItem class]])) {
                            if ([destObj isFolder])
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
                    fileCount++;
                    if (OK) {
                        fileOKCount++;
                    }
                    else break;
                    if ([self isCancelled]) break;
                }
                if ([op isEqualTo:opRename]) {
                    if (!OK) {
                        statusText = @"Rename Failed";
                    }
                    else {
                        statusText  = [NSString stringWithFormat:@"%lu Files renamed", fileOKCount];
                    }
                }
                else if ([op isEqualTo:opNewFolder]) {
                    if (!OK) {
                        statusText = @"New Folder creation failed";
                    }
                    else
                        statusText = @"Folder Created";
                }
            }

            // this is the move or copy
            else {
                id destObj = [_taskInfo objectForKey:kDFODestinationKey];
                // Sees if there is a rename associated with the copy
                NSString *newName = [_taskInfo objectForKey:kDFORenameFileKey];

                if (destObj!=nil && ([destObj isKindOfClass:[TreeItem class]])) {
                    if ([destObj isFolder]) {
                        TreeBranch *dest = destObj;

                        // Assuming all will go well, and revert to No if anything happens
                        OK = YES;
                        if ([op isEqualTo:opCopyOperation]) {
                            for (id item in files) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]])
                                    newURL = copyFileToDirectory(item, [dest url], newName, error);
                                else if ([item isKindOfClass:[TreeItem class]])
                                    newURL = copyFileToDirectory([item url], [dest url], newName, error);
                                if (newURL) {
                                    fileOKCount++;
#ifdef UPDATE_TREE
                                    [dest addURL:newURL];
#endif //UPDATE_TREE
                                }
                                else {
                                    OK = NO;
                                    break;
                                }
                                fileCount++;
                                if ([self isCancelled] || OK==NO) break;
                            }
                        }
                        else if ([op isEqualTo:opMoveOperation]) {
                            for (id item in files) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]]) {
                                    newURL = moveFileToDirectory(item, [dest url], newName, error);
                                    if (newURL) {
                                        fileOKCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
#endif //UPDATE_TREE
                                    }
                                    else {
                                        OK = NO;
                                        break;
                                    }
                                    fileCount++;
                                }
                                else if ([item isKindOfClass:[TreeItem class]]) {
                                    newURL = moveFileToDirectory([item url], [dest url], newName, error);
                                    if (newURL) {
                                        fileOKCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
                                        // Remove itself from the former parent
                                        [(TreeItem*)item removeItem];
#endif //UPDATE_TREE
                                    }
                                    else {
                                        OK = NO;
                                        break;
                                    }
                                    fileCount++;
                                }
                                if ([self isCancelled] || OK==NO) break;
                            }
                        }
                        else if ([op isEqualTo:opReplaceOperation]) {
                            for (id item in files) {
                                NSURL *newURL = NULL;
                                if ([item isKindOfClass:[NSURL class]]) {
                                    newURL = replaceFileWithFile(item, [dest url], newName, error);
                                    if (newURL) {
                                        fileOKCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
#endif //UPDATE_TREE
                                    }
                                    else {
                                        OK = NO;
                                        break;
                                    }
                                    fileCount++;
                                }
                                else if ([item isKindOfClass:[TreeItem class]]) {
                                    newURL = replaceFileWithFile([item url], [dest url], newName, error);
                                    if (newURL) {
                                        fileOKCount++;
#ifdef UPDATE_TREE
                                        [dest addURL:newURL];
                                        // Remove itself from the former parent
                                        [(TreeItem*)item removeItem];
#endif //UPDATE_TREE
                                    }
                                    else {
                                        OK = NO;
                                        break;
                                    }
                                    fileCount++;
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
                    if ([op isEqualTo:opCopyOperation]) {
                        for (id item in files) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]])
                                newURL = copyFileToDirectory(item, dest, newName, error);
                            else if ([item isKindOfClass:[TreeItem class]])
                                newURL = copyFileToDirectory([item url], dest, newName, error);

                            if (newURL)
                                fileOKCount++;
                            else {
                                OK = NO;
                                break;
                            }
                            fileCount++;
                            if ([self isCancelled]) break;
                        }
                    }
                    else if ([op isEqualTo:opMoveOperation]) {
                        for (id item in files) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]]) {
                                newURL = moveFileToDirectory(item, dest, newName, error);
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = moveFileToDirectory([item url], dest, newName, error);
                            }

                            if (newURL)
                                fileOKCount++;
                            else {
                                OK = NO;
                                break;
                            }
                            fileCount++;

                            if ([self isCancelled]) break;
                        }
                    }

                    else if ([op isEqualTo:opReplaceOperation]) {
                        for (id item in files) {
                            NSURL *newURL = NULL;
                            if ([item isKindOfClass:[NSURL class]]) {
                                newURL = replaceFileWithFile(item, dest, newName, error);
                            }
                            else if ([item isKindOfClass:[TreeItem class]]) {
                                newURL = replaceFileWithFile([item url], dest, newName, error);
                            }
                            if (newURL)
                                fileOKCount++;
                            else {
                                OK = NO;
                                break;
                            }
                            fileCount++;
                            if ([self isCancelled]) break;
                        }
                    }
                }
                NSString *strFiles;
                
                if (OK) {
                    if (fileCount==1) {
                        id item = [files firstObject];
                        NSString *name;
                        if ([item isKindOfClass:[TreeItem class]]) {
                            name = [(TreeItem*)item name];
                        }
                        else if ([item isKindOfClass:[NSURL class]]) {
                            name = [(NSURL*)item lastPathComponent];
                        }
                        else
                            name = @"...";
                        strFiles = [NSString stringWithFormat:@"%@ was", name];
                    }
                    else {
                        strFiles = [NSString stringWithFormat:@"%lu files were", fileOKCount];
                    }
                }
                if ([op isEqualTo:opCopyOperation]) {
                    if (OK) {
                        statusText  = [NSString stringWithFormat:@"%@ copied", strFiles];
                    }
                    else
                        statusText = @"Copy Failed";
                }
                else if ([op isEqualTo:opMoveOperation]) {
                    if (OK)
                        statusText  = [NSString stringWithFormat:@"%@ moved", strFiles];
                    else
                        statusText = @"Move Failed";
                }
                else if ([op isEqualTo:opReplaceOperation]) {
                    if (OK)
                        statusText  = [NSString stringWithFormat:@"%@ replaced", strFiles];
                    else
                        statusText = @"Replace Failed";
                }
            }

            // Sending notification to AppDelegate
            if (send_notification) {
                NSDictionary *OKError = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithBool:OK], kDFOOkKey,
                                         statusText, kDFOStatusKey,
                                         error, kDFOErrorKey, nil];
                [self send_notification: OKError];
            }
        }
    }
}

-(NSString*) statusText {
    
    NSString *strFiles;
    if (totalFileCount == 0) {
        strFiles = @"";
    }
    else if (totalFileCount == 1) {
        id item = [files firstObject];
        if ([item isKindOfClass:[TreeItem class]]) {
            strFiles = [(TreeItem*)item name];
        }
        else if ([item isKindOfClass:[NSURL class]]) {
            strFiles = [(NSURL*)item lastPathComponent];
        }
        else {
            strFiles = @"";
        }
    }
    else {
        strFiles = [NSString stringWithFormat:@" %ld of %ld files", fileCount, totalFileCount];
    }
    NSString *status = @"Internal Error. Unknown Operation";
    if ([op isEqualTo:opCopyOperation]) {
        status = [NSString stringWithFormat:@"Copying... %@", strFiles];
    }
    else if ([op isEqualTo:opMoveOperation]) {
        status = [NSString stringWithFormat:@"Moving... %@", strFiles];
    }
    else if ([op isEqualTo:opReplaceOperation]) {
        status = [NSString stringWithFormat:@"Replacing... %@", strFiles];
    }
    else if ([op isEqualTo:opSendRecycleBinOperation]) {
        status = [NSString stringWithFormat:@"Trashing... %@", strFiles];
    }
    else if ([op isEqualTo:opSendRecycleBinOperation]) {
        status = [NSString stringWithFormat:@"Trashing... %@", strFiles];
    }
    else if ([op isEqualTo:opEraseOperation]) {
        status = [NSString stringWithFormat:@"Erasing... %@", strFiles];
    }
    else if ([op isEqualTo:opRename]) {
        status = [NSString stringWithFormat:@"Renaming... %@", strFiles];
    }
    else if ([op isEqualTo:opNewFolder]) {
        status = [NSString stringWithFormat:@"Creating Folder "];
    }
    return status;
}

@end

