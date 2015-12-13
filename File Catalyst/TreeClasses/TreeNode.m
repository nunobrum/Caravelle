//
//  TreeBranch.m
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

//#include "definitions.h"
#import "BrowserProtocol.h"
#import "TreeNode.h"





@implementation TreeNode



-(void) releaseChildren {
    [self removeAllObjects];
}



#pragma mark -
#pragma mark chidren access

-(TreeNode*) childWithName:(NSString*) name class:(id)cls {
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([[item name] isEqualToString: name] && [item isKindOfClass:cls]) {
                return item;
            }
        }
    }
    return nil;
}


/*
 * BrowserProtocol Implementation
 */

#pragma mark - Browser Protocol

-(NSInteger) itemCount {
    return [self count]; /* This is needed to invalidate and re-scan the node */
}

-(TreeNode*) itemAtIndex:(NSUInteger)index {
    return [self objectAtIndex:index];
}

-(NSMutableArray*) itemsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        [answer addObjectsFromArray:self];
        return answer;
    }
    return NULL;
}

-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate *)filter {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        if (filter==nil)
            [answer addObjectsFromArray:self];
        else
            [answer addObjectsFromArray:[self filteredArrayUsingPredicate:filter]];
        return answer;
    }
    return NULL;
}

-(NSMutableArray*) itemsInBranchTillDepth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestItemsInBranch:answer depth:depth filter:nil];
    return answer;
}

-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestItemsInBranch:answer depth:depth  filter:filter];
    return answer;
}


-(void) _harvestItemsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter {
    @synchronized(self) {
        if (filter!=nil) {
            [collector addObjectsFromArray:[self filteredArrayUsingPredicate:filter]];
        }
        else {
            [collector addObjectsFromArray: self];
        }
        if (depth > 1) {
            for (TreeNode* item in self) {
                if ([item isFolder]) {
                    [item _harvestItemsInBranch: collector depth:depth-1 filter:filter];
                }
            }
        }
    }
}

#pragma mark - Node access


-(NSInteger) nodeCount {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item isFolder]) {
                total++;
            }
        }
    }
    return total;
}


-(NSMutableArray*) nodesInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeNode* item in self) {
            if ([item isFolder]) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}




-(TreeNode*) nodeAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item isFolder]) {
                if (i==index)
                    return item;
                i++;
            }
        }
    }
    return nil;
}

//-(NSIndexSet*) branchIndexes {
//    NSMutableIndexSet *answer = [[NSMutableIndexSet alloc] init];
//    @synchronized(self) {
//        NSUInteger index = 0;
//        for (TreeNode* item in self) {
//            if ([item isFolder]) {
//                [answer addIndex:index];
//            }
//            index++;
//        }
//    }
//    return answer;
//}

/*
 * Leaf Access
 */

#pragma mark - Leaf access



-(NSInteger) leafCount {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item isLeaf]) {
                total++;
            }
        }
    }
    return total;
}

-(TreeNode*) leafAtIndex:(NSUInteger) index {
    NSInteger i=0;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item isLeaf]) {
                if (i==index)
                    return item;
                i++;
            }
        }
    }
    return nil;
}


-(NSMutableArray*) leafsInNode {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeNode* item in self) {
            if ([item isLeaf]) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    NSInteger total=0;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item isFolder]) {
                total += [item numberOfLeafsInBranch];
            }
            else
                total++;
        }
    }
    return total;
}





-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate *)filter {
    @synchronized(self) {
        NSMutableArray *answer = [[NSMutableArray new] init];
        for (TreeNode* item in self) {
            if ([item isLeaf] && (filter==nil || [filter evaluateWithObject:item])) {
                [answer addObject:item];
            }
        }
        return answer;
    }
    return nil;
}

