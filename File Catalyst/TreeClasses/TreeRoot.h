//
//  TreeRoot.h
//  FileCatalyst1
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCollection.h"
#import "TreeBranch.h"


@interface TreeRoot : TreeBranch <TreeProtocol> {
    FileCollection* _fileCollection;
    NSString* _name;
}

-(void) setName:(NSString*)name;
-(NSString*) name;

-(void) setFileCollection:(FileCollection*)collection;

@end
