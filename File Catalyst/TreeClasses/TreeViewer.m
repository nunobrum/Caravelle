//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer.h"

@implementation TreeViewer


-(instancetype) initWithID:(NSString*)ID viewing:(TreeBranch*)parent depth:(NSUInteger)depth {
    self->_iterators = [NSMutableArray arrayWithCapacity:depth];
    self->_maxLevel = depth;
    self->_root = parent;
    self->_ID = ID;
    self->_item = nil;
    // Default sortDescriptor
    self->sort = [NSSortDescriptor sortDescriptorWithKey:@"hasChildren" ascending:NO];
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
    [_iterators addObject:se];
}

-(void) setSortDescriptor:(NSSortDescriptor *)sortDesc {
    self->sort = sortDesc;
}

-(NSUInteger) count {
    NSString *itemCountStoreKey = [self.ID stringByAppendingString:@"ItemCount"];
    NSString *sectionCountStoreKey = [self.ID stringByAppendingString:@"SectionCount"];
    TreeBranch *curBranch  = self->_root;
    
    // First test if count was already done
    NSNumber *itemCount = [curBranch objectWithKey:itemCountStoreKey];
    if (itemCount != nil) {
        return itemCount.unsignedIntegerValue;
    }
    else {
        //return [_root numberOItemsInBranchTillDepth:_maxLevel];
        NSUInteger level=0;
        NSUInteger * idxs = malloc(_maxLevel*sizeof(NSUInteger));
        NSUInteger *itemCounters = malloc(_maxLevel*sizeof(NSUInteger));
        NSUInteger *sectionCounters = malloc(_maxLevel*sizeof(NSUInteger));
        
        NSUInteger curIndex=0;
        TreeItem *item;
        NSUInteger auxCounter   = 0;
        for (int i =0 ; i < _maxLevel ; i++) {
            idxs[i] = 0; // Resets the pointers.
            //        counters[i].leafCounter = 0;
            //        counters[i].branchCounter = 0;
        }
        
        
        while (1) {
            if (curIndex < curBranch.numberOfItemsInNode) {
                item = [curBranch itemAtIndex:curIndex];
                auxCounter++;
                if ([item hasChildren] && (level+1 < _maxLevel)) {
                    // Will trace that branch
                    idxs[level] = curIndex; // Reset the pointer
                    itemCounters[level] = auxCounter;
                    sectionCounters[level]++;
                    curIndex = 0;
                    auxCounter = 0;
                    level++;
                    idxs[level] = 0;
                    curBranch = (TreeBranch*)item;
                }
                else {
                    curIndex++;
                }
            }
            else {
                // It will go up the hierarchy
                if (level > 0) {
                    itemCounters[level] = auxCounter;
                    [curBranch store:[NSNumber numberWithUnsignedInteger:auxCounter] withKey:itemCountStoreKey];
                    [curBranch store:[NSNumber numberWithUnsignedInteger:sectionCounters[level]] withKey:sectionCountStoreKey];
                    level--;
                    curIndex = idxs[level] + 1;
                    auxCounter = itemCounters[level] + auxCounter;
                    sectionCounters[level] += sectionCounters[level+1];
                    curBranch = curBranch.parent;
                    if (curBranch == nil)  {// If no link to parent, will have to navigate to it from root.
                        TreeItem *cursor = self->_root;
                        NSInteger level1 = 0;
                        while (level1 <= level && [cursor hasChildren]) {
                            curBranch = (TreeBranch*)cursor;
                            cursor = [curBranch itemAtIndex:idxs[level1++]];
                        }
                    }
                }
                else // If it can't it stops the iteration
                    break;
            }
        }
        free(idxs); // Liberate allocated memory
        auxCounter += itemCounters[0];
        free(itemCounters);
        free(sectionCounters);
        return auxCounter;
    }
}

-(TreeItem*) selectedItem {
    return self->_item;
}