-(void) _harvestLeafsInBranch:(NSMutableArray*)collector depth:(NSInteger)depth filter:(NSPredicate*)filter {
    if (depth ==0) return;
    @synchronized(self) {
        for (TreeNode* item in self) {
            if ([item hasChildren]) {
                [item _harvestLeafsInBranch: collector depth:depth-1 filter:filter];
            }
            else if (filter==nil || [filter evaluateWithObject:item]) {
                [collector addObject:item];
            }
        }
    }
}
-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestLeafsInBranch: answer depth:depth filter:nil];
    return answer;
}

-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    NSMutableArray *answer = [[NSMutableArray new] init];
    [self _harvestLeafsInBranch: answer depth:depth filter:filter];
    return answer;
}




#pragma mark -


-(BrowserItemPointer) parent {
    return nil;
}


-(BOOL) needsRefresh {
    NSAssert(NO, @"This should be overriden");
    return NO;
}

-(void)refresh {
    NSAssert(NO, @"This should be overriden");
}

-(NSString*)name {
    NSAssert(NO, @"This should be overriden");
    return @"Tree Node Class Instance, should be overrided";
}

-(void) setName:(NSString*)newName {
    NSAssert(NO, @"This should be overriden");
}

-(NSImage*)image {
    NSAssert(NO, @"This should be overriden");
    return nil;
}

-(NSString*)hint {
    NSAssert(NO, @"This should be overriden");
    return nil;
}

-(attrViewTagEnum)tag {
    NSAssert(NO, @"This should be overriden");
    return 0;
}

-(void)    setTag:(attrViewTagEnum)tags {
    NSAssert(NO, @"This should be overriden");
}
-(void)  resetTag:(attrViewTagEnum)tags {
    NSAssert(NO, @"This should be overriden");
}
-(BOOL)    hasTag:(attrViewTagEnum)tags {
    NSAssert(NO, @"This should be overriden");
    return NO;
}

-(void) toggleTag:(attrViewTagEnum)tags {
    NSAssert(NO, @"This should be overriden");
}


/* Returns if the node is expandable
 Note that if the _children is not populated it is assumed that the
 node is expandable. It is preferable to assume as yes and later correct. */
-(BOOL) isExpandable {
    NSAssert(NO, @"This should be overriden");
    return [self count]!=0;
}
-(BOOL) needsSizeCalculation {
    NSAssert(NO, @"This should be overriden");
    return NO;
}

-(BOOL) isGroup {
    NSAssert(NO, @"This should be overriden");
    return NO;
}

-(BOOL) isFolder { // has visible folders
    NSAssert(NO, @"This should be overriden");
    return NO;
}

-(BOOL) hasChildren { // has physical children but does not display as folders.
    NSAssert(NO, @"This should be overriden");
    return [self count]!=0;
}

-(BOOL) isLeaf {  // convinient selector which translates to NOT isFolder
    NSAssert(NO, @"This should be overriden");
    return YES;
}

-(NSMutableArray*) children {
    return self;
}

-(id)   hashObject { // Used for maintaining selections
    NSAssert(NO, @"This should be overriden");
    return nil;
}

// Copy and paste support
-(NSDragOperation) supportedDragOperations:(id<NSDraggingInfo>) info {
    NSAssert(NO, @"This should be overriden");
    return NSDragOperationNone;
}

-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject {
    NSAssert(NO, @"This should be overriden");
    return [NSArray array];
}




-(NSInteger) indexOfItem:(TreeNode*)item {
    return [self indexOfObject:item];
}



-(BOOL) removeItemAtIndex:(NSUInteger)index {
    BOOL answer = YES;
    @try {
        [self removeObjectAtIndex:index];
    }
    @catch (NSException *exception) {
        answer = NO;
    }
    return answer;
}

-(BOOL) replaceItem:(TreeNode*)original with:(TreeNode*)replacement {
    NSInteger index = [self indexOfObject:original];
    if (index != NSNotFound) {
        [self setObject:replacement atIndexedSubscript:index];
        return YES;
    }
    return NO;
}






