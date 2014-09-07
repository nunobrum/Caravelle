//
//  MyURL.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileUtils.h"
#import "Definitions.h"

//static NSOperationQueue *localOperationsQueue() {
//    static NSOperationQueue *queue= nil;
//    if (queue==nil)
//        queue= [[NSOperationQueue alloc] init];
//    return queue;
//}

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

BOOL eraseFile(NSURL*url) {
    NSError *error;
    BOOL answer = [[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error];
    if (error) {
        NSLog(@"=================ERASE ERROR ====================");
        NSLog(@"%@", error);
        NSLog(@"=================================================");
    }
    return answer;
}

void sendToRecycleBin(NSArray *urls) {
    [[NSWorkspace sharedWorkspace] recycleURLs:urls completionHandler:nil];
}

NSURL* copyFileTo(NSURL*srcURL, NSURL *destURL) {
    NSError *error;
    NSURL *destFileURL = [destURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
    // !!! TODO Check if File Exists and propose nameing
    [appFileManager copyItemAtURL:srcURL toURL:destFileURL error:&error];
    if (error) { // In the event of errors the NSFileManagerDelegate is called
        NSLog(@"================ COPY ERROR =====================");
        NSLog(@"%@", error);
        NSLog(@"=================================================");
        return NULL;

    }
    return destFileURL;
}

NSURL *moveFileTo(NSURL*srcURL, NSURL *destURL) {
    NSError *error;
    NSURL *destFileURL = [destURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
    [appFileManager moveItemAtURL:srcURL toURL:destFileURL error:&error];
    if (error) {  // In the event of errors the NSFileManagerDelegate is called 
        NSLog(@"================ MOVE ERROR =====================");
        NSLog(@"%@", error);
        NSLog(@"=================================================");
        return NULL;
    }
    return destFileURL;
}

BOOL openFile(NSURL*url) {
    [[NSWorkspace sharedWorkspace] openFile:[url path]];
    return YES;
}
//
//BOOL copyFilesThreaded(NSArray *files, id toDirectory) {
//    NSString *toDir;
//    if ([toDirectory isKindOfClass:[NSURL class]]) {
//        toDir = [(NSURL*)toDirectory path];
//    }
//    else if ([toDirectory isKindOfClass:[NSString class]]) {
//        toDir = toDirectory;
//    }
//    else {
//        return NO;
//    }
//    for (id file in files) {
//        NSString *src;
//        if ([file isKindOfClass:[NSURL class]])
//            src = [(NSURL*)file path];
//        else
//            src = file;
//        [localOperationsQueue() addOperationWithBlock:^(void) {
//            NSError *error=nil;
//            NSString *newFilePath = [toDir stringByAppendingPathComponent:[file lastPathComponent]];
//            NSLog(@"Copying '%@' to '%@' ", file, newFilePath);
//            [appFileManager copyItemAtPath:src toPath:newFilePath error:&error];
//            if (error!=nil)
//                NSLog(@"Error %@", error);
//        }];
//    }
//    return YES;
//}
//
//BOOL moveFilesThreaded(NSArray *files, id toDirectory) {
//    NSString *toDir;
//    if ([toDirectory isKindOfClass:[NSURL class]]) {
//        toDir = [(NSURL*)toDirectory path];
//    }
//    else if ([toDirectory isKindOfClass:[NSString class]]) {
//        toDir = toDirectory;
//    }
//    else {
//        return NO;
//    }
//    for (NSString *file in files) {
//        NSString *src;
//        if ([file isKindOfClass:[NSURL class]])
//            src = [(NSURL*)file path];
//        else
//            src = file;
//        [localOperationsQueue() addOperationWithBlock:^(void) {
//            NSError *error=nil;
//            NSString *newFilePath = [toDir stringByAppendingPathComponent:[file lastPathComponent]];
//            //NSLog(@"Moving '%@' to '%@' ", file, newFilePath);
//            [appFileManager moveItemAtPath:src toPath:newFilePath error:&error];
//            if (error!=nil)
//                NSLog(@"Error %@", error);
//        }];
//    }
//    return YES;
//}

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