-(TreeItem*) forward:(NSInteger) index {
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
        NSLog(@"forward:nO %@",_item);
        if (_item) {
            if ([_item hasChildren] && (_level+1 < _maxLevel)) {
                // Will register it's section and index number
                NSString *storeKey = [self.ID stringByAppendingString:@"ItemIndex"];
                [_item store:[NSNumber numberWithUnsignedInteger:_currIndex] withKey:storeKey];
                storeKey = [self.ID stringByAppendingString:@"SectionIndex"];
                [_item store:[NSNumber numberWithUnsignedInteger:_sectionIndex] withKey:storeKey];
                // Will trace that branch
                _level++;
                [_iterators addObject:se];
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
    NSLog(@"forward:ret %@",_item);
    return _item;
}

-(TreeItem*) nextObject {
    return [self forward:_currIndex+1];
}

-(TreeItem*) itemAtIndex:(NSUInteger)index {
    return [self forward:index];
}

-(TreeBranch*) sectionNumber:(NSUInteger) section {
    if(section == 0)
        return self->_root;

    NSString *sectionIndexKey = [self.ID stringByAppendingString:@"SectionIndex"];
    NSString *sectionCountKey = [self.ID stringByAppendingString:@"SectionCount"];
    FilterEnumerator *fe = [[FilterEnumerator alloc] initWithParent:self->_root];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self.hasChildren"];
    [fe setFilter:filter];
    TreeBranch *tb;
    
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
    }
    return tb;
}

-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath {
    TreeBranch *sec = [self sectionNumber: indexPath.section];
    return [sec itemAtIndex:indexPath.item];
}

-(NSInteger) isGroup {
    return ((_level+1) < _maxLevel) && [self->_item hasChildren];
}

-(NSString*) groupTitle {
    TreeBranch *cBranch ;
    NSInteger level1 = 0;
    NSString *answer = [NSString stringWithFormat:@"%lu",(unsigned long)self->_level];
    while (level1 < _level ) {
        cBranch = self->_iterators[0].parent;
        answer = [answer stringByAppendingString:[NSString stringWithFormat:@"|%@",cBranch.name]];
        
    }
    return answer;
}

//-(NSUInteger) groupCount {
//    //return [_root numberOItemsInBranchTillDepth:_maxLevel];
//    NSUInteger level=0;
//    NSUInteger * idxs = malloc(_maxLevel*sizeof(NSUInteger));
//    TreeBranch *curBranch  = self->_root;
//    TreeItem *item;
//    NSUInteger answer=0;
//    
//    for (int i =0 ; i < _maxLevel ; i++)
//        idxs[i] = 0; // Resets the pointers.
//    
//    
//    while (1) {
//        if (idxs[level] < curBranch.numberOfItemsInNode) {
//            item = [curBranch itemAtIndex:idxs[level]];
//            if ([item hasChildren] && (level+1 < _maxLevel)) {
//                // Will trace that branch
//                level++;
//                idxs[level] = 0; // Reset the pointer
//                curBranch = (TreeBranch*)item;
//                answer++;
//            }
//            else
//                idxs[level] = idxs[level] + 1;
//        }
//        else {
//            // It will go up the hierarchy
//            if (level > 0) {
//                idxs[level] = 0;
//                level--;
//                idxs[level] = idxs[level] + 1;
//                curBranch = curBranch.parent;
//                if (curBranch == nil)  {// If no link to parent, will have to navigate to it from root.
//                    TreeItem *cursor = self->_root;
//                    NSInteger level1 = 0;
//                    while (level1 <= level && [cursor hasChildren]) {
//                        curBranch = (TreeBranch*)cursor;
//                        cursor = [curBranch itemAtIndex:_indexes[level1++]];
//                    }
//                }
//            }
//            else // If it can't it stops the iteration
//                break;
//        }
//    }
//    free(idxs); // Liberate allocated memory
//    return answer;
//}

-(NSUInteger) itemCountAtSection:(NSUInteger)section {
    return [[self sectionNumber:section] numberOfItemsInNode];
}



@end
