//
//  TreeBranch.h
//  Caravelle
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
//extern NSArray* treesContaining(NSArray* treeItems);


@interface TreeBranch : TreeItem <TreeProtocol, NSFastEnumeration> {

@protected
    NSMutableArray *_children;
    long long size_files;
    long long size_allocated;
    long long size_total;
    long long size_total_allocated;
}

-(instancetype) initWithURL:(NSURL*)url parent:(TreeBranch*)parent;
-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent;


-(NSUInteger) numberOfBranchesInNode;
-(NSUInteger) numberOfItemsInNode;

-(NSUInteger) numberOfLeafsInBranch;
//-(NSUInteger) numberOItemsInBranchTillDepth:(NSUInteger) depth;
-(NSUInteger) numberOfItemsWithPredicate:(NSPredicate*)filter tillDepth:(NSUInteger) depth;
-(NSUInteger) numberOfLeafsWithPredicate:(NSPredicate*)filter tillDepth:(NSUInteger) depth;



-(TreeBranch*) branchAtIndex:(NSUInteger)index;
-(NSInteger) indexOfItem:(TreeItem*)item;
-(TreeItem*) itemAtIndex:(NSUInteger)index;


-(NSMutableArray*) children; // Read only access to the children
-(NSMutableArray*) itemsInNode;
-(NSMutableArray*) branchesInNode;


-(void) harvestItemsInBranch:(NSMutableArray*)collector depth:(NSUInteger)depth filter:(NSPredicate*)filter;

-(void) harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSUInteger)depth filter:(NSPredicate*)filter;


//-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;
-(void) harvestItemsInBranch:(NSMutableArray*)collector
                       depth:(NSUInteger)depth
                   withBlock:(BOOL(^)(TreeItem* item, NSUInteger level))filter;

// Duplicate Support
//-(NSInteger) numberOfFileDuplicatesInBranch;
//-(NSInteger)       numberOfDuplicatesInNode;
//-(NSInteger)       numberOfDuplicatesInBranch;
//-(NSInteger)       numberOfBranchesWithDuplicatesInNode;
//-(long long)       duplicateSize;
//-(TreeLeaf*)       duplicateAtIndex:(NSUInteger) index;
//-(TreeBranch*)     duplicateBranchAtIndex:(NSUInteger) index;
//-(NSMutableArray*) duplicatesInBranchTillDepth:(NSInteger)depth;
//-(NSMutableArray*) duplicatesInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth;
//-(void)            prepareForDuplicates;

-(BOOL) isExpandable;

-(TreeItem*) childWithName:(NSString*) name class:(id)cls;
//-(TreeItem*) childWithURL:(NSURL*)url;
//-(TreeItem*) childContainingURL:(NSURL*)url;
-(TreeItem*) getNodeWithPathComponents:(NSArray*) pComp;
-(TreeItem*) getNodeWithURL:(NSURL*)url;
-(TreeItem*) getNodeWithPath:(NSString*)path;
-(TreeItem*) addURL:(NSURL*)theURL;
-(BOOL)      addTreeItem:(TreeItem*) item;

-(BOOL) replaceItem:(TreeItem*)original with:(TreeItem*)replacement;
-(BOOL) removeItemAtIndex:(NSUInteger)index;


-(instancetype) initFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;
+(instancetype) treeFromEnumerator:(NSEnumerator*) dirEnum URL:(NSURL*)rootURL parent:(TreeBranch*)parent cancelBlock:(BOOL(^)())cancelBlock;

-(void) tagRefreshStart;
-(void) tagRefreshFinished;
-(BOOL) needsRefresh;
-(void) refresh;
-(void) forceRefreshOnBranch;
-(void) calculateSize;
-(void) setSizes:(long long)files allocated:(long long)allocated total:(long long)total totalAllocated:(long long) totalallocated;
-(void) sizeCalculationCancelled;

-(void) requestFlatForView:(id)view tillDepth:(NSInteger)depth ;
-(void) harverstUndeveloppedFolders:(NSMutableArray*)collector tillDepth:(NSInteger) depth;

-(void) notifyDidChangeTreeBranchPropertyChildren;

/*
 * Item Manipulation methods
 */

-(BOOL) addChild:(TreeItem*)item;
-(BOOL) removeChild:(TreeItem*)item;
//-(BOOL) moveChild:(TreeItem*)item;

-(NSInteger) releaseReleasedChildren;
-(void) releaseChildren;

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



