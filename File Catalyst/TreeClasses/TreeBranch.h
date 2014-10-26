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
    pathIsSame = 0,
    pathsHaveNoRelation = 1,
    pathIsParent = 2,
    pathIsChild = 3
};

extern NSString* commonPathFromItems(NSArray* itemArray);

@interface TreeBranch : TreeItem <TreeProtocol> {

@protected
    NSMutableArray *_children;
}

-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;
-(TreeBranch*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;


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

-(TreeItem*) childWithName:(NSString*) name class:(id)cls;
-(TreeItem*) childWithURL:(NSURL*)url;
-(TreeItem*) childContainingURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) addURL:(NSURL*)theURL;

-(BOOL) addTreeItem:(TreeItem*)treeItem;


//-(NSMutableArray*) branchesInBranch;

//-(FileCollection*) duplicatesInNode;
//-(FileCollection*) duplicatesInBranch;
-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;
+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(void)refreshContentsOnQueue: (NSOperationQueue *) queue;


// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

/*
 * Item Manipulation methods
 */

-(BOOL) addChild:(TreeItem*)item;
-(BOOL) removeChild:(TreeItem*)item;
-(BOOL) moveChild:(TreeItem*)item;

/*
 * Tag manipulation
 */
-(void) setTagsInNode:(TreeItemTagEnum)tags;
-(void) setTagsInBranch:(TreeItemTagEnum)tags;
-(void) resetTagsInNode:(TreeItemTagEnum)tags;
-(void) resetTagsInBranch:(TreeItemTagEnum)tags;
//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(TreeItemTagEnum)tags;
//-(void) performSelector:(SEL)selector withObject:(id)param inTreeItemsWithTag:(TreeItemTagEnum)tags;
//-(void) purgeDirtyItems;
@end
