//
//  MyURL.h
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
extern BOOL sendToRecycleBin(NSURL*url);
extern BOOL eraseFile(NSURL*url);
extern BOOL copyFileTo(NSURL*url, NSString *path);
extern BOOL moveFileTo(NSURL*url, NSString *path);
extern BOOL openFile(NSURL*url);

