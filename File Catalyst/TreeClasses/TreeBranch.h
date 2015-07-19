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
    long long size_files;
    long long size_allocated;
    long long size_total;
    long long size_total_allocated;
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

// Duplicate Support
-(NSInteger)       numberOfDuplicatesInNode;
-(NSInteger)       numberOfDuplicatesInBranch;
-(NSInteger)       numberOfBranchesWithDuplicatesInNode;
-(long long)       duplicateSize;
-(TreeLeaf*)       duplicateAtIndex:(NSUInteger) index;
-(TreeBranch*)     duplicateBranchAtIndex:(NSUInteger) index;
-(NSMutableArray*) duplicatesInBranchTillDepth:(NSInteger)depth;
-(NSMutableArray*) duplicatesInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;
-(void)            prepareForDuplicates;

-(BOOL) isExpandable;

-(TreeItem*) childWithName:(NSString*) name class:(id)cls;
-(TreeItem*) childWithURL:(NSURL*)url;
-(TreeItem*) childContainingURL:(NSURL*)url;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithPath:(NSString*)path;
-(TreeItem*) addURL:(NSURL*)theURL;
-(BOOL)      addTreeItem:(TreeItem*) item;


-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;
+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(BOOL) needsRefresh;
-(void) refreshContents;
-(void) forceRefreshOnBranch;
-(void) calculateSize;
-(void) expandAllBranches;
-(void) setSizes:(long long)files allocated:(long long)allocated total:(long long)total totalAllocated:(long long) totalallocated;
-(void) sizeCalculationCancelled;


-(void) notifyDidChangeTreeBranchPropertyChildren;

// Private Method
//-(void) _harvestItemsInBranch:(NSMutableArray*)collector;

/*
 * Item Manipulation methods
 */

-(BOOL) addChild:(TreeItem*)item;
-(BOOL) removeChild:(TreeItem*)item;
//-(BOOL) moveChild:(TreeItem*)item;

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
