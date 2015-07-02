//
//  DirectoryIterator.m
//  FileCatalyst1
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileUtils.h"
#import "FileCollection.h"

#import "Definitions.h"


@implementation FileCollection: NSObject

-(FileCollection *) init {
    self = [super init];
    self->fileArray = [[NSMutableArray new] init];
    self->rootDirectory = nil;
    return self;
}


/*-(void) addFilesInDirectory:(NSString *)rootpath callback:(void (^)(NSInteger fileno))callbackhandler
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

        // Retrieve whether a directory. From NSURLIsDirectoryKey, also
        // cached during the enumeration.
        NSNumber *isDirectory;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        // Ignore files under the _extras directory
        //if (([fileName caseInsensitiveCompare:@"_extras"]==NSOrderedSame) &&
        //    ([isDirectory boolValue]==YES))
        //{
        //    [dirEnumerator skipDescendants];
        //}
        //else
        if ([isDirectory boolValue]==NO)
        {
            [self->fileArray addObject: [TreeItem treeItemForURL:theURL parent:nil]];
            fileno+=1;
        }
        callbackhandler(fileno);
    }
    
    // Release the localFileManager.
    //[localFileManager release]; Commenting this line because automatic reference count is activated
    
    
}*/

-(void) addFile: (TreeItem*) item {
    if (fileArray==nil)
        fileArray = [[NSMutableArray new] init];
    [fileArray addObject:item];
    
}

//-(void) addFileByURL: (NSURL *) anURL {
//    FileInformation *fi = [FileInformation createWithURL:anURL];
//    if (fileArray==nil)
//        fileArray = [[NSMutableArray new] init];
//    [fileArray addObject:fi];    
//}

-(void) addFiles: (NSArray *)otherArray {
    if (otherArray!=nil) { // Will only do anything if the other array is valid
        if (fileArray==nil) {
            fileArray = [[NSMutableArray new] init];
            [fileArray addObjectsFromArray:otherArray];
        }
        else {
            for (TreeItem *fi in otherArray) {
                if (NSNotFound==[fileArray indexOfObject:fi]) {
                    // Adds only if it doesn't already exist
                    [fileArray addObject:fi];
                }
            }
            rootDirectory = nil; // It will be calculated next time the rootPath is called
        }
    }
}
-(void) setFiles:(NSArray *)otherArray {
    self->fileArray = [NSMutableArray arrayWithArray:otherArray];
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
        for (TreeItem *fi in fileArray) {
            if (common_path==nil)
            {
                common_path = [[fi url] pathComponents];
                ci = [common_path count]-1; /* This will exclude the file name */
            }
            else
            {
                NSInteger i;
                file_path = [[fi url] pathComponents];
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


-(FileCollection*) filesInPath:(NSString*) path {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeItem *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame)
            [newCollection->fileArray addObject:finfo];

    }
    return newCollection;
}

-(FileCollection*) duplicatesInPath:(NSString*) path dCounter:(NSUInteger)dCount {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeItem *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame) {
            TreeItem *cursor=[finfo nextDuplicate];
            while (cursor!=finfo) {
                if ([cursor duplicateRefreshCount]!=dCount) {
                    [newCollection->fileArray addObject:cursor];
                    [cursor setDuplicateRefreshCount: dCount];
                }
                cursor = [cursor nextDuplicate];
            }
        }
    }
    return newCollection;
}

/*
-(BOOL) isRootContainedInPath:(NSString *)path {
    enumPathCompare test = path_relation(rootDirectory, path);
    if (test == pathIsParent)
        return YES;
    else
        return NO;
}

-(BOOL) rootContainsPath:(NSString *)otherRoot {
    enumPathCompare test = path_relation(rootDirectory, otherRoot);
    if (test == pathIsChild || test == pathIsSame)
        return YES;
    else
        return NO;
}

-(BOOL) isRootContainedIn:(FileCollection *)otherCollection {
    NSRange result;
    result = [ rangeOfString:rootDirectory];
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
*/
-(void) concatenateFileCollection: (FileCollection *)otherCollection {
    [fileArray addObjectsFromArray:[otherCollection fileArray]];
    rootDirectory = nil; // It will be calculated next time the rootPath is called
    //NSLog(@"The total of files to scan is now %ld",[fileArray count] );
}

-(void) resetDuplicateLists {
    for (TreeItem * filei in fileArray) {
        [filei resetDuplicates];
    }
}


// This method returns a new FileCollection with only the files that have duplicates
-(FileCollection*) FilesWithDuplicates {
    FileCollection *result = [[FileCollection new] init];
    for (TreeItem *fi in fileArray) {
        if ([fi duplicateCount]!=0)
            [result->fileArray addObject:fi];
    }
    result->rootDirectory = self->rootDirectory;
    return result;
}

-(void) streamFilesWithDuplicates {
    NSMutableArray *old = fileArray; // Make a copy of the old pointer
    fileArray = [[self FilesWithDuplicates] fileArray]; // re-initialize
    [old removeAllObjects]; // Cleans up the old array
}

//-(void) sortByFileSize {
//    [fileArray sortUsingSelector:@selector(compareSize:)];
//}

@end