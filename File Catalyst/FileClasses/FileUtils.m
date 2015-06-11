//
//  MyURL.m
//  File Catalyst
//
//  Created by Nuno Brum on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileUtils.h"
#import "Definitions.h"



BOOL isFolder(NSURL* url) {
    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    return [isDirectory boolValue];
}

BOOL isPackage(NSURL* url) {
    NSNumber *isPackage;
    [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
    return [isPackage boolValue];
}

BOOL isWritable(NSURL* url) {
    NSNumber *isWritable;
    [url getResourceValue:&isWritable forKey:NSURLIsWritableKey error:NULL];
    return [isWritable boolValue];
}


NSString* utiType(NSURL* url) {
    NSString *typeIdentifier=nil;
    [url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL];
    return typeIdentifier;
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

BOOL fileURLlExists(NSURL *url) {
    return [[NSFileManager defaultManager]fileExistsAtPath:[url path]];
}

NSString *pathWithRename(NSString *original, NSString *new_name) {
    return [[original stringByDeletingLastPathComponent] stringByAppendingPathComponent:new_name];
}

NSURL *urlWithRename(NSURL* original, NSString *new_name) {
    BOOL folder = isFolder(original);
    return [[original URLByDeletingLastPathComponent] URLByAppendingPathComponent:new_name isDirectory:folder];
}

enumPathCompare path_relation(NSString *aPath, NSString* otherPath) {
    NSArray *pathComponents      = [aPath pathComponents];
    NSArray *otherPathComponents = [otherPath pathComponents];
    NSUInteger pcount = [pathComponents count];
    NSUInteger ocount = [otherPathComponents count];

    if (pcount == ocount) {
        // test if path is the same
        NSUInteger i;
        for (i=0 ; i < pcount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsSame;
    }
    else if (pcount < ocount) {
        // Test if path is a child
        NSUInteger i;
        for (i=0 ; i < pcount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsChild;
    }
    else {
        // test if s parent
        NSUInteger i;
        for (i=0 ; i < ocount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsParent;
    }
}

enumPathCompare url_relation(NSURL *aURL, NSURL* otherURL) {
    NSArray *pathComponents      = [aURL pathComponents];
    NSArray *otherPathComponents = [otherURL pathComponents];
    NSUInteger pcount = [pathComponents count];
    NSUInteger ocount = [otherPathComponents count];

    if (pcount == ocount) {
        // test if path is the same
        NSUInteger i;
        for (i=0 ; i < pcount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsSame;
    }
    else if (pcount < ocount) {
        // Test if path is a child
        NSUInteger i;
        for (i=0 ; i < pcount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsChild;
    }
    else {
        // test if s parent
        NSUInteger i;
        for (i=0 ; i < ocount ; i++) {
            if (NO==[[pathComponents objectAtIndex:i] isEqualToString: [otherPathComponents objectAtIndex:i]])
                return pathsHaveNoRelation;
        }
        return  pathIsParent;
    }
}

BOOL eraseFile(NSURL*url, NSError *error) {
    BOOL answer = [[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error];
    if (error) {
        NSLog(@"FileUtils.eraseFile - Error:\n%@\n\n", error);
    }
    return answer;
}

void sendToRecycleBin(NSArray *urls) {
    [[NSWorkspace sharedWorkspace] recycleURLs:urls completionHandler:nil];
}

NSURL* copyFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error) {
    NSURL *destFileURL;
    if (newName) {
        destFileURL = [destURL URLByAppendingPathComponent:newName];
    }
    else {
        destFileURL = [destURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
    }

    // if one folder is contained in another, abort operation
    if (isFolder(srcURL) && (url_relation(srcURL, destFileURL)==pathIsChild)) {
        //TODO:! create an error subclass, in order to make a error dialog
        return NULL;
    }
    [appFileManager copyItemAtURL:srcURL toURL:destFileURL error:&error];
    if (error) { // In the event of errors the NSFileManagerDelegate is called
        return NULL;
    }
    return destFileURL;
}

NSURL *moveFileToDirectory(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error) {
    NSURL *destFileURL;
    if (newName) {
        destFileURL = [destURL URLByAppendingPathComponent:newName];
    }
    else {
        destFileURL = [destURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
    }
    // if one file is contained in another, or the same, abort operation
    if (isFolder(srcURL) && (url_relation(srcURL, destFileURL)==pathIsChild)) {
        //TODO:! create an error subclass, in order to make a error dialog
        return NULL;
    }
    [appFileManager moveItemAtURL:srcURL toURL:destFileURL error:&error];
    if (error) {  // In the event of errors the NSFileManagerDelegate is called 
        return NULL;
    }
    return destFileURL;
}

NSURL * replaceFileWithFile(NSURL*srcURL, NSURL *destURL, NSString *newName, NSError *error) {
    NSURL *newURL;
    NSURL *destFileURL;
    if (newName) {
        destFileURL = [destURL URLByAppendingPathComponent:newName];
    }
    else {
        destFileURL = [destURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
    }
    [appFileManager replaceItemAtURL:destFileURL withItemAtURL:srcURL backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&newURL error:&error];
    //other options:  NSFileManagerItemReplacementWithoutDeletingBackupItem
    return newURL;
}

/*BOOL copyFileTo(NSURL*srcURL, NSURL *destURL, NSError *error) {
    // if one file is contained in another, or the same, abort operation
    if (url_relation(srcURL, destURL)!=pathsHaveNoRelation) {
        //TODO:! create an error subclass
        return NO;
    }
    [appFileManager copyItemAtURL:srcURL toURL:destURL error:&error];
    if (error) { // In the
        return NO;
    }
    return YES;
}

BOOL moveFileTo(NSURL*srcURL, NSURL *destURL, NSError *error) {
    // if one file is contained in another, or the same, abort operation
    if (url_relation(srcURL, destURL)!=pathsHaveNoRelation) {
        //TODO:! create an error subclass
        return NO;
    }
    BOOL OK = [appFileManager moveItemAtURL:srcURL toURL:destURL error:&error];
    if (OK==NO || error!=nil) { // In the case of error
        return NO;
    }
    return YES;
}*/

BOOL openFile(NSURL*url) {
    [[NSWorkspace sharedWorkspace] openFile:[url path]];
    return YES;
}

NSURL *renameFile(NSURL*url, NSString *newName, NSError *error) {
    BOOL isDirectory = isFolder(url);
    NSURL *newURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName isDirectory:isDirectory];
    BOOL OK = [appFileManager moveItemAtURL:url toURL:newURL error:&error];
    if (OK==NO || error!=nil) { // In the case of error
        return nil;
    }
    return newURL;
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


BOOL createDirectoryAtURL(NSString *name, NSURL *parent, NSError *error) {
    // TODO:! Check what are the attributes that must be set. see umask(2) documentation
    NSURL *newDirectory = [parent URLByAppendingPathComponent:name isDirectory:YES];
    BOOL OK = [appFileManager createDirectoryAtURL:newDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    return OK;
}

NSDictionary *getDiskInformation(NSURL *diskPath) {
    static NSMutableDictionary *diskInfos = nil; /* Used to store all the queries */
    DASessionRef session = nil;

    if (diskInfos==nil)
        diskInfos = [[NSMutableDictionary alloc] init];

    if (![diskPath isKindOfClass:[NSURL class]]) {
        NSLog(@"FileUtils.getDiskInformation - The return class for the getDiskInformation info is not an URL");
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

