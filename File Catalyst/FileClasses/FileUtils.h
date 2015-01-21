//
//  FileUtils.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>


// File Information
extern BOOL isFolder(NSURL* url);
extern BOOL isPackage(NSURL* url);
extern BOOL isWritable(NSURL* url);
extern NSString* utiType(NSURL* url);
extern inline NSString* name(NSURL*url);
extern inline NSDate* dateModified(NSURL*url);
extern inline NSString* path(NSURL*url);
extern inline long long filesize(NSURL*url);

// Support Routines
NSString *pathWithRename(NSString *original, NSString *new_name);
NSURL *urlWithRename(NSURL* original, NSString *new_name);

// File Operations
extern void sendToRecycleBin(NSArray *urls);
extern BOOL eraseFile(NSURL*url);
extern NSURL *copyFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName);
extern NSURL *moveFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName);
BOOL copyFileTo(NSURL*srcURL, NSURL *destURL);
BOOL moveFileTo(NSURL*srcURL, NSURL *destURL);
BOOL renameFile(NSURL*url, NSString *newName);
extern BOOL openFile(NSURL*url);

//BOOL copyFilesThreaded(NSArray *files, id toDirectory);
//BOOL moveFilesThreaded(NSArray *files, id toDirectory);

extern NSDictionary *getDiskInformation(NSURL *diskPath);
extern NSString *mediaNameFromURL(NSURL *rootURL);