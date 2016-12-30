//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"
#import "DataSourceProtocol.h"
#import "TreeEnumerator.h"

@interface TreeViewer : NSObject <TreeViewerProtocol> {

    // This class will enumerate all leafs and branches of the Tree
    NSInteger _level;
    NSInteger _currIndex;
    NSMutableArray <SortedEnumerator*> *_iterators;
    SortedEnumerator *se;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
    TreeBranch *_root;
    TreeItem *_item;
    BOOL _isGroup;
    BOOL _needsRefresh;
    NSSortDescriptor *sort;
    NSPredicate *_filter;
}

-(instancetype) initWithParent:(TreeBranch*)parent depth:(NSUInteger)depth;

-(NSUInteger) count;
-(TreeItem*) itemAtIndex:(NSUInteger)index;
//-(NSMutableArray <TreeItem*> *) itemsAtIndexes:(NSIndexSet*) indexes;

//-(NSInteger) indexOfItem:(TreeItem*) item;
//-(NSIndexSet*) indexesWithHashes:(NSArray *)hashes;

-(TreeItem*) nextObject;

-(BOOL) isGroup:(NSUInteger)index;
-(NSString*) groupTitle;

@end
