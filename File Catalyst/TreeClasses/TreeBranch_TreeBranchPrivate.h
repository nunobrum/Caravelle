//
//  TreeBranch_TreeBranchPrivate.h
//  File Catalyst
//
//  Created by Nuno Brum on 30/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"

@interface TreeBranch( PrivateMethods )

-(void) _harvestItemsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter;
-(void) _harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter;

-(void) _performSelectorInUndeveloppedBranches:(SEL)selector; // Used for branch expansion
//-(void) _performSelector:(SEL)selector inItemsWithPredicate:(NSPredicate*)predicte; // Used for tree expansion

-(TreeItem*) _addURLnoRecurr:(NSURL*)theURL;
-(void) refreshTreeFromURLs;
-(void) _setChildren:(NSMutableArray*) children;
-(void) _computeAllocatedSize;

-(void) harverstUndeveloppedFolders:(NSMutableArray*)collector;

-(NSMutableArray*) children;
-(void) initChildren;

-(NSInteger) _releaseReleasedChildren;
-(void) _releaseChildren;

@end


