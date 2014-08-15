//
//  MyURL.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "MyURL.h"


inline BOOL isDirectory(NSURL* url) {
    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    return [isDirectory boolValue];
}

inline NSString* name(NSURL*url) {
    return [url lastPathComponent];
}

inline NSDate* dateModified(NSURL*url) {
    NSDate *date=nil;
    NSError *errorCode;
    if ([url isFileURL]) {
        [url getResourceValue:&date forKey:NSURLContentModificationDateKey error:&errorCode];
        if (errorCode || date==nil) {
            [url getResourceValue:&date forKey:NSURLContentAccessDateKey error:&errorCode];
        }
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:NULL];
        date = [dirAttributes fileModificationDate];
    }
    return date;
}

inline NSString* path(NSURL*url) {
    NSString *path;
    [url getResourceValue:&path     forKey:NSURLPathKey error:NULL];
    return path;
}


inline long long filesize(NSURL*url) {
    NSNumber *filesize;
    [url getResourceValue:&filesize     forKey:NSURLFileSizeKey error:NULL];
    return [filesize longLongValue];
}

BOOL sendToRecycleBin(NSURL*url) {
    return [[NSFileManager defaultManager] removeItemAtPath:[url path] error:nil];
}

BOOL eraseFile(NSURL*url) {
    // Missing implementation
    NSLog(@"Erase File Method not implemented");
    return NO;
}

BOOL copyFileTo(NSURL*url, NSString *path) {
    // Missing implementation
    NSLog(@"Copy File Method not implemented");
    return NO;
}

BOOL moveFileTo(NSURL*url, NSString *path) {
    // Missing implementation
    NSLog(@"Move File Method not implemented");
    return NO;
}

BOOL openFile(NSURL*url) {
    [[NSWorkspace sharedWorkspace] openFile:[url path]];
    return YES;
}