-(NSEnumerator*) itemsInNodeEnumerator {
    return [[ItemEnumerator alloc] initWithParent:self];
}




/*
 * Tag manipulation
 */

//-(void) setTagsInNode:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (TreeNode* item in self->_children) {
//            [item setTag:tags];
//        }
//    }
//}
//-(void) setTagsInBranch:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (TreeNode* item in self->_children) {
//            [item setTag:tags];
//            if ([item isFolder]) {
//                [(TreeBranch*)item setTagsInBranch:tags];
//            }
//        }
//    }
//}
//-(void) resetTagsInNode:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (TreeNode* item in self->_children) {
//            [item resetTag:tags];
//        }
//    }
//}
//-(void) resetTagsInBranch:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (TreeNode* item in self->_children) {
//            [item setTag:tags];
//            if ([item isFolder]) {
//                [(TreeBranch*)item resetTagsInBranch:tags];
//            }
//        }
//    }
//}
//
//// trying to invalidate all existing tree and lauching a refresh on the views
//-(void) forceRefreshOnBranch {
//    if (self->_children!=nil) {
//        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//        @synchronized(self) {
//            [self setTag:attrViewDirty];
//            for (TreeNode* item in self->_children) {
//                if ([item isFolder]) {
//                    [(TreeBranch*)item forceRefreshOnBranch];
//                }
//            }
//        }
//        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
//    }
//}


//-(void) performSelector:(SEL)selector inTreeItemsWithTag:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector];
//            }
//            if ([item isFolder]) {
//                [(TreeBranch*)item performSelector:selector inTreeItemsWithTag:tags];
//            }
//        }
//    }
//}
//-(void) performSelector:(SEL)selector withObject:(id)param inTreeItemsWithTag:(attrViewTagEnum)tags {
//    @synchronized(self) {
//        for (id item in self->_children) {
//            if ([item hasTags:tags] && [item respondsToSelector:selector]) {
//                [item performSelector:selector withObject:param];
//            }
//            if ([item isFolder]) {
//                [(TreeBranch*)item performSelector:selector withObject:param inTreeItemsWithTag:tags];
//            }
//        }
//    }
//}
//
//-(void) purgeDirtyItems {
//    NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
//    NSUInteger index = 0;
//    @synchronized (self) {
//        for (id item in self->_children) {
//            if ([item hasTags:attrViewDirty]) {
//                [indexesToDelete addIndex:index];
//            }
//            else if ([item isFolder]) {
//                [(TreeBranch*)item purgeDirtyItems];
//            }
//            index++;
//        }
//    }
//    if ([indexesToDelete count]>0) {
//        [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
//        // We synchronize access to the image/imageLoading pair of variables
//        @synchronized (self) {
//            [_children removeObjectsAtIndexes:indexesToDelete];
//        }
//        [self notifyDidChangeTreeBranchPropertyChildren];   // This will inform the observer about change
//    }
//}

//-(FileCollection*) duplicatesInNode {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeNode* item in _children) {
//        if ([item isLeaf]) {
//            [answer addFiles: [[(CRVLFile*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}
//
//-(FileCollection*) duplicatesInBranch {
//    FileCollection *answer = [[FileCollection new] init];
//    for (TreeNode* item in _children) {
//        if ([item isFolder]) {
//            [answer concatenateFileCollection:[(TreeBranch*)item duplicatesInBranch]];
//        }
//        else if ([item isLeaf]) {
//            [answer addFiles: [[(CRVLFile*)item getFileInformation] duplicateList] ];
//        }
//    }
//    return answer;
//}

/*
 * Debug
 */

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"TreeNode:(%ld files)", [self count]];
}

@end


@implementation ItemEnumerator

-(instancetype) initWithParent:(TreeNode*)parentA {
    self->index = 0;
    self->parent = parentA;
    return self;
}

-(id) nextObject {
    if (index < [self->parent itemCount]) {
        return [self->parent itemAtIndex:index++];
    }
    return nil;
}


@end
