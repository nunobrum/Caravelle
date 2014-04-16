//
//  TreeBranch.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"
#import "TreeLeaf.h"
#import "MyDirectoryEnumerator.h"

@interface TreeBranch( PrivateMethods )

-(void) _harvestItemsInBranch:(NSMutableArray*)collector;
-(void) _harvestLeafsInBranch:(NSMutableArray*)collector;

@end

@implementation TreeBranch

-(BOOL) isBranch {
    return YES;
}

-(TreeBranch*) init {
    self = [super init];
    self->_children = nil;
    return self;
}

-(void) removeBranch {
    for (TreeItem *item in _children) {
        if ([item isBranch])
            [(TreeBranch*)item removeBranch];
    }
    [[self children] removeAllObjects];
    //[self setDateModified:nil];
    [self setByteSize:0];
}


-(NSInteger) numberOfLeafsInNode {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            total++;
        }
    }
    return total;
}

-(NSInteger) numberOfBranchesInNode {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total++;
        }
    }
    return total;
}

-(NSInteger) numberOfItemsInNode {
    return [_children count];
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total += [(TreeBranch*)item numberOfLeafsInBranch];
        }
        else
            total++;
    }
    return total;
}

-(NSString*) path {
    return [self.theURL path];
}

-(NSInteger) numberOfFileDuplicatesInBranch {
    NSInteger total = 0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            total += [(TreeBranch*)item numberOfFileDuplicatesInBranch];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            if ([[(TreeLeaf*)item getFileInformation] duplicateCount]!=0)
                total++;
        }
    }
    return total;
}


-(TreeBranch*) branchAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            if (i==index)
                return (TreeBranch*)item;
            i++;
        }
    }
    return nil;
}

-(TreeLeaf*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            if (i==index)
                return (TreeLeaf*)item;
            i++;
        }
    }
    return nil;
}



-(FileCollection*) filesInNode {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer AddFileInformation:[(TreeLeaf*)item getFileInformation]];
        }
    }
    
    return answer; 
}
-(FileCollection*) filesInBranch {
    return nil; // Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    return self->_children;
}

-(void) _harvestItemsInBranch:(NSMutableArray*)collector {
    [collector addObjectsFromArray: _children];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestItemsInBranch: collector];
        }
    }
}
-(NSMutableArray*) itemsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestItemsInBranch:answer];
    return answer; // Pending Implementation
}

-(NSMutableArray*) leafsInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addObject:item];
        }
    }
    return answer;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector {
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [(TreeBranch*)item _harvestLeafsInBranch: collector];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [collector addObject:item];
        }
    }
}
-(NSMutableArray*) leafsInBranch {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestLeafsInBranch: answer];
    return answer; // Pending Implementation
}

-(NSMutableArray*) branchesInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [answer addObject:item];
        }
    }
    return answer;

}


-(FileCollection*) duplicatesInNode {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
        }
    }
    return answer;
}

-(FileCollection*) duplicatesInBranch {
    FileCollection *answer = [[FileCollection new] init];
    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
        }
    }
    return answer;
}

/* This is not to be used with Catalyst Mode */
-(void) refreshTreeFromURLs {
    // Will get the first level of the tree
    TreeBranch *cursor, *currdir;
    long oldByteSize = 0;

    if ([self children]==nil)
        [self setChildren: [[NSMutableArray new] init]];

    oldByteSize = self.byteSize;
    /* Subtract existing files before updating */

    for (TreeItem *item in _children) {
        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
            self.byteSize -= [item byteSize];
            //oldNumberOfFiles++;
            [_children removeObject:item];
        }
    }
    NSURL *directoryToScan = [NSURL fileURLWithPath:self.path];
    NSInteger level0 = [[directoryToScan pathComponents] count];
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:directoryToScan WithMode:NO];


    for (NSURL *theURL in dirEnumerator) {

        NSArray *pathComponents = [theURL pathComponents];
        NSInteger level;

        // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
        NSNumber *fileSize;
        [theURL getResourceValue:&fileSize     forKey:NSURLFileSizeKey error:NULL];


        self.byteSize += [fileSize longLongValue];; // Add the size of the file to the directory
        currdir = (TreeBranch*)self;
        for (level=level0; level < [pathComponents count]-1; level++) { //last path component is the file name
            NSString *dirName = [pathComponents objectAtIndex:level];
            //NSLog(@"<%@>",dirName);
            cursor = nil;
            for (TreeBranch *subdir in [currdir children]){
                // If the two are the same
                if ([[[subdir theURL] lastPathComponent]compare: dirName]==NSOrderedSame) {
                    cursor = subdir;
                    cursor.byteSize += [fileSize longLongValue];;
                    break;
                }
            }
            if (cursor==nil) { // the directory doesn't exit
                TreeBranch *newDir = [[TreeBranch new] init];  // Create the new directory or file
                newDir.theURL = theURL;
                newDir.parent = currdir;
                newDir.children = [[NSMutableArray new] init];
                newDir.byteSize = [fileSize longLongValue];;
                [[currdir children] addObject: newDir]; // Adds the created file or directory to the current directory
                currdir = newDir;

            } // if
            else
                currdir = cursor;

        } //for
        // Now adding the File
        TreeLeaf *newFile = [[TreeLeaf new] init];  // Create the new directory or file
        FileInformation *finfo = [FileInformation createWithURL:theURL];
        newFile.theURL = theURL;
        newFile.parent = currdir;
        newFile.byteSize = [fileSize longLongValue];
        [newFile SetFileInformation: finfo];
        [[currdir children] addObject: newFile]; // Adds the created file or directory to the current director

    } // for

    /* Now will propagate new totals to parent directories */
    currdir = (TreeBranch*)self;
    while (currdir!=nil) {
        currdir.byteSize+= self.byteSize - oldByteSize;
        currdir = (TreeBranch*)[currdir parent];
    }
}


@end
