//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer2.h"

@implementation TreeViewer2


-(instancetype) initWithRoot:(TreeBranch*)parent andDepth:(NSUInteger)depth {
    self->_indexes = malloc(depth*sizeof(NSUInteger));
    self->_maxLevel = depth;
    self->_level = 0;
    self->_root = parent;
    self->_curTree = parent;
    for (int i =0 ; i < depth ; i++)
        self->_indexes[i] = 0; // Resets the pointers.
    return self;
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
            while ([item hasChildren] && (level+1 < _maxLevel)) {
                // Will trace that branch
                level++;
                idxs[level] = 0; // Reset the pointer
                curBranch = (TreeBranch*)item;
                item = [curBranch itemAtIndex:idxs[level]];
            }
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
    return answer;
}

-(TreeItem*) currObject {
    TreeItem *cursor = self->_root;
    NSInteger level = 0;
    while ([cursor isFolder]) {
        _curTree = (TreeBranch*) cursor;
        if (level >= _level )
            break;
        cursor = [_curTree itemAtIndex:_indexes[level++]];
    }
    return cursor;
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
    TreeItem *item ;
    
    while (1) {
        if (_indexes[_level] < _curTree.numberOfItemsInNode) {
            item = [_curTree itemAtIndex:_indexes[_level]];
            while ([item hasChildren] && (_level+1 < _maxLevel)) {
                // Will trace that branch
                _level++;
                _indexes[_level] = 0; // Reset the pointer
                _curTree = (TreeBranch*) item;
                item = [_curTree itemAtIndex:_indexes[_level]];
            }
            if (count == 0) break;
            count--;
            _indexes[_level] = _indexes[_level] + 1;
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
                        cursor = [_curTree itemAtIndex:_indexes[level1++]];}
                }
            }
            else // If it can't it stops the iteration
                return nil;
        }
    }
    return item;
}

-(TreeItem*) itemAtIndex:(NSUInteger)index {
    return [self forward:index - _currIndex];
}

@end

