//
//  TreeViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 13.11.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeEnumerator.h"


@implementation FilterEnumerator
@synthesize parent = _parent;

-(instancetype) initWithParent:(TreeBranch*)parent {
    self->_index = 0;
    self->_parent = parent;
    self->_filter = nil;
    return self;
}

-(id) nextObject {
    if (_index < [self->_parent numberOfItemsInNode]) {
        if (self->_filter) {
            while (NO == [self->_filter evaluateWithObject:[self->_parent itemAtIndex:_index]]) {
                _index++;
            }
        }
        return [self->_parent itemAtIndex:_index++];
    }
    return nil;
}

-(void) setFilter:(NSPredicate*)filter {
    self->_filter = filter;
}

-(NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    // plan of action: extra[0] will contain pointer to node
    // that contains next object to iterate
    // because extra[0] is a long, this involves ugly casting
    if(state->state == 0)
    {
        // state 0 means it's the first call, so get things set up
        // we won't try to detect mutations, so make mutationsPtr
        // point somewhere that's guaranteed not to change
        state->mutationsPtr = 0;
        
        // set up extra[0] to point to the head to start in the right place
        state->extra[0] = 0;
        
        // and update state to indicate that enumeration has started
        state->state = 1;
    }
    
    
    // keep track of how many objects we iterated over so we can return
    // that value
    NSUInteger objCount = 0;
    NSUInteger index = state->extra[0];
    
    // we'll be putting objects in stackbuf, so point itemsPtr to it
    state->itemsPtr = buffer;
    
    // if it's NULL then we're done enumerating, return 0 to end
    while (index < self->_parent.children.count && objCount < len) {
        TreeItem *obj = self->_parent.children[index++];
        if (self->_filter && [self->_filter evaluateWithObject:obj]) {
            *(buffer++) = obj;
            objCount++;
        }
    }
    // update extra[0]
    state->extra[0] = index;
    // we're returning exactly one item
    return objCount;
}

-(NSInteger) count {
    if (self->_parent == nil || self->_parent.children == nil)
        return 0;
    if (self->_filter) {
        NSInteger __block count = 0;
        [self->_parent.children enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self->_filter evaluateWithObject:obj])
                count++;
        }];
        return count;
    }
    else {
        return [self->_parent.children count];
    }
}

@end

@implementation SortedEnumerator

-(instancetype) initWithParent:(TreeBranch*)parent sort:(NSSortDescriptor*) sort {
    self = [super initWithParent:parent];
    self->_sort = sort;
    return self;
}

-(TreeItem*) nextObject {
    if (self->_multiplicity > 0) {
        // Start get all the multiples of till multiplicity is 0
        for (NSUInteger x= self->_itemIndex + 1 ; x < self->_parent.children.count; x++) {
            TreeItem *ref = [self->_parent itemAtIndex:x];
            NSComparisonResult test = [self->_sort compareObject:self->_item toObject:ref];
            if (test == NSOrderedSame) {
                // Stopping here
                self->_multiplicity--;
                self->_itemIndex = x;
                self->_item = ref;
                break;
            }
        }
    }
    else {
        NSUInteger x=0;
        if (self->_item == nil) {
            self->_item = self->_parent.children[0];
            self->_multiplicity = -1; // This trick avoids a more complicated checking.
                                      // We know that the first object will be set match the first object
                                      // on the iteration below, so we start with -1.
            self->_itemIndex = 0;
            self->_nextItem = nil; //Always initialize it to nil
            for (TreeItem* ref in self->_parent) {
                NSComparisonResult test = [self->_sort compareObject:self->_item toObject:ref];
                // NSNumericSearch makes the proper order 8,9,10,11 instead if 10,11,8,9
                if (test==NSOrderedDescending) {
                    self->_nextItem = self->_item;
                    self->_item = ref;
                    self->_nextItemIndex = self->_itemIndex;
                    self->_itemIndex = x;
                    self->_multiplicity = 0;
                }
                else if (test == NSOrderedSame) {
                    self->_multiplicity ++;
                }
                else {
                    if (self->_nextItem == nil) {
                        self->_nextItem = ref;
                        self->_nextItemIndex = x;
                    }
                    else {
                        NSComparisonResult test = [self->_sort compareObject:self->_item toObject:ref];
                        if (test == NSOrderedDescending) {
                            self->_nextItem = ref;
                            self->_nextItemIndex = x;
                        }
                    }
                }
                x++;
            }
        }
        else {
            self->_item = self->_nextItem; // If it was nill before it will just stop the cycle.
            self->_multiplicity = -1; // Will discount the match with itself.
            self->_itemIndex = self->_nextItemIndex;
            self->_nextItem = nil; //Always initialize it to nil
            if (self->_item != nil) { // Bypass the loop and returning nil will stop the loop.
                for (TreeItem* ref in self->_parent) {
                    NSComparisonResult test = [self->_sort compareObject:self->_item toObject:ref];
                    // NSNumericSearch makes the proper order 8,9,10,11 instead if 10,11,8,9
                    if (test == NSOrderedSame) {
                        self->_multiplicity ++;
                    }
                    else if (test == NSOrderedAscending) {
                        if (self->_nextItem == nil) {
                            self->_nextItem = ref;
                            self->_nextItemIndex = x;
                        }
                        else {
                            NSComparisonResult test = [self->_sort compareObject:self->_item toObject:ref];
                            if (test == NSOrderedDescending) {
                                self->_nextItem = ref;
                                self->_nextItemIndex = x;
                            }
                        }
                    }
                    x++;
                }
            }
        }
        
    }
    return self->_item;
}

-(void) setFilter:(NSPredicate*)filter {
    self->_filter = filter;
}

-(void) setSort:(NSSortDescriptor *)sort {
    self->_sort = sort;
}

@end




@implementation BranchEnumerator

-(instancetype) initWithParent:(TreeBranch*)parent andDepth:(NSUInteger)depth {
    self->_parent = parent;
    _level = 0;
    _maxLevel = depth;
    // allocates and initializes memory for counters
    _indexes = malloc(depth * sizeof(NSUInteger));
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
 

