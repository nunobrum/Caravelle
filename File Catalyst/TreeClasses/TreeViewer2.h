//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"
#import "TreeEnumerator.h"

@interface TreeViewer2 : NSObject {
    // This class will enumerate all leafs and branches of the Tree
    NSInteger _level;
    NSInteger _currIndex;
    NSInteger _sectionIndex;
    NSMutableArray <SortedEnumerator*> *_iterators;
    SortedEnumerator *se;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
    TreeBranch *_root;
    TreeItem *_item;
    NSSortDescriptor *sort;
}
@property (readonly) NSString *ID;

-(instancetype) initWithID:(NSString*)ID viewing:(TreeBranch*)parent depth:(NSUInteger)depth;
-(void) reset;
-(void) setSortDescriptor:(NSSortDescriptor*) sortDesc;

-(NSUInteger) count;
-(TreeItem*) itemAtIndex:(NSUInteger)index;
-(TreeItem*) nextObject;

-(BOOL) isGroup;
-(NSString*) groupTitle;
-(TreeItem*) selectedItem;

//
-(NSUInteger) sectionCount;
-(NSUInteger) itemCountAtSection:(NSUInteger)section;
-(TreeItem*) itemAtIndexPath:(NSIndexPath*)indexPath;
@end




