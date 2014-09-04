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
extern inline NSString* name(NSURL*url);
extern inline NSDate* dateModified(NSURL*url);
extern inline NSString* path(NSURL*url);
extern inline long long filesize(NSURL*url);

// File Operations
extern void sendToRecycleBin(NSArray *urls);
extern BOOL eraseFile(NSURL*url);
extern NSURL *copyFileTo(NSURL*srcURL, NSURL *destURL);
extern NSURL *moveFileTo(NSURL*srcURL, NSURL *destURL);
extern BOOL openFile(NSURL*url);

//BOOL copyFilesThreaded(NSArray *files, id toDirectory);
//BOOL moveFilesThreaded(NSArray *files, id toDirectory);

extern NSDictionary *getDiskInformation(NSURL *diskPath);
extern NSString *mediaNameFromURL(NSURL *rootURL);