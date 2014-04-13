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

@implementation TreeRoot

-(void) setFileCollection:(FileCollection*)collection {
    _fileCollection = collection;
}

-(FileCollection *) fileCollection {
    return _fileCollection;
}

-(NSString*) rootPath {
    return [_fileCollection rootPath];
}

-(void) refreshTree {
    // Will get the first level of the tree
    TreeBranch *cursor, *currdir;
    //TreeRoot* rootDir = self;
    
    //FileCollection *fileCollection = [rootDir fileCollection];
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
        NSString *fileName = [finfo getName];
        NSNumber *fileSize = [finfo getFileSize];
        NSDate *dateModified = [finfo getDateModified];
        //NSLog(@"%@--->",fileName);
        
        self.byteSize += [fileSize longLongValue]; // Add the size of the file to the directory
        currdir = (TreeBranch*)self;
        for (level=level0; level < [pathComponents count]-1; level++) { //last path component is the file name
            NSString *dirName = [pathComponents objectAtIndex:level];
            //NSLog(@"<%@>",dirName);
            cursor = nil;
            for (TreeBranch *subdir in [currdir children]){
                // If the two are the same
                if ([[subdir name]compare: dirName]==NSOrderedSame) {
                    cursor = subdir;
                    cursor.byteSize += [fileSize longLongValue];
                    break;
                }
            }
            if (cursor==nil) { // the directory doesn't exit
                TreeBranch *newDir = [[TreeBranch new] init];  // Create the new directory or file
                newDir.name = dirName;
                newDir.parent = currdir;
                newDir.children = [[NSMutableArray new] init];
                newDir.byteSize = [fileSize longLongValue];
                [[currdir children] addObject: newDir]; // Adds the created file or directory to the current directory
                currdir = newDir;
                
            } // if
            else
                currdir = cursor;
            
        } //for
        // Now adding the File
        TreeLeaf *newFile = [[TreeLeaf new] init];  // Create the new directory or file
        newFile.name = fileName;
        newFile.parent = currdir;
        newFile.byteSize = [fileSize longLongValue];
        newFile.dateModified = dateModified;
        [newFile SetFileInformation: finfo];
        [[currdir children] addObject: newFile]; // Adds the created file or directory to the current director
        
    } // for
}

@end
