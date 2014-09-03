//
//  TreeRoot.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeRoot.h"
#import "TreeBranch_TreeBranchPrivate.h"
#import "TreeLeaf.h"
#import "FileCollection.h"
#import "MyDirectoryEnumerator.h"

#import "definitions.h"

@implementation TreeRoot


-(FileCollection *) fileCollection {
    if (_isCollectionSet== NO) {
        // !!! To be implemented : Will construct the file collection from the tree
    }
    return _fileCollection;
}

-(NSString*) rootPath {
    return self.path; //rootDirectory; //[_fileCollection rootPath];
}

-(void) setFileCollection:(FileCollection*)collection {
    _fileCollection = collection;
    _isCollectionSet = YES;
}


+(TreeRoot*) treeWithFileCollection:(FileCollection *)fileCollection {
    if (fileCollection!=nil && [fileCollection FileCount]>0 ) {
        NSInteger fileno=0;

        NSString *patH = [fileCollection commonPath];
        NSURL *rootURL = [NSURL fileURLWithPath:patH isDirectory:YES];
        if (rootURL==nil) {
            NSLog(@"We have a problem here. The NSURL wasnt sucessfully created after commonPath");
        }
        TreeRoot *rootDir = [[TreeRoot new] initWithURL:rootURL parent:nil];

        // assigns the name to the root directory
        [rootDir setFileCollection: fileCollection];
        [rootDir setIsCollectionSet:YES];

        /* Since a new tree is created there is no problems with contentions */

        /* Refresh the Trees so that the trees are displayed */
        for (FileInformation *finfo in fileCollection.fileArray) {
            [rootDir addURL:finfo.getURL];
            fileno++;

        } // for

        return rootDir;
    }
    else
        return NULL;
}


+(TreeRoot*) treeWithURL:(NSURL*) rootURL {

    TreeRoot *rootDir = [[TreeRoot new] initWithURL:rootURL parent:nil];
    // assigns the name to the root directory
    [rootDir setFileCollection: NULL];
    [rootDir setIsCollectionSet:NO];
    return rootDir;

}

+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock {
    TreeRoot *tree = [TreeRoot alloc];
    tree = [tree initFromEnumerator:dirEnum URL:rootURL parent:parent cancelBlock:cancelBlock];
    tree->_fileCollection = NULL;
    tree->_isCollectionSet = NO;
    return tree;
}

//+(TreeRoot*) treeFromPath:(NSString*)rootPath {
//    TreeRoot *rootDir = [[TreeRoot new] init];
//    rootDir.children = [[NSMutableArray new] init];
//    rootDir.url = [NSURL URLWithString:rootPath];
//    NSLog(@"Scanning directory %@", rootDir.path);
//    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:rootDir->_url WithMode:BViewCatalystMode];
//    @synchronized(self) {
//        for (NSURL *theURL in dirEnumerator) {
//            [rootDir addURL:theURL];
//        } // for
//    }
//    return rootDir;
//}


@end
