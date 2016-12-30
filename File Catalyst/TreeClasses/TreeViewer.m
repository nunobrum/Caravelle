//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer.h"


@implementation TreeViewer

-(instancetype) initWithParent:(TreeBranch *)parent depth:(NSUInteger)depth {
    self->_iterators = [NSMutableArray arrayWithCapacity:depth];
    self->_maxLevel = depth;
    self->_root = parent;
    self->_item = nil;
    // Default sortDescriptor
    self->sort = [NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
    self->_currIndex = NSIntegerMax; // This will trigger a reset at the first seek
    self->_needsRefresh = YES;
    return self;
}

#pragma mark - TreeViewerProtocol
-(void) reset {
    self->_currIndex = -1;
    self->_level = 0;
    self->_isGroup = NO;
    self->_curTree = self->_root;
    self->_item = self->_root;
    [self->_iterators removeAllObjects];
    se = [[SortedEnumerator alloc] initWithParent:self->_root sort:self->sort];
}

-(BOOL) needsRefresh {
    return self->_needsRefresh;
}

-(void) setParent:(TreeBranch *)parent {
    if (parent != self->_root) {
        self->_root = parent;
        self->_needsRefresh = YES;
    }
}

-(TreeBranch*) parent {
    return self->_root;
}

-(void) setDepth:(NSInteger)depth {
    if (depth != self->_maxLevel) {
        self->_maxLevel = depth;
        self->_needsRefresh = YES;
    }
}

-(NSInteger) depth {
    return self->_maxLevel;
}

-(void) setSortDescriptor:(NSSortDescriptor *)sortDesc {
    if (sortDesc != self->sort)  {
        self->sort = sortDesc;
        self->_needsRefresh = YES;
    }
}

-(NSSortDescriptor*) sortDescriptor {
    return self->sort;
}

-(void) setFilter:(NSPredicate *)filter {
    if (filter != self->_filter)  {
        self->_filter = filter;
        self->_needsRefresh = YES;
    }
}

-(NSPredicate*) filter {
    return self->_filter;
}

-(NSUInteger) count {
    NSUInteger answer = 0;
    answer = [self->_root numberOItemsInBranchTillDepth: self->_maxLevel];
    return answer;
}

-(TreeItem*) seek:(NSInteger) index {
    NSInteger count = index - _currIndex;
    if (count < 0) {
        // If negative will restart from 0
        [self reset];
        count  = index + 1;
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
                self->_isGroup = YES;
            }
            else
                self->_isGroup = NO;
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


-(BOOL) isGroup:(NSUInteger)index {
    [self seek:index];
    return self->_isGroup;
}

-(NSString*) groupTitle {
    TreeBranch *cBranch ;
    NSInteger level1 = 0;
    NSString *answer = [NSString stringWithFormat:@"%lu",(unsigned long)self->_level];
    while (level1 < _level ) {
        cBranch = self->_iterators[level1].parent;
        answer = [answer stringByAppendingString:[NSString stringWithFormat:@"/%@",cBranch.name]];
        level1++;
    }
    answer = [answer stringByAppendingString:[NSString stringWithFormat:@"/%@",se.parent.name]];
    return answer;
}

//-(NSMutableArray <TreeItem*> *) itemsAtIndexes:(NSIndexSet *)indexes {
//    NSMutableArray <TreeItem*> *answer = [NSMutableArray arrayWithCapacity:indexes.count];
//    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
//        TreeItem *ti = [self seek:idx];
//        [answer addObject:ti];
//    }];
//    return answer;
//}

//-(NSIndexSet*) indexesWithHashes:(NSArray *)hashes {
//    assert(false); //TODO:!!! Implement this
//    /*NSIndexSet *indexes = [self->_displayedItems indexesOfObjectsPassingTest:^(id item, NSUInteger index, BOOL *stop){
//     //NSLog(@"setTableViewSelectedURLs %@ %lu", [item path], index);
//     if ([item isKindOfClass:[TreeItem class]] && [hashes containsObject:[item hashObject]])
//     return YES;
//     else
//     return NO;
//     }];
//     return indexes;*/
//    return nil;
//}

@end
