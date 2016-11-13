//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeEnumerator.h"


@implementation NodeEnumerator

-(instancetype) initWithParent:(TreeBranch*)parent {
    self->_index = 0;
    self->_parent = parent;
    return self;
}

-(id) nextObject {
    if (_index < [self->_parent numberOfItemsInNode]) {
        return [self->_parent itemAtIndex:_index++];
    }
    return nil;
}

@end


@implementation BranchEnumerator

-(instancetype) initWithParent:(TreeBranch*)parent andDepth:(NSUInteger)depth {
    self = [super initWithParent:parent];
    _level = 0;
    _maxLevel = depth;
    // allocates and initializes memory for counters
    _indexes = malloc(level*sizeof(NSUInteger));
    for (NSUInteger i=0; i < depth; i++)
        _indexes[i] = 0;
    _curTree = parent;
    return self;
}

-(void) deinit {
    if (_indexes != nil) free(_indexes);
}

-(id) nextObject {
    TreeItem *answer = nil;
    while (1) {
        if (_indexes[_level] < _curTree.numberOfItemsInNode) {
            answer = [_curTree itemAtIndex:_indexes[_level]];
            if ([answer hasChildren]) {
                if (_level+1 < _maxLevel) { // Will trace that branch
                    _level++;
                    _indexes[_level] = 0; // Reset the pointer
                }
                else { // Moves to the next
                    _indexes[_level] = _indexes[_level] + 1;
                    break; // Return the branch if it is the limot
                }
            }
            else {
                _indexes[_level] = _indexes[_level] + 1;
                break; // Returns it
            }
        }
        else {
            // It will go up the hierarchy
            if (_level > 0) {
                _level--;
                _curTree = _parent; // Starts from root
                for (int i=0; i < _level; i++) {
                    _curTree = [_curTree itemAtIndex:_indexes[i]];
                    if ([_curTree hasChildren]==NO)
                        break; // Need to stop if it isn't a tree. This isn't supposed to happen
                }
                _indexes[_level] = _indexes[_level] + 1;
            }
            else // If it can't it stops the iteration
                return nil;
        }
    }
    return answer;
}

@end
 

