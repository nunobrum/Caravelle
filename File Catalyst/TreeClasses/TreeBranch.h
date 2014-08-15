//
//  TreeBranch.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "TreeLeaf.h"
#import "FileCollection.h"

/* Enumerate to be used on the result of the path relation compare method */
enum enumPathCompare {
    pathsHaveNoRelation = 1,
    pathIsChild = 0,
    pathIsParent = -1
};


@interface TreeBranch : TreeItem <TreeProtocol>

@property (retain) TreeBranch     *parent;


@property (retain) NSMutableArray *children;

-(TreeBranch*) init;
-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;

-(void) dealloc;

-(TreeItem*) root;

-(BOOL)      isBranch;
-(void)      removeBranch;
-(NSInteger) numberOfLeafsInNode;
-(NSInteger) numberOfBranchesInNode;
-(NSInteger) numberOfItemsInNode;

-(NSInteger) numberOfLeafsInBranch;

//-(NSInteger) numberOfFileDuplicatesInBranch;

-(TreeBranch*) branchAtIndex:(NSUInteger)index;
-(TreeLeaf*) leafAtIndex:(NSUInteger)index;

-(long long) sizeOfNode;
-(long long) filesize;

-(FileCollection*) filesInNode;
-(FileCollection*) filesInBranch;
-(NSMutableArray*) itemsInNode;
-(NSMutableArray*) itemsInBranch;
-(NSMutableArray*) leafsInNode;
-(NSMutableArray*) leafsInBranch;
-(NSMutableArray*) branchesInNode;

-(TreeItem*) itemWithName:(NSString*) name class:(id)cls;
-(BOOL) addURL:(NSURL*)theURL;

//-(NSMutableArray*) branchesInBranch;

//-(FileCollection*) duplicatesInNode;
//-(FileCollection*) duplicatesInBranch;

-(void) refreshTreeFromURLs;

-(NSInteger) relationTo:(NSString*) otherPath;

// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

@end
