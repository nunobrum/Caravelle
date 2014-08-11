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
    // Will get the first level of the tree
    TreeBranch *cursor, *currdir;
    //TreeRoot* rootDir = self;
    NSInteger fileno=0;

    if (_isCollectionSet && _fileCollection!=nil) {

        NSInteger level0 = [[[NSURL fileURLWithPath:[_fileCollection rootPath]] pathComponents] count];



        if ([self children]==nil)
            [self setChildren: [[NSMutableArray new] init]];
        else
            [self removeBranch];

        for (FileInformation *finfo in _fileCollection.fileArray) {
            //NSURL *handler = finfo.getURL;

            NSArray *pathComponents = [finfo getPathComponents];
            NSInteger level;

            // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
            NSNumber *fileSize = [finfo getFileSize];
            //NSLog(@"%@--->",[finfo getName]);

            self.byteSize += [fileSize longLongValue]; // Add the size of the file to the directory
            currdir = (TreeBranch*)self;
            NSURL *currURL = [self theURL];
            for (level=level0; level < [pathComponents count]-1; level++) { //last path component is the file name
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
            // Now adding the File
            TreeLeaf *newFile = [[TreeLeaf new] init];  // Create the new directory or file
            newFile.theURL = [finfo getURL];
            newFile.parent = currdir;
            newFile.byteSize = [fileSize longLongValue];
            //[newFile SetFileInformation: finfo];
            if (currdir.children==nil) {
                currdir.children =[[NSMutableArray new] init];
            }
            [[currdir children] addObject: newFile]; // Adds the created file or directory to the current director
            if (0 ==(fileno % UPDATE_CADENCE_PER_FILE))
                callbackhandler(fileno);
            fileno++;

        } // for
    }
    else
        NSLog(@"Ooops! This wasn't supposed to happen. File collection should have been set");
}

+(TreeRoot*) treeWithFileCollection:(FileCollection *)fileCollection callback:(void (^)(NSInteger fileno))callbackhandler {
    TreeRoot *rootDir = [[TreeRoot new] init];
    NSURL *rootpath = [NSURL URLWithString:[fileCollection rootPath]];

    // assigns the name to the root directory
    [rootDir setTheURL: rootpath];
    [rootDir setFileCollection: fileCollection];
    [rootDir setIsCollectionSet:YES];

    /* Refresh the Trees so that the trees are displayed */
    [rootDir refreshTreeFromCollection:callbackhandler];
    return rootDir;
}


+(TreeRoot*) treeWithURL:(NSURL*) rootPath {

    TreeRoot *rootDir = [[TreeRoot new] init];
    // assigns the name to the root directory
    [rootDir setTheURL: rootPath];
    [rootDir setFileCollection: NULL];
    [rootDir setIsCollectionSet:NO];
    return rootDir;

}



@end
