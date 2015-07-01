//
//  TreeBranch.h
//  FileCatalyst1
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "TreeLeaf.h"
//#import "FileCollection.h"

extern NSString *const kvoTreeBranchPropertyChildren;
extern NSString *const kvoTreeBranchPropertySize;
//extern NSString *const kvoTreeBranchReleased;

extern NSString* commonPathFromItems(NSArray* itemArray);
extern NSArray* treesContaining(NSArray* treeItems);

@interface TreeBranch : TreeItem <TreeProtocol> {

@protected
    NSMutableArray *_children;
    long long allocated_size;
}

-(TreeBranch*) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;
-(TreeBranch*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;


-(NSInteger) numberOfLeafsInNode;
-(NSInteger) numberOfBranchesInNode;
-(NSInteger) numberOfItemsInNode;

-(NSInteger) numberOfLeafsInBranch;

//-(NSInteger) numberOfFileDuplicatesInBranch;

-(TreeBranch*) branchAtIndex:(NSUInteger)index;
-(TreeLeaf*) leafAtIndex:(NSUInteger)index;
-(NSInteger) indexOfChild:(TreeItem*)item;

-(long long) sizeOfNode;
-(long long) filesize;

//-(FileCollection*) filesInNode;
//-(FileCollection*) filesInBranch;
-(NSMutableArray*) itemsInNode;
-(NSMutableArray*) itemsInBranchTillDepth:(NSInteger)depth;
-(NSMutableArray*) leafsInNode;
-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth;
-(NSMutableArray*) branchesInNode;

-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate*)filter;
-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate*)filter;
-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;
-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;

-(BOOL) isExpandable;

-(TreeItem*) childWithName:(NSString*) name class:(id)cls;
-(TreeItem*) childWithURL:(NSURL*)url;
-(TreeItem*) childContainingURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithPath:(NSString*)path;
-(TreeItem*) addURL:(NSURL*)theURL;


//-(NSMutableArray*) branchesInBranch;

//-(FileCollection*) duplicatesInNode;
//-(FileCollection*) duplicatesInBranch;
-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;
+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(BOOL) needsRefresh;
-(void) refreshContents;
-(void) forceRefreshOnBranch;
-(void) calculateSize;
-(void) expandAllBranches;

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
