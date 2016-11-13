//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer.h"

@implementation TreeViewer


-(instancetype) initWithRoot:(TreeBranch*)parent andDepth:(NSUInteger)depth {
    self->_indexes = malloc(depth*sizeof(NSUInteger));
    self->_maxLevel = depth;
    self->_root = parent;
    [self reset];
    return self;
}

-(void) deinit {
    free(self->_indexes);
}

-(void) reset {
    self->_level = 0;
    self->_curTree = self->_root;
    self->_item = self->_root;
    for (int i =0 ; i < self->_maxLevel ; i++)
        self->_indexes[i] = 0; // Resets the pointers.
}

-(NSUInteger) count {
    //return [_root numberOItemsInBranchTillDepth:_maxLevel];
    NSUInteger level=0;
    NSUInteger * idxs = malloc(_maxLevel*sizeof(NSUInteger));
    TreeBranch *curBranch  = self->_root;
    TreeItem *item;
    NSUInteger answer=0;
    
    for (int i =0 ; i < _maxLevel ; i++)
        idxs[i] = 0; // Resets the pointers.
    
    
    while (1) {
        if (idxs[level] < curBranch.numberOfItemsInNode) {
            item = [curBranch itemAtIndex:idxs[level]];
            if ([item hasChildren] && (level+1 < _maxLevel)) {
                // Will trace that branch
                level++;
                idxs[level] = 0; // Reset the pointer
                curBranch = (TreeBranch*)item;
            }
            else
                idxs[level] = idxs[level] + 1;
            answer++;
        }
        else {
            // It will go up the hierarchy
            if (level > 0) {
                idxs[level] = 0;
                level--;
                idxs[level] = idxs[level] + 1;
                curBranch = curBranch.parent;
                if (curBranch == nil)  {// If no link to parent, will have to navigate to it from root.
                    TreeItem *cursor = self->_root;
                    NSInteger level1 = 0;
                    while (level1 <= level && [cursor hasChildren]) {
                        curBranch = (TreeBranch*)cursor;
                        cursor = [curBranch itemAtIndex:_indexes[level1++]];
                    }
                }
            }
            else // If it can't it stops the iteration
                break;
        }
    }
    free(idxs); // Liberate allocated memory
    return answer;
}

-(TreeItem*) selectedItem {
    return self->_item;
}

-(TreeItem*) forward:(NSInteger) count {
    if (count < 0) {
        // If negative will restart from 0
        count = _currIndex + count;
        _level = 0;
        for (int i =0 ; i < _maxLevel ; i++)
            self->_indexes[i] = 0; // Resets the pointers.
        _curTree = self->_root;
        _currIndex = 0;
    }
    
    while (1) {
        if (_indexes[_level] < _curTree.numberOfItemsInNode) {
            _item = [_curTree itemAtIndex:_indexes[_level]];
            if (count == 0) break;
            if ([_item hasChildren] && (_level+1 < _maxLevel)) {
                // Will trace that branch
                _level++;
                _indexes[_level] = 0; // Reset the pointer
                _curTree = (TreeBranch*) _item;
            }
            else
                _indexes[_level] = _indexes[_level] + 1;
            
            count--;
            _currIndex++;
        }
        else {
            // It will go up the hierarchy
            if (_level > 0) {
                _indexes[_level] = 0;
                _level--;
                _indexes[_level] = _indexes[_level] + 1;
                _curTree = _curTree.parent;
                if (_curTree == nil) {// If no link to parent, will have to navigate to it from root.
                    TreeItem *cursor = self->_root;
                    NSInteger level1 = 0;
                    while (level1 <= _level && [cursor hasChildren]) {
                        _curTree = (TreeBranch*)cursor;
                        cursor = [_curTree itemAtIndex:_indexes[level1++]];
                    }
                }
            }
            else // If it can't it stops the iteration
                return nil;
        }
    }
    return _item;
}

-(TreeItem*) nextObject {
    if (_currIndex==0)
        return [self forward:0];
    else
        return [self forward:1];
}

-(TreeItem*) itemAtIndex:(NSUInteger)index {
    return [self forward:index - _currIndex];
}

