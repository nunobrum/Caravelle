//
//  DirectoryIterator.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileCollection.h"
#import "FileInformation.h"

#import "Definitions.h"


@implementation FileCollection: NSObject

-(FileCollection *) init {
    self = [super init];
    self->fileArray = [[NSMutableArray new] init];
    self->rootDirectory = nil;
    return self;
}


-(void) addFilesInDirectory:(NSString *)rootpath callback:(void (^)(NSInteger fileno))callbackhandler
{

    NSInteger fileno=0;
    
    // Copies the rootpath to rootDirectory;
    self->rootDirectory = rootpath;
    
    // Create a local file manager instance
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    
    
    // Enumerate the directory (specified elsewhere in your code)
    // Request the two properties the method uses, name and isDirectory
    // Ignore hidden files
    // The errorHandler: parameter is set to nil. Typically you'd want to present a panel
    
    NSURL *directoryToScan = [NSURL fileURLWithPath:rootpath];
    
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:directoryToScan
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:
                                                                              NSURLNameKey,
                                                                              NSURLIsDirectoryKey,
                                                                              NSURLContentModificationDateKey,
                                                                              NSURLFileSizeKey,
                                                                              nil]
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                errorHandler:nil];
    // NSDirectoryEnumerationSkipsSubdirectoryDescendants
    
    // An array to store the all the enumerated file names in
    
    
    if (fileArray==nil)
        fileArray = [NSMutableArray new];
    else
        [fileArray removeAllObjects ];
    
    // Enumerate the dirEnumerator results, each value is stored in allURLs
    for (NSURL *theURL in dirEnumerator) {
        
        // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
        NSString *fileName;
        [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        //NSLog(@"File %@",fileName);
        
        // Retrieve whether a directory. From NSURLIsDirectoryKey, also
        // cached during the enumeration.
        NSNumber *isDirectory;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        // Ignore files under the _extras directory
        /*if (([fileName caseInsensitiveCompare:@"_extras"]==NSOrderedSame) &&
            ([isDirectory boolValue]==YES))
        {
            [dirEnumerator skipDescendants];
            NSLog(@"Skipping %@",fileName);
        }
        else*/
        if ([isDirectory boolValue]==NO)
        {
            [self addFileByURL:theURL];
            fileno+=1;
        }
        if (0 ==(fileno % UPDATE_CADENCE_PER_FILE))
            callbackhandler(fileno);
    }
    
    // Release the localFileManager.
    //[localFileManager release]; Commenting this line because automatic reference count is activated
    
    
}

-(void) AddFileInformation: (FileInformation*) aFileInfo {
    if (fileArray==nil)
        fileArray = [[NSMutableArray new] init];
    [fileArray addObject:aFileInfo];
    
}
-(void) addFileByURL: (NSURL *) anURL {
    FileInformation *fi = [FileInformation createWithURL:anURL];
    if (fileArray==nil)
        fileArray = [[NSMutableArray new] init];
    [fileArray addObject:fi];    
}

-(void) addFiles: (NSMutableArray *)otherArray {
    if (otherArray!=nil) { // Will only do anything if the other array is valid
        if (fileArray==nil) {
            fileArray = [[NSMutableArray new] init];
            [fileArray addObjectsFromArray:otherArray];
        }
        else {
            for (FileInformation *fi in otherArray) {
                if (NSNotFound==[fileArray indexOfObject:fi]) {
                    // Adds only if it doesn't already exist
                    [fileArray addObject:fi];
                }
            }
            rootDirectory = nil; // It will be calculated next time the rootPath is called
        }
    }
}

-(NSInteger) FileCount {
    return [fileArray count];
}

/* Computes the common path between all files in the collection */
-(NSString*) commonPath {
    if (rootDirectory==nil) {
        NSArray *common_path = nil;
        NSArray *file_path;
        NSInteger ci=0;
        for (FileInformation *fi in fileArray) {
            if (common_path==nil)
            {
                common_path = [fi getPathComponents];
                ci = [common_path count]-1; /* This will exclude the file name */
            }
            else
            {
                NSInteger i;
                file_path = [fi getPathComponents];
                if ([file_path count]<ci)
                    ci = [file_path count];
                for (i=0; i< ci; i++) {
                    if (NO==[[common_path objectAtIndex:i] isEqualToString:[file_path objectAtIndex:i]]) {
                        ci = i;
                        break;
                    }
                }
//                NSRange r;
//                r.location = 0;
//                r.length = 0+ci;
//                rootDirectory = [NSString pathWithComponents:[common_path objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r]]];
//                NSLog(@"common path %li %@",ci, rootDirectory);

            }
        }
        if (ci==0) {
            rootDirectory = @"/";
        }
        else {
            NSRange r;
            r.location = 0;
            r.length = 0+ci;
            rootDirectory = [NSString pathWithComponents:[common_path objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r]]];
        }
    }
    return rootDirectory;
}

-(NSMutableArray*) fileArray {
    return fileArray;
}

