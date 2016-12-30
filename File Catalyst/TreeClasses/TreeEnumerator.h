//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface FilterEnumerator : NSEnumerator  {
    NSUInteger _index;
    TreeBranch *_parent;
    NSPredicate *_filter;
}
@property (readonly) TreeBranch* parent;

-(instancetype) initWithParent:(TreeBranch*)parent;
-(instancetype) initWithParent:(TreeBranch*)parent filter:(NSPredicate*)filter;

-(void) setFilter:(NSPredicate*) filter;
-(NSInteger) count;
-(void) reset;

@end

@interface SortedEnumerator : FilterEnumerator {
    NSSortDescriptor *_sort;
    TreeItem *_item;
    TreeItem *_nextItem;
    NSInteger _itemIndex, _nextItemIndex, _multiplicity;
}
-(instancetype) initWithParent:(TreeBranch*)parent sort:(NSSortDescriptor*) sort;
-(instancetype) initWithParent:(TreeBranch*)parent sort:(NSSortDescriptor *)sort filter:(NSPredicate*)filter;

-(void) setSort:(NSSortDescriptor*) sort;

@end

@interface BranchEnumerator : NSObject {
    NSUInteger _level;
    NSInteger *_indexes;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
    TreeBranch *_parent;
}
-(instancetype) initWithParent:(TreeBranch*)parent andDepth:(NSUInteger)depth;
-(id) nextObject;

@end

//
//// This will make the enumeration without returning branches, only leafs.
//@interface BranchEnumerator2 : NSObject {
//    NSUInteger _level;
//    NSInteger *_indexes;
//    NSUInteger _maxLevel;
//    TreeBranch *_curTree;
//    TreeBranch *_parent;
//}
//
//-(instancetype) initWithParent:(TreeBranch*)parent andDepth:(NSUInteger)depth;
//-(id) nextObject;
//@end



