//
//  MyURL.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileUtils.h"
#import "Definitions.h"

static NSOperationQueue *localOperationsQueue() {
    static NSOperationQueue *queue= nil;
    if (queue==nil)
        queue= [[NSOperationQueue alloc] init];
    return queue;
}

BOOL isFolder(NSURL* url) {
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
    NSError *error;
    BOOL answer = [[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error];
    return answer;
}

BOOL eraseFile(NSURL*url) {
    // Missing implementation
    NSLog(@"Erase File Method not implemented");
    return NO;
}

BOOL copyFileTo(NSURL*srcURL, NSURL *destURL) {
    NSError *error;
    BOOL answer = [appFileManager copyItemAtURL:srcURL toURL:destURL error:&error];
    return answer;
}

BOOL moveFileTo(NSURL*srcURL, NSURL *destURL) {
    NSError *error;
    BOOL answer = [appFileManager moveItemAtURL:srcURL toURL:destURL error:&error];
    return answer;
}

BOOL openFile(NSURL*url) {
    [[NSWorkspace sharedWorkspace] openFile:[url path]];
    return YES;
}

BOOL copyFilesThreaded(NSArray *files, NSString *toDirectory) {
    for (NSString *file in files) {
        [localOperationsQueue() addOperationWithBlock:^(void) {
            NSError *error=nil;
            NSString *newFilePath = [toDirectory stringByAppendingPathComponent:[file lastPathComponent]];
            //NSLog(@"Copying '%@' to '%@' ", file, newFilePath);
            [appFileManager copyItemAtPath:file toPath:newFilePath error:&error];
            if (error!=nil)
                NSLog(@"Error %@", error);
        }];
    }
    return YES;
}

BOOL moveFilesThreaded(NSArray *files, NSString *toDirectory) {
    for (NSString *file in files) {
        [localOperationsQueue() addOperationWithBlock:^(void) {
            NSError *error=nil;
            NSString *newFilePath = [toDirectory stringByAppendingPathComponent:[file lastPathComponent]];
            //NSLog(@"Moving '%@' to '%@' ", file, newFilePath);
            [appFileManager moveItemAtPath:file toPath:newFilePath error:&error];
            if (error!=nil)
                NSLog(@"Error %@", error);
        }];
    }
    return YES;
}

NSDictionary *getDiskInformation(NSURL *diskPath) {
    static NSMutableDictionary *diskInfos = nil; /* Used to store all the queries */
    DASessionRef session = nil;

    if (diskInfos==nil)
        diskInfos = [[NSMutableDictionary alloc] init];

    if (![diskPath isKindOfClass:[NSURL class]]) {
        NSLog(@"Houston we have a problem !!!");
        return nil;
    }

    //if (session==NULL)
    session = DASessionCreate(kCFAllocatorDefault);
    NSDictionary *di = [diskInfos objectForKey:diskPath];

    if(di==nil) {
        if (session!=NULL) {
                DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (__bridge CFURLRef)(diskPath));
                if (disk) {
                    CFDictionaryRef descDict = DADiskCopyDescription(disk);
                    if (descDict) {
                        di = [NSDictionary dictionaryWithDictionary:CFBridgingRelease(descDict)];
                        [diskInfos addEntriesFromDictionary:[NSDictionary dictionaryWithObject:di forKey:diskPath]];
                    }
                }
            
        }
    }
    return di;
}

NSString *mediaNameFromURL(NSURL *rootURL) {
    NSDictionary *diskInfo = getDiskInformation(rootURL);
    return diskInfo[@"DAVolumeName"];
}