-(FileCollection *) findDuplicates: (DuplicateOptions) options operation:(NSOperation*)operation {
    NSInteger i, j;
    NSInteger max_files = [fileArray count];
    BOOL duplicate;
    FileCollection *duplicateList = [[FileCollection new] init];
    
    if (options & DupCompareSize) {
        [self sortByFileSize];
    }
    
    FileInformation *FileA, *FileB;
    for (i=0;i<max_files;i++) {
        if ([operation isCancelled])
            return nil;
        FileA = [fileArray objectAtIndex:i];
        for (j=i+1; j<max_files; j++) {
            FileB = [fileArray objectAtIndex:j];
            duplicate = TRUE;
            if (options & DupCompareName && [FileA equalName: FileB]==FALSE) {
                duplicate= FALSE;
            }
            else if (options & DupCompareSize) {
                NSComparisonResult result = [FileA compareSize:FileB];
                if (result ==NSOrderedAscending) {
                    j = max_files; // This will make the inner cycle to end
                    duplicate = FALSE;
                }
                else if (result == NSOrderedDescending) {
                    duplicate = FALSE; // This in principle will never happen if the files are sorted by size
                }
            }
            if (duplicate==TRUE && (options & DupCompareDateModified) && [FileA equalDate:FileB]==FALSE) {
                duplicate = FALSE;
            }
            if (duplicate==TRUE && (options & (DupCompareContentsMD5|DupCompareContentsFull))) {
                // First tries to make the difference using MD5 checksums
                if ([FileA compareMD5checksum:FileB]==FALSE) {
                    duplicate = FALSE;
                }
                // If the MD5 Matches, then it must compare the full contents
                else if ((options&DupCompareContentsMD5) || [FileA compareContents:FileB]==FALSE) {
                    duplicate = FALSE;
                }
            }
            if (duplicate) {
                //NSLog(@"=======================File Duplicated =====================\n%@\n%@", [FileA getPath], [FileB getPath]);
                [FileA addDuplicate:FileB];
                // The cycle will end once one duplicate is found
                // This must be like this in order for the
                // Duplicate ring to work, and it makes the algorithm much faster
                j = max_files;
            }
        }
        if ([FileA hasDuplicates]==YES) {
            [duplicateList AddFileInformation:FileA];
        }
    }
    if ([duplicateList FileCount]==0)
        return nil;
    else
        duplicateList->rootDirectory = nil; // It will be calculated next time the rootPath is called
        return duplicateList;
}

-(FileCollection*) filesInPath:(NSString*) path {
    FileCollection *newCollection = [[FileCollection new] init];
    for (FileInformation *finfo in fileArray) {
        NSString *fpath = finfo.getPath;
        NSRange result;
        result = [fpath rangeOfString:path];
        if (result.location == 0)
            [newCollection AddFileInformation:finfo];

    }
    return newCollection;
}

-(FileCollection*) duplicatesInPath:(NSString*) path {
    FileCollection *newCollection = [[FileCollection new] init];
    for (FileInformation *finfo in fileArray) {
        NSString *fpath = finfo.getPath;
        NSRange result;
        result = [fpath rangeOfString:path];
        if (result.location == 0) {
            FileInformation *cursor=finfo->duplicate_chain;
            while (cursor!=finfo) {
                [newCollection AddFileInformation:cursor];
                cursor = cursor->duplicate_chain;
            }
        }
    }
    return newCollection;
}


-(BOOL) isRootContainedInPath:(NSString *)otherRoot {
    NSRange result;
    result = [otherRoot rangeOfString:rootDirectory];
    if (result.location == NSNotFound)
        return NO;
    else
        return YES;
}

-(BOOL) rootContainsPath:(NSString *)otherRoot {
    NSRange result;
    result = [rootDirectory rangeOfString:otherRoot];
    if (result.location == NSNotFound)
        return NO;
    else
        return YES;
}

-(BOOL) isRootContainedIn:(FileCollection *)otherCollection {
    NSRange result;
    result = [[otherCollection commonPath] rangeOfString:rootDirectory];
    if (result.location == NSNotFound)
        return NO;
    else
        return YES;
}

-(BOOL) rootContains:(FileCollection *)otherCollection {
    NSRange result;
    result = [rootDirectory rangeOfString:[otherCollection commonPath]];
    if (result.location == NSNotFound)
        return NO;
    else
        return YES;
}

-(void) concatenateFileCollection: (FileCollection *)otherCollection {
    [fileArray addObjectsFromArray:[otherCollection fileArray]];
    rootDirectory = nil; // It will be calculated next time the rootPath is called
    //NSLog(@"The total of files to scan is now %ld",[fileArray count] );
}

-(void) resetDuplicateLists {
    for (FileInformation * filei in fileArray) {
        [filei resetDuplicates];
    }
}


// This method returns a new FileCollection with only the files that have duplicates
-(FileCollection*) FilesWithDuplicates {
    FileCollection *result = [[FileCollection new] init];
    for (FileInformation *fi in fileArray) {
        if ([fi duplicateCount]!=0)
            [result AddFileInformation:fi];
    }
    result->rootDirectory = self->rootDirectory;
    return result;
}

-(void) streamFilesWithDuplicates {
    NSMutableArray *old = fileArray; // Make a copy of the old pointer
    fileArray = [[self FilesWithDuplicates] fileArray]; // re-initialize
    [old removeAllObjects]; // Cleans up the old array
}

-(void) sortByFileSize {
    [fileArray sortUsingSelector:@selector(compareSize:)];
}

@end