-(TreeBranch*) sectionNumber:(NSUInteger) section {
    //return [_root numberOItemsInBranchTillDepth:_maxLevel];
    NSUInteger level=0;
    NSUInteger * idxs = malloc(_maxLevel*sizeof(NSUInteger));
    TreeBranch *curBranch  = self->_root;
    TreeItem *item;
    
    for (int i =0 ; i < _maxLevel ; i++)
        idxs[i] = 0; // Resets the pointers.
    
    
    while (section) {
        if (idxs[level] < curBranch.numberOfItemsInNode) {
            item = [curBranch itemAtIndex:idxs[level]];
            if ([item hasChildren] && (level+1 < _maxLevel)) {
                // Will trace that branch
                level++;
                idxs[level] = 0; // Reset the pointer
                curBranch = (TreeBranch*)item;
                section--;
            }
            else
                idxs[level] = idxs[level] + 1;
        }
        else {
            // It will go up the hierarchy
            if (level > 0) {
                idxs[level] = 0;
                level--;
                idxs[level] = idxs[level] + 1;
                curBranch = curBranch.parent;
                if (curBranch == nil)  {// If no link to parent, will have to navigate to it from root.
                    TreeItem *cursor = self->_root;
                    NSInteger level1 = 0;
                    while (level1 <= level && [cursor hasChildren]) {
                        curBranch = (TreeBranch*)cursor;
                        cursor = [curBranch itemAtIndex:_indexes[level1++]];
                    }
                }
            }
            else // If it can't it stops the iteration
                break;
        }
    }
    free(idxs); // Liberate allocated memory
    return curBranch;
}

-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath {
    TreeBranch *sec = [self sectionNumber: indexPath.section];
    return [sec itemAtIndex:indexPath.item];
}

-(NSInteger) isGroup {
    return ((_level+1) < _maxLevel) && [self->_item hasChildren];
}

-(NSString*) groupTitle {
    //TreeItem *item = [_curTree itemAtIndex:_indexes[_level]];
    TreeItem *cursor = [self->_root itemAtIndex:_indexes[0]];
    TreeBranch *cBranch ;
    NSInteger level1 = 1;
    NSString *answer = [NSString stringWithFormat:@"%@|%@",self->_root.location, cursor.name];
    while (level1 <= _level && [cursor hasChildren]) {
        cBranch = (TreeBranch*)cursor;
        cursor = [cBranch itemAtIndex:_indexes[level1++]];
        answer = [answer stringByAppendingString:[NSString stringWithFormat:@"|%@",cBranch.name]];
        
    }
    return answer;
}

-(NSUInteger) groupCount {
    //return [_root numberOItemsInBranchTillDepth:_maxLevel];
    NSUInteger level=0;
    NSUInteger * idxs = malloc(_maxLevel*sizeof(NSUInteger));
    TreeBranch *curBranch  = self->_root;
    TreeItem *item;
    NSUInteger answer=0;
    
    for (int i =0 ; i < _maxLevel ; i++)
        idxs[i] = 0; // Resets the pointers.
    
    
    while (1) {
        if (idxs[level] < curBranch.numberOfItemsInNode) {
            item = [curBranch itemAtIndex:idxs[level]];
            if ([item hasChildren] && (level+1 < _maxLevel)) {
                // Will trace that branch
                level++;
                idxs[level] = 0; // Reset the pointer
                curBranch = (TreeBranch*)item;
                answer++;
            }
            else
                idxs[level] = idxs[level] + 1;
        }
        else {
            // It will go up the hierarchy
            if (level > 0) {
                idxs[level] = 0;
                level--;
                idxs[level] = idxs[level] + 1;
                curBranch = curBranch.parent;
                if (curBranch == nil)  {// If no link to parent, will have to navigate to it from root.
                    TreeItem *cursor = self->_root;
                    NSInteger level1 = 0;
                    while (level1 <= level && [cursor hasChildren]) {
                        curBranch = (TreeBranch*)cursor;
                        cursor = [curBranch itemAtIndex:_indexes[level1++]];
                    }
                }
            }
            else // If it can't it stops the iteration
                break;
        }
    }
    free(idxs); // Liberate allocated memory
    return answer;
}

-(NSUInteger) itemCountAtSection:(NSUInteger)section {
    return [[self sectionNumber:section] numberOfItemsInNode];
}



@end
