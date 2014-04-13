//
//  TreeRoot.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCollection.h"
#import "TreeBranch.h"

@interface TreeRoot : TreeBranch <TreeProtocol> {
    FileCollection *_fileCollection;
    //NSString *rootDirectory;
}


-(void) setFileCollection:(FileCollection*)collection;
-(FileCollection *) fileCollection;
-(NSString*) rootPath;
-(void) refreshTree;

@end
