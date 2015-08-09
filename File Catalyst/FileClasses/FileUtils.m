//
//  MyURL.m
//  File Catalyst
//
//  Created by Nuno Brum on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileUtils.h"
#import "Definitions.h"
#include "MD5.h"


inline BOOL isFolder(NSURL* url) {
    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    return [isDirectory boolValue];
}

inline BOOL isPackage(NSURL* url) {
    NSNumber *isPackage;
    [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
    return [isPackage boolValue];
}

inline BOOL isWritable(NSURL* url) {
    NSNumber *isWritable;
    [url getResourceValue:&isWritable forKey:NSURLIsWritableKey error:NULL];
    return [isWritable boolValue];
}

inline BOOL isHidden(NSURL* url) {
    NSNumber *isHidden;
    [url getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:NULL];
    return [isHidden boolValue];
}

inline NSString* utiType(NSURL* url) {
    NSString *typeIdentifier=nil;
    [url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL];
    return typeIdentifier;
}


inline NSString* name(NSURL*url) {
    return [url lastPathComponent];
}

NSDate* dateModified(NSURL*url) {
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

inline BOOL fileURLlExists(NSURL *url) {
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
        //TODO:!!!! create an error subclass, in order to make a error dialog
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
        //TODO:!!!! create an error subclass, in order to make a error dialog
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

BOOL fileExistsOnPath(NSString*path) {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

// The function that proposes a filename for file copy
NSString *duplicateFileNameProposal(NSString *path) {
    // Making the rename in consistency with Mac OSX
    
    // TODO:2.0 Localization of the "copy" word
    NSString *copyS = @"copy";
    NSString *newFileName = nil;
    NSString *newName;
    NSString *folder = [path stringByDeletingLastPathComponent];
    //Testing " copy" was already appended.
    NSString *name = [path lastPathComponent];
    NSString *nameWithoutExtension = [name stringByDeletingPathExtension];
    NSRange copyLocation = [nameWithoutExtension rangeOfString:copyS options: NSBackwardsSearch ]; // NSCaseInsensitiveSearch
    NSInteger copyNumber = 0;
    do {
        newName = nil;
        // if copy was found must first check if there is a number in front.
        if (copyNumber==0) { // If it is the first iteration will try to get from the file
            if (copyLocation.location == NSNotFound)
            {
                // will just append "copy"
                newName = [nameWithoutExtension stringByAppendingFormat:@" %@", copyS];
                nameWithoutExtension = newName;
                // Prepares for next cycle in case the file exists
                copyLocation = [nameWithoutExtension rangeOfString:copyS options: NSBackwardsSearch ]; // NSCaseInsensitiveSearch
                
                copyNumber = 1;
            }
            else {
                NSRange numberRange;
                numberRange.location = copyLocation.location + copyLocation.length;
                numberRange.length = [nameWithoutExtension length] - numberRange.location;
                if (numberRange.length == 0) { // There is no number
                    // just add 2, for the second copy
                    newName = [nameWithoutExtension stringByAppendingString:@" 2"];
                    copyNumber = 2;
                }
                else {
                    NSScanner *numberScanner  = [NSScanner scannerWithString:nameWithoutExtension];
                    [numberScanner setScanLocation:copyLocation.location + copyLocation.length];
                    if ([numberScanner scanInteger:&copyNumber]) { // If the conversion was successful
                        copyNumber++;
                    }
                    newName =  [NSString stringWithFormat:@"%@%@ %ld",
                                [nameWithoutExtension substringToIndex:copyLocation.location],
                                copyS,
                                (long)copyNumber];
                }
            }
        }
        else {
            // Only increment the copy Number
            copyNumber++;
            newName =  [NSString stringWithFormat:@"%@%@ %ld",
                        [nameWithoutExtension substringToIndex:copyLocation.location],
                        copyS,
                        (long)copyNumber];
        }
        // Now testing if the file already exists
        newName = [newName stringByAppendingPathExtension: [path pathExtension]];
        newFileName = [folder stringByAppendingPathComponent:newName];
    } while (fileExistsOnPath(newFileName) && (copyNumber < 5000)); // A high number where it will simply give up
    return newName;
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

NSString *pathFriendly(NSURL*url) {
    if ([[url pathComponents] count]==1) {
        return mediaNameFromURL(url);
    }
    else {
        return [url path];
    }
}

/* 
 * MD5 Calculation
 */
/* This function will calculate the file checksum based on the MD5 protocol */
#define BUFFER_SIZE_MD5 4096
void *calculateMD5(NSURL *url, void *buffer16bytes) {
    NSData *NSbuffer;
    md5_state_t state;
    md5_byte_t digest[16];
    md5_byte_t *data_pointer;
    NSUInteger bytes_read;
    NSError *error;
    //char hex_output[16*2 + 1];
    //int di;
    
    NSFileHandle *handler = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
    
    if (error==nil && handler!=nil) {
        
        md5_init(&state);
        
        do  {
            NSbuffer = [handler readDataOfLength:BUFFER_SIZE_MD5];
            bytes_read = [NSbuffer length];
            data_pointer = (md5_byte_t *)[NSbuffer bytes];
            md5_append(&state, data_pointer, (int)bytes_read); // Potential dangerous cast since it is converting from unsigned long to int, mind size declared in BUFFER_SIZE
            
        } while (bytes_read == BUFFER_SIZE_MD5);
        md5_finish(&state, digest);
    }
    [handler closeFile];
    //for (di = 0; di < 16; ++di)
    //    sprintf(hex_output + di * 2, "%02x", digest[di]);
    memcpy(buffer16bytes, digest, 16);
    //NSData *MD5 = [[NSData alloc] initWithBytes:digest length:16];
    return buffer16bytes;
}

