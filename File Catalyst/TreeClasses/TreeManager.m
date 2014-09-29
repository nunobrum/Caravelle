//
//  TreeManager.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeManager.h"
#import "TreeBranch_TreeBranchPrivate.h"

@implementation TreeManager

-(TreeManager*) init {
    self->iArray = [[NSMutableArray alloc] init];
    return self;
}


-(TreeBranch*) addTreeBranchWithURL:(NSURL*)url {
    NSUInteger index=0;
    TreeBranch *answer=nil;
    while (index < [self->iArray count]) {
        TreeBranch *item = self->iArray[index];
        NSUInteger comparison = [item relationTo:[url path]];
        if (comparison == pathIsChild) {
            NSUInteger level = [[[item url] pathComponents] count]; // Get the level of the root;
            NSArray *pathComponents = [url pathComponents];
            NSUInteger top_level = [pathComponents count];
            TreeBranch *cursor=item;
            while (level < top_level) {
                NSString *path = pathComponents[level];
                TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
                if (child==nil) {
                    NSRange rng;
                    rng.location=0;
                    rng.length = level;
                    NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                    @synchronized(cursor) {
                        [cursor addURL:newURL];
                        [cursor setTag:tagTreeItemDirty];
                    }
                    [cursor refreshContentsOnQueue:operationsQueue];
                }
                if ([child isBranch]) {
                    cursor = (TreeBranch*)child;
                    level++;
                }
                else
                    return nil; //Failing here is serious . Giving up search
            }
            answer = cursor;
            index++;
        }
        else if (comparison==pathIsParent) {
            /* Will add this to the node being inserted */
            
        }
    }
    if (answer==nil) { // If not found in existing trees will create it
        id aux = [TreeItem treeItemForURL:url parent:nil];
        // But will only return it if is a Branch Like
        if ([aux isBranch]) {
            answer = aux;
            @synchronized(self) {
                [self->iArray addObject:answer];
            }

        }
    }
    return answer;
}

-(TreeItem*) getTreeItemWithURL:(NSURL*)url {
    TreeItem *answer=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item containsURL:url]) {
            answer = [item treeItemWithURL:url];
            break;
        }
    }
    return answer;
}

-(void) addTreeBranch:(TreeBranch*)node {
    TreeBranch *cursor=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item containsURL:[node url]]) {
            cursor = item;
            break;
        }
    }
    if (cursor) { // There is already a root containing this node. Will find it and add it
        NSUInteger level = [[[cursor url] pathComponents] count]; // Get the level of the root;
        NSArray *pathComponents = [[node url] pathComponents];
        NSUInteger top_level = [pathComponents count]-1;
        while (level < top_level) {
            NSString *path = pathComponents[level];
            TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
            if (child==nil) {
                NSRange rng;
                rng.location=0;
                rng.length = level;
                NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                child = [TreeItem treeItemForURL:newURL parent:cursor];
                [child setTag:tagTreeItemDirty];
            }
            cursor = (TreeBranch*)child;
        }
        [cursor addItem:node]; // Finally add the node
    }
    else {
        [self->iArray addObject:node];
    }
}

-(void) removeTreeBranch:(TreeBranch*)node {
    @synchronized(self) {
        [self->iArray removeObject:node];
    }
}

@end
