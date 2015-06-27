//
//  FileUtils.h
//  File Catalyst
//
//  Created by Nuno Brum on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>


// File Information
extern BOOL isFolder(NSURL* url);
extern BOOL isPackage(NSURL* url);
extern BOOL isWritable(NSURL* url);
extern BOOL isHidden(NSURL* url);
extern NSString* utiType(NSURL* url);
extern inline NSString* name(NSURL*url);
extern inline NSDate* dateModified(NSURL*url);
extern inline NSString* path(NSURL*url);
extern inline long long filesize(NSURL*url);
extern BOOL fileURLlExists(NSURL *url);

/* Enumerate to be used on the result of the path relation compare method */
typedef NS_ENUM(NSInteger, enumPathCompare) {
    pathIsSame = 0,
    pathsHaveNoRelation = 1,
    pathIsParent = 2,
    pathIsChild = 3
};
enumPathCompare path_relation(NSString *aPath, NSString* otherPath);
enumPathCompare url_relation(NSURL *aURL, NSURL* otherURL);

// Support Routines
//NSString *pathWithRename(NSString *original, NSString *new_name);
//NSURL *urlWithRename(NSURL* original, NSString *new_name);

// File Operations
extern void sendToRecycleBin(NSArray *urls);
extern BOOL eraseFile(NSURL*url, NSError *error);
extern NSURL *copyFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error);
extern NSURL *moveFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error);
extern NSURL *replaceFileWithFile(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error);
extern NSURL *renameFile(NSURL*url, NSString *newName, NSError *error);

//BOOL copyFileTo(NSURL*srcURL, NSURL *destURL, NSError *error);
//BOOL moveFileTo(NSURL*srcURL, NSURL *destURL, NSError *error);
//BOOL renameFile(NSURL*url, NSString *newName, NSError *error);
extern BOOL openFile(NSURL*url);
extern BOOL fileExistsOnPath(NSString*path);
extern NSString* duplicateFileNameProposal(NSString *path);

BOOL createDirectoryAtURL(NSString *name, NSURL *parent, NSError *error);

//BOOL copyFilesThreaded(NSArray *files, id toDirectory);
//BOOL moveFilesThreaded(NSArray *files, id toDirectory);

extern NSDictionary *getDiskInformation(NSURL *diskPath);
extern NSString *mediaNameFromURL(NSURL *rootURL);

/*
 * MD5 Calculation
 */
/* This function will calculate the file checksum based on the MD5 protocol */
NSData *calculateMD5(NSURL *url);
