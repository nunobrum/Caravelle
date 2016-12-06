//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer.h"

//#define USE_STORE YES

#ifdef USE_STORE
#define ITEM_COUNT    @"ItemCount"
#define SECTION_COUNT @"SectionCount"
#define ITEM_INDEX    @"ItemIndex"
#define SECTION_INDEX @"SectionIndex"
#endif

@implementation TreeViewer


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
    self->_isGroup = NO;
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
                // Will register it's section and index number
#ifdef USE_STORE
                NSString *storeKey = [self.ID stringByAppendingString:ITEM_INDEX];
                [_item store:[NSNumber numberWithUnsignedInteger:_currIndex] withKey:storeKey];
                storeKey = [self.ID stringByAppendingString:SECTION_INDEX];
                [_item store:[NSNumber numberWithUnsignedInteger:_sectionIndex] withKey:storeKey];
#endif
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

-(NSUInteger) sectionCount {
    NSUInteger answer;
    NSPredicate *onlySections = [NSPredicate predicateWithFormat:@"self.hasChildren"];
    answer = [self->_root numberOItemsWithPredicate:onlySections tillDepth:self->_maxLevel];
    return answer;
}

-(TreeBranch*) sectionNumber:(NSUInteger) section {
    if(section == 0)
        return self->_root;

#ifdef USE_STORE
    NSString *sectionIndexKey = [self.ID stringByAppendingString:SECTION_INDEX];
    NSString *sectionCountKey = [self.ID stringByAppendingString:SECTION_COUNT];
    while (tb = [fe nextObject]) {
        NSUInteger tbSection = [[tb objectWithKey:sectionIndexKey] unsignedIntegerValue];
        if (tbSection >= section) {
            NSUInteger tbSectionCount = [[tb objectWithKey:sectionCountKey] unsignedIntegerValue];
            if (section < (tbSection+tbSectionCount)) {
                if (tbSectionCount == 1) { //  condition assures there are no further iterations to make
                    return tb;
                }
                fe = [[FilterEnumerator alloc] initWithParent:tb];
            }
        }
        if ([tb.hasChildren])
    }
#else
    FilterEnumerator *fe = [[FilterEnumerator alloc] initWithParent:self->_root];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self.hasChildren"];
    [fe setFilter:filter];
    TreeBranch *tb;
    NSInteger level = 0;
    NSUInteger count = 0;
    NSMutableArray *iterators = [NSMutableArray arrayWithCapacity:self->_maxLevel];
    
    while (count < section) {
        tb = [fe nextObject];
        if (tb) {
            if (level+1 < _maxLevel) {
                // Will register it's section and index number
                [iterators setObject:fe atIndexedSubscript:level];
                // Will trace that branch
                level++;
                fe = [[SortedEnumerator alloc] initWithParent:(TreeBranch*)_item sort:sort];
            }
            count++;
        }
        else {
            // It will go up the hierarchy
            if (_level > 0) {
                _level--;
                fe = iterators[level];
            }
            else // If it can't it stops the iteration
                return nil;
        }
    }
#endif
    return tb;
}

-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath {
    TreeBranch *sec = [self sectionNumber: indexPath.section];
    return [sec itemAtIndex:indexPath.item];
}

-(BOOL) isGroup {
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


-(NSUInteger) itemCountAtSection:(NSUInteger)section {
    return [[self sectionNumber:section] numberOfItemsInNode];
}

@end
