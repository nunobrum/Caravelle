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

@private
    NSMutableArray *children;
}

-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;

-(BOOL)      isBranch;
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

//-(NSMutableArray*) branchesInBranch;

//-(FileCollection*) duplicatesInNode;
//-(FileCollection*) duplicatesInBranch;

+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(void)refreshContentsOnQueue: (NSOperationQueue *) queue;

-(NSInteger) relationTo:(NSString*) otherPath;
-(BOOL) containsURL:(NSURL*)url;

// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

/*
 * File Manipulation methods
 */
-(BOOL) sendToRecycleBinItem:(TreeItem*) item;
-(BOOL) eraseItem:(TreeItem*) item;
-(BOOL) copyItem:(TreeItem*)item To:(NSString*)path;
-(BOOL) MoveItem:(TreeItem*)item To:(NSString*)path;

@end
