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

extern NSString *const kvoTreeBranchPropertyChildren;

/* Enumerate to be used on the result of the path relation compare method */
typedef NS_ENUM(NSInteger, enumPathCompare) {
    pathsHaveNoRelation = 1,
    pathIsChild = 0,
    pathIsParent = -1
};


@interface TreeBranch : TreeItem <TreeProtocol> {
    BOOL refreshing;
}


@property (retain) NSMutableArray *children;

-(TreeBranch*) init;
-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;

-(void) dealloc;


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

-(BOOL) isExpandable;

-(TreeItem*) itemWithName:(NSString*) name class:(id)cls;
-(BOOL) addURL:(NSURL*)theURL;

//-(NSMutableArray*) branchesInBranch;

//-(FileCollection*) duplicatesInNode;
//-(FileCollection*) duplicatesInBranch;

-(void) refreshTreeFromURLs;
-(void)refreshContentsOnQueue: (NSOperationQueue *) queue;

-(NSInteger) relationTo:(NSString*) otherPath;

// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

@end
