//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer2.h"

@implementation TreeViewer2


-(instancetype) initWithID:(NSString*)ID viewing:(TreeBranch*)parent depth:(NSUInteger)depth {
    self->_iterators = [NSMutableArray arrayWithCapacity:depth];
    self->_maxLevel = depth;
    self->_root = parent;
    self->_ID = ID;
    self->_item = nil;
    // Default sortDescriptor
    self->sort = [NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
    [self reset];
    
    return self;
}

-(void) reset {
    self->_currIndex = -1;
    self->_level = 0;
    self->_curTree = self->_root;
    self->_item = self->_root;
    [self->_iterators removeAllObjects];
    se = [[SortedEnumerator alloc] initWithParent:_root sort:sort];
}

-(void) setSortDescriptor:(NSSortDescriptor *)sortDesc {
    self->sort = sortDesc;
}

-(NSUInteger) count {
    NSUInteger answer = 0;
    answer = [self->_root numberOItemsInBranchTillDepth: self->_maxLevel];
    return answer;
}

-(TreeItem*) selectedItem {
    return self->_item;
}

-(TreeItem*) seek:(NSInteger) index {
    NSInteger count = index - _currIndex;
    if (count < 0) {
        // If negative will restart from 0
        count = _currIndex + count;
        [self reset];
        count  = 1;
    }
    //else
    //    se = _iterators[_level];
    
    while (count) {
        _item = [se nextObject];
        if (_item) {
            if ([_item hasChildren] && (_level+1 < _maxLevel)) {
                // Will trace that branch, but first store the current one
                [_iterators setObject:se atIndexedSubscript:_level];
                _level++;
                se = [[SortedEnumerator alloc] initWithParent:(TreeBranch*)_item sort:sort];
            }
            count--;
            _currIndex++;
        }
        else {
            // It will go up the hierarchy
            if (_level > 0) {
                _level--;
                se = _iterators[_level];
            }
            else // If it can't it stops the iteration
                return nil;
        }
    }
    return _item;
}

-(TreeItem*) nextObject {
    return [self seek:_currIndex+1];
}

-(TreeItem*) itemAtIndex:(NSUInteger)index {
    return [self seek:index];
}

-(BOOL) isGroup {
    return ((_level+1) < _maxLevel);
}

-(NSString*) groupTitle {
    TreeBranch *cBranch ;
    NSInteger level1 = 0;
    NSString *answer = [NSString stringWithFormat:@"%lu",(unsigned long)self->_level];
    while (level1 < _level ) {
        cBranch = self->_iterators[level1].parent;
        answer = [answer stringByAppendingString:[NSString stringWithFormat:@"|%@",cBranch.name]];
        level1++;
    }
    return answer;
}

@end

