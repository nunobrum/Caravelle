//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface TreeViewer2 : NSObject {
    // This class will enumerate all leafs of the Tree
    NSUInteger _level;
    NSUInteger _currIndex;
    NSInteger *_indexes;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
    TreeBranch *_root;
}

-(instancetype) initWithRoot:(TreeBranch*)parent andDepth:(NSUInteger)depth;
-(NSUInteger) count;
-(TreeItem*) itemAtIndex:(NSUInteger)index;
-(TreeItem*) forward:(NSInteger) count;


@end




