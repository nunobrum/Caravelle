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

#import "definitions.h"

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

//-(NSInteger) numberOfFileDuplicatesInBranch {
//    NSInteger total = 0;
//    for (TreeItem *item in _children) {
//        if ([item isKindOfClass:[TreeBranch class]]==YES) {
//            total += [(TreeBranch*)item numberOfFileDuplicatesInBranch];
//        }
//        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
//            if ([[(TreeLeaf*)item getFileInformation] duplicateCount]!=0)
//                total++;
//        }
//    }
//    return total;
//}


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
            FileInformation *finfo;
            finfo = [FileInformation createWithURL:[(TreeLeaf*)item theURL]];
            [answer AddFileInformation:finfo];
        }
    }
    
    return answer; 
}
-(FileCollection*) filesInBranch {
    return nil; // Pending Implementation
}
-(NSMutableArray*) itemsInNode {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [answer addObjectsFromArray:self->_children];
    return answer;
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


//-(FileCollection*) duplicatesInNode {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item isKindOfClass:[TreeLeaf class]]==YES) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}
//
//-(FileCollection*) duplicatesInBranch {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeItem *item in _children) {
//        if ([item isKindOfClass:[TreeBranch class]]==YES) {
//            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
//        }
//        else if ([item isKindOfClass:[TreeLeaf class]]==YES) {
//            [answer addFiles: [[(TreeLeaf*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}

/* This is not to be used with Catalyst Mode */
-(void) refreshTreeFromURLs {
    // Will get the first level of the tree
    TreeBranch *cursor, *currdir;
    long oldByteSize = 0;

    if ([self children]==nil)
        [self setChildren: [[NSMutableArray new] init]];
    else {
        NSLog(@"Tree %@ was already constructed", self.path);
        return;
        oldByteSize = self.byteSize;
        /* Subtract existing files before updating */

        for (TreeItem *item in _children) {
            if ([item isKindOfClass:[TreeLeaf class]]==YES) {
                self.byteSize -= [item byteSize];
                //oldNumberOfFiles++;
                [_children removeObject:item];
            }
        }
    }
    NSURL *directoryToScan = [NSURL fileURLWithPath:self.path];
    NSLog(@"Scanning directory %@", self.path);
    NSInteger level0 = [[directoryToScan pathComponents] count];
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:directoryToScan WithMode:NO];


    for (NSURL *theURL in dirEnumerator) {

        NSArray *pathComponents = [theURL pathComponents];
        NSInteger level;

        // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
        NSNumber *fileSize;
        [theURL getResourceValue:&fileSize     forKey:NSURLFileSizeKey error:NULL];
        self.byteSize += [fileSize longLongValue];; // Add the size of the file to the directory

        NSNumber *isDirectory;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];

        unsigned long pathComponents2;
        if ([isDirectory boolValue]==NO)
            pathComponents2 = [pathComponents count]-1;
        else
            pathComponents2 = [pathComponents count];

        currdir = (TreeBranch*)self;
        NSURL *currURL = [self theURL];
        
        for (level=level0; level < pathComponents2; level++) { //last path component is the file name
            NSString *dirName = [pathComponents objectAtIndex:level];
            //NSLog(@"<%@>",dirName);
            NSURL *newdir;// = [NSURL new];
            newdir = [currURL URLByAppendingPathComponent:dirName isDirectory:YES];
            cursor = nil;
            for (TreeBranch *subdir in [currdir branchesInNode]){
                // If the two are the same
                //NSLog(@"subdir %@ currdir %@",[subdir name],dirName);
                if ([newdir isEqualTo:[subdir theURL]]) {
                    cursor = subdir;
                    cursor.byteSize += [fileSize longLongValue];
                    break;
                }
            }
            if (cursor==nil) { // the directory doesn't exit
                TreeBranch *newDir = [[TreeBranch new] init];  // Create the new directory or file
                newDir.theURL = newdir ;
                newDir.parent = currdir;
                newDir.children = nil; //[[NSMutableArray new] init];
                newDir.byteSize = [fileSize longLongValue];
                [[currdir children] addObject: newDir]; // Adds the created file or directory to the current directory
                currdir = newDir;
                currURL = newdir;

            } // if
            else {
                currdir = cursor;
                currURL = [cursor theURL];
            }
        } //for
        if ([isDirectory boolValue]==NO) {
            // Its a file, Now adding the File
            TreeLeaf *newFile = [[TreeLeaf new] init];  // Create the new directory or file
            newFile.theURL = theURL;
            newFile.parent = currdir;
            newFile.byteSize = [fileSize longLongValue];
            if (currdir.children==nil) {
                currdir.children =[[NSMutableArray new] init];
            }
            [[currdir children] addObject: newFile]; // Adds the created file or directory to the current director
        }
    } // for

    /* Now will propagate new totals to parent directories */
    currdir = (TreeBranch*)[self parent];
    while (currdir!=nil) {
        currdir.byteSize+= self.byteSize - oldByteSize;
        currdir = (TreeBranch*)[currdir parent];
    }
}

-(NSInteger) relationTo:(NSString*) otherRoot {
    NSRange result;
    NSInteger answer = rootHasNoRelation;
    result = [otherRoot rangeOfString:[self path]];
    if (NSNotFound!=result.location) {
        // The new root is already contained in the existing trees
        answer = rootAlreadyContained;
        NSLog(@"The added path is contained in existing roots.");

    }
    else {
        /* The new contains exiting */
        result = [[self path] rangeOfString:otherRoot];
        if (NSNotFound!=result.location) {
            // Will need to replace current position
            answer = rootContainsExisting;
            NSLog(@"The added path contains already existing roots, please delete them.");
            //[root removeBranch];
            //fileCollection_inst = [root fileCollection];
        }
    }
    return answer;
}

@end
