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


-(void) refreshTreeFromCollection:(void (^)(NSInteger fileno))callbackhandler {
    NSInteger fileno=0;
    @synchronized(self) {
        if (_isCollectionSet && _fileCollection!=nil && !refreshing) {
            self->refreshing = YES;
            [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
            [self removeBranch];
            for (FileInformation *finfo in _fileCollection.fileArray) {
                [self addURL:finfo.getURL];
                if (0 ==(fileno % UPDATE_CADENCE_PER_FILE))
                    callbackhandler(fileno);
                fileno++;

            } // for
            self->refreshing=FALSE;
            [self didChangeValueForKey:kvoTreeBranchPropertyChildren]; // This will inform the observer about change
        }
        else
            NSLog(@"Ooops! This wasn't supposed to happen. File collection should have been set");
    }
}

+(TreeRoot*) treeWithFileCollection:(FileCollection *)fileCollection callback:(void (^)(NSInteger fileno))callbackhandler {
    if (fileCollection!=nil && [fileCollection FileCount]>0 ) {


        TreeRoot *rootDir = [[TreeRoot new] init];
        NSString *patH = [fileCollection commonPath];
        NSURL *rootURL = [NSURL fileURLWithPath:patH isDirectory:YES];
        if (rootURL==nil) {
            NSLog(@"We have a problem here. The NSURL wasnt sucessfully created after commonPath");
        }
        // assigns the name to the root directory
        [rootDir setUrl: rootURL];
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

    TreeRoot *rootDir = [[TreeRoot new] initWithURL:rootURL parent:nil];
    // assigns the name to the root directory
    [rootDir setFileCollection: NULL];
    [rootDir setIsCollectionSet:NO];
    return rootDir;

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
