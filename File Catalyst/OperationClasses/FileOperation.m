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

-(NSString*) opCode {
    return op;
}

-(void) main {
    BOOL  OK = NO;  // Assume it will go wrong until proven otherwise
    BOOL send_notification=YES;
    NSMutableArray *filesOK = [NSMutableArray arrayWithCapacity:totalFileCount];
    
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
                        NSURL *url = getURL(item);
                    

                        BOOL blk_OK = [appFileManager trashItemAtURL:url resultingItemURL:nil error:&loop_error];
                        if (blk_OK) {
                            [filesOK addObject:item];
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
                    statusText  = [NSString stringWithFormat:@"%ld Files Trashed", filesOK.count];
                else
                    statusText = @"Trash Failed";

            }
            else if ([op isEqualTo:opEraseOperation]) {
                for (id item in files) {
                    NSURL *url = getURL(item);
                    OK = eraseFile(url, error);
                    
                    fileCount++;
                    if (OK) {
                        [filesOK addObject:item];
                    }
                    else {
                        break;
                    }
                    if ([self isCancelled]) break;
                }
                if (OK)
                    statusText  = [NSString stringWithFormat:@"%lu Files Trashed", filesOK.count];
                else
                    statusText = @"Trash Failed";

            }

            // Its a rename or a file new
            else if ([op isEqualTo:opRename] ||
                     [op isEqualTo:opNewFolder]) {

                // Check whether it is a rename or a New File/Folder. Both required an edit of a name.
                // To distinguish from the two, if the file/folder exists is a rename, else is a new
                for (id item in files) {
                    NSURL *checkURL = getURL(item);
                   
                    assert(checkURL!=nil); // Unknown type

                    // Creating a new URL, works for either the new File or a Rename
                    NSString *newName = [_taskInfo objectForKey:kDFORenameFileKey];
                    // create a new Folder.

                    if ([op isEqualTo:opNewFolder]) {
                        NSURL *parentURL;
                        id destObj = [_taskInfo objectForKey:kDFODestinationKey];
                        if (destObj!=nil) {
                            parentURL = getURL(destObj);
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
                        }
                        else {
                            OK = NO;
                        }
                        // Adjust to the correct Operation
                        [_taskInfo setObject:opRename forKey:kDFOOperationKey];
                    }
                    fileCount++;
                    if (OK) {
                        [filesOK addObject:item];
                    }
                    else break;
                    if ([self isCancelled]) break;
                }
                if ([op isEqualTo:opRename]) {
                    if (!OK) {
                        statusText = @"Rename Failed";
                    }
                    else {
                        statusText  = [NSString stringWithFormat:@"%lu Files renamed", filesOK.count];
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
                NSURL *destURL = getURL(destObj);

                if (destURL!=nil) {
                    if (isFolder(destURL)) {
                        // Assuming all will go well, and revert to No if anything happens
                        OK = YES;
                        if ([op isEqualTo:opCopyOperation]) {
                            for (id item in files) {
                                NSURL *itemURL = getURL(item);
                                NSURL *newURL = NULL;
                                newURL = copyFileToDirectory(itemURL, destURL, newName, error);
                                if (newURL) {
                                    [filesOK addObject:item];
#ifdef UPDATE_TREE
                                    if ([destObj isKindOfClass:[TreeItem class]]) {
                                        [dest addURL:newURL];
                                    }
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
                                NSURL *itemURL = getURL(item);
                                NSURL *newURL = NULL;
                                if (itemURL != nil) {
                                    newURL = moveFileToDirectory(itemURL, destURL, newName, error);
                                    if (newURL) {
                                        [filesOK addObject:item];
#ifdef UPDATE_TREE
                                        if ([destObj isKindOfClass:[TreeItem class]]) {
                                            [dest addURL:newURL];
                                        }
                                        if ([item isKindOfClass:[TreeItem class]]) {
                                            [dest addURL:newURL];
                                            // Remove itself from the former parent
                                            [(TreeItem*)item removeItem];
                                        }
#endif //UPDATE_TREE
                                    }
                                    else {
                                        OK = NO;
                                        break;
                                    }
                                }
                                else {
                                    OK = NO;
                                    break;
                                }
                                fileCount++;
                                if ([self isCancelled] || OK==NO) break;
                            }
                        }
                    
                        else if ([op isEqualTo:opReplaceOperation]) {
                            NSURL *destURL = getURL(destObj);
                            for (id item in files) {
                                NSURL *itemURL = getURL(item);
                                NSURL *newURL = NULL;
                                
                                if (itemURL != nil) {
                                    newURL = replaceFileWithFile(itemURL, destURL, newName, error);
                                    if (newURL) {
                                        [filesOK addObject:item];
#ifdef UPDATE_TREE
                                        if ([item isKindOfClass:[TreeItem class]]) {
                                            [dest addURL:newURL];
                                        }
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
                        strFiles = [NSString stringWithFormat:@"%lu files were", filesOK.count];
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
                [_taskInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                         filesOK, kDFOFilesKey,
                                         [NSNumber numberWithBool:OK], kDFOOkKey,
                                         statusText, kDFOStatusKey,
                                         error, kDFOErrorKey, nil]];
                [self send_notification: _taskInfo];
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

