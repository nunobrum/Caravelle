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
    self->fileArray = nil;
    return self;
}



-(void) addFile: (TreeLeaf*) item {
    if (fileArray==nil)
        fileArray = [[NSMutableArray new] init];
    [fileArray addObject:item];
    
}

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
        }
    }
}

-(void) setFiles:(NSArray *)otherArray {
    self->fileArray = [NSMutableArray arrayWithArray:otherArray];
}

//-(NSInteger) FileCount {
//    return [fileArray count];
//}
//

-(NSMutableArray*) fileArray {
    return fileArray;
}


-(FileCollection*) filesInPath:(NSString*) path {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeLeaf *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame)
            [newCollection addFile:finfo];

    }
    return newCollection;
}

-(FileCollection*) duplicatesInPath:(NSString*) path dCounter:(NSUInteger)dCount {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeLeaf *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame) {
            TreeLeaf *cursor=[finfo nextDuplicate];
            while (cursor!=finfo) {
                if ([cursor duplicateRefreshCount]!=dCount) {
                    [newCollection addFile:cursor];
                    [cursor setDuplicateRefreshCount: dCount];
                }
                cursor = [cursor nextDuplicate];
            }
        }
    }
    return newCollection;
}

-(void) concatenateFileCollection: (FileCollection *)otherCollection {
    if (fileArray==nil) 
        fileArray = [NSMutableArray arrayWithArray:[otherCollection fileArray]];
    else
        [fileArray addObjectsFromArray:[otherCollection fileArray]];
}

@end