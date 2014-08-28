//
//  TreeRoot.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeRoot.h"
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


-(void) refreshTreeFromCollection:(void (^)(NSInteger fileno))callbackhandler {
    NSInteger fileno=0;
    if (_isCollectionSet && _fileCollection!=nil) {
        if ([self children]==nil)
            [self setChildren: [[NSMutableArray new] init]];
        else
            [self removeBranch];

        for (FileInformation *finfo in _fileCollection.fileArray) {
            [self addURL:finfo.getURL];
            if (0 ==(fileno % UPDATE_CADENCE_PER_FILE))
                callbackhandler(fileno);
            fileno++;

        } // for
    }
    else
        NSLog(@"Ooops! This wasn't supposed to happen. File collection should have been set");
}

+(TreeRoot*) treeWithFileCollection:(FileCollection *)fileCollection callback:(void (^)(NSInteger fileno))callbackhandler {
    if (fileCollection!=nil && [fileCollection FileCount]>0 ) {


        TreeRoot *rootDir = [[TreeRoot new] init];
        NSURL *rootpath = [NSURL URLWithString:[fileCollection commonPath]];

        // assigns the name to the root directory
        [rootDir setUrl: rootpath];
        [rootDir setFileCollection: fileCollection];
        [rootDir setIsCollectionSet:YES];

        /* Refresh the Trees so that the trees are displayed */
        [rootDir refreshTreeFromCollection:callbackhandler];
        return rootDir;
    }
    else
        return NULL;
}


+(TreeRoot*) treeWithURL:(NSURL*) rootURL {

    TreeRoot *rootDir = [[TreeRoot new] init];
    // assigns the name to the root directory
    [rootDir setUrl: rootURL];
    [rootDir setFileCollection: NULL];
    [rootDir setIsCollectionSet:NO];
    return rootDir;

}

+(TreeRoot*) treeFromPath:(NSString*)rootPath {
    TreeRoot *rootDir = [[TreeRoot new] init];
    rootDir.children = [[NSMutableArray new] init];
    rootDir.url = [NSURL URLWithString:rootPath];
    NSLog(@"Scanning directory %@", rootDir.path);
    MyDirectoryEnumerator *dirEnumerator = [[MyDirectoryEnumerator new ] init:rootDir->_url WithMode:BViewCatalystMode];
    for (NSURL *theURL in dirEnumerator) {
        [rootDir addURL:theURL];
    } // for
    return rootDir;
}


@end
