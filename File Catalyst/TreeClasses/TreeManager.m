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

-(TreeBranch*) addTreeBranch:(NSURL*)url {
    TreeBranch *answer=nil;
    for (TreeBranch *item in self) {
        if ([item containsURL:url]) {
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

        }
    }
    if (answer==nil) { // If not found in existing trees will create it
        id aux = [TreeItem treeItemForURL:url parent:nil];
        // But will only return it if is a Branch Like
        if ([aux isBranch]) {
            answer = aux;
        }
    }
    return answer;
}

-(TreeItem*) getItemWithURL:(NSURL*)url {
    TreeItem *answer=nil;
    for (TreeBranch *item in self) {
        if ([item containsURL:url]) {
            answer = [item treeItemWithURL:url];
            break;
        }
    }
    return answer;
}

-(void) removeTree:(TreeBranch*)node {
    [self removeObject:node];
}

@end
