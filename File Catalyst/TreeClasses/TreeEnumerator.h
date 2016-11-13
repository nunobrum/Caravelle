//
//  TreeViewer.h
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreeBranch.h"

@interface NodeEnumerator : NSEnumerator {
    NSUInteger _index;
    TreeBranch *_parent;
}
-(instancetype) initWithParent:(TreeBranch*)parent andDepth:(NSUInteger)depth;

@end

@interface BranchEnumerator : NodeEnumerator {
    NSUInteger _level;
    NSInteger *_indexes;
    NSUInteger _maxLevel;
    TreeBranch *_curTree;
}

@end




