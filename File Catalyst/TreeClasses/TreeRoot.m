//
//  TreeRoot.m
//  Caravelle
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeRoot.h"
#import "TreeBranch_TreeBranchPrivate.h"

@implementation TreeRoot

-(void) setName:(NSString*)name {
    self->_name = name;
}

-(NSString*) name {
    return self->_name;
}

-(void) setFileCollection:(FileCollection*)collection {
    self->_fileCollection = collection;
    [self releaseChildren];
    
    NSString *patH = commonPathFromItems(collection.fileArray);
    NSURL *rootURL = [NSURL fileURLWithPath:patH isDirectory:YES];
    if (rootURL==nil) {
        NSLog(@"TreeRoot.treeWithFileCollection: - Error: The NSURL wasnt sucessfully created after commonPath");
        return;
    }
    self.url = rootURL;
    for (TreeItem *finfo in collection.fileArray) {
        [self addTreeItem:finfo];
    }
}


@end
