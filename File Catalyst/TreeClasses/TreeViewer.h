//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface TreeViewer : NSObject {

    // This class will enumerate all leafs and branches of the Tree
    NSUInteger _level;
    NSUInteger _currIndex;
    NSInteger *_indexes;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
    TreeBranch *_root;
    TreeItem *_item;
}

-(instancetype) initWithRoot:(TreeBranch*)parent andDepth:(NSUInteger)depth;
-(void) reset;

-(NSUInteger) count;
-(TreeItem*) itemAtIndex:(NSUInteger)index;
-(TreeItem*) forward:(NSInteger) count;
-(TreeItem*) nextObject;

-(NSInteger) isGroup;
-(NSString*) groupTitle;
-(TreeItem*) selectedItem;

-(NSUInteger) groupCount;
-(NSUInteger) itemCountAtSection:(NSUInteger)section;
-(TreeItem*) itemAtIndexPath:(NSIndexPath*)indexPath;

@end
