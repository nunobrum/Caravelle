//
//  DirectoryIterator.m
//  Caravelle
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileUtils.h"
#import "FileCollection.h"

#import "Definitions.h"
#import "TreeLeaf.h"

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

// duplicatesInPath:dCounter
// This selector returns all the duplicates of a given path together with all their brothers
// To simplify the algorithm of collecting duplicates without collecting more than two times
// the same files, a counter is used per collection done.
// When a file is found as duplicate, its counter is updated to the newest collecting number.
// If a file is found to have already the most recent collecting number, then it's not added.
// This way of operation avoid having to compare each found duplicate with the existing
// collecting set.
-(FileCollection*) duplicatesInPath:(NSString*) path dCounter:(NSUInteger)dCount {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeLeaf *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame) {
            TreeLeaf *cursor=[finfo nextDuplicate];
            if (cursor==nil)
                NSLog(@"FileCollection.duplicatesInPath: Deleted Duplicate %@",finfo.url);
            else {
                while (cursor!=finfo) {
                    if ([cursor duplicateRefreshCount]!=dCount) {
                        [newCollection addFile:cursor];
                        [cursor setDuplicateRefreshCount: dCount];
                    }
                    cursor = [cursor nextDuplicate];
                }
            }
        }
    }
    return newCollection;
}


// duplicatesOfPath:dCounter
// This selector returns all the "brothers" of the duplicate files in a given path
// See duplicatesInPath:dCounter for more information on the operation.
-(FileCollection*) duplicatesOfPath:(NSString*) path dCounter:(NSUInteger)dCount {
    FileCollection *newCollection = [[FileCollection new] init];
    for (TreeLeaf *finfo in fileArray) {
        enumPathCompare test = path_relation(path, finfo.path);
        if (test == pathIsChild || test == pathIsSame) {
            TreeLeaf *cursor=[finfo nextDuplicate];
            if (cursor==nil)
                NSLog(@"FileCollection.duplicatesInPath: Deleted Duplicate %@",finfo.url);
            else {
                while (cursor!=finfo) {
                    test = path_relation(path, cursor.path);
                    if (test != pathIsChild && test != pathIsSame) {
                        if ([cursor duplicateRefreshCount]!=dCount) {
                            [newCollection addFile:cursor];
                            [cursor setDuplicateRefreshCount: dCount];
                        }
                    }
                    cursor = [cursor nextDuplicate];
                }
            }
        }
    }
    return newCollection;
}

+(FileCollection*) duplicatesOfFiles:(NSArray*)fileArray dCounter:(NSUInteger)dCount {
    FileCollection *newCollection = [[FileCollection new] init];
    newCollection->fileArray = [[NSMutableArray new] init];
    for (TreeLeaf *finfo in fileArray) {
        if ([finfo respondsToSelector:@selector(nextDuplicate)]) {
            [finfo setDuplicateRefreshCount:dCount]; // This avoids that the file itself is added.
            TreeLeaf *cursor=[finfo nextDuplicate];
            if (cursor==nil)
                NSLog(@"FileCollection.duplicatesInPath: Deleted Duplicate %@",finfo.url);
            else {
                while (cursor!=finfo) {
                    if ([cursor duplicateRefreshCount]!=dCount) {
                        [newCollection->fileArray addObject:cursor];
                        [cursor setDuplicateRefreshCount: dCount];
                    }
                    
                    cursor = [cursor nextDuplicate];
                }
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