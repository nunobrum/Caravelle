//
//  TreeManager.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 26/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "TreeManager.h"
//#import "TreeBranch_TreeBranchPrivate.h"

@implementation TreeManager

-(TreeManager*) init {
    self->iArray = [[NSMutableArray alloc] init];
    return self;
}


-(TreeBranch*) addTreeBranchWithURL:(NSURL*)url {
    NSUInteger index=0;
    TreeBranch *answer=nil;
    id parent =  nil;
    while (index < [self->iArray count]) {
        TreeBranch *item = self->iArray[index];
        NSUInteger comparison = [item relationTo:[url path]];
        if (comparison == pathIsSame) {
            return item;
        }
        else if (comparison == pathIsChild) {
            id aux = [item addURL:url];
            if ([aux isKindOfClass:[TreeBranch class]])
                answer = aux;
            index++;
        }
        else if (comparison==pathIsParent) {
            /* Will add this to the node being inserted */
            NSUInteger level = [[url pathComponents] count]; // Get the level above the new root;
            NSArray *pathComponents = [[item url] pathComponents];
            NSUInteger top_level = [pathComponents count]-1;
            if (parent==nil) {
                parent =[TreeItem treeItemForURL:url parent:nil];
            }
            if ([parent isKindOfClass:[TreeBranch class]]) {
                answer = parent;
                TreeBranch *cursor = parent;
                while (level < top_level) {
                    NSString *path = pathComponents[level];
                    TreeItem *child = [cursor childWithName:path class:[TreeBranch class]];
                    if (child==nil) {
                        NSRange rng;
                        rng.location=0;
                        rng.length = level+1;
                        NSURL *newURL = [NSURL fileURLWithPathComponents:[pathComponents objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rng]]];
                        child = [cursor addURL:newURL];
                    }
                    if ([child isBranch]) {
                        cursor = (TreeBranch*)child;
                        level++;
                    }
                    else
                        return nil; //Failing here is serious . Giving up search
                }
                [cursor addChild:item]; // Finally add the node
                @synchronized(self) {
                    [self->iArray removeObjectAtIndex:index]; // Remove the node, It will
                }
            }
            else {
                index++;
            }
        }
        else
            index++;
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
    else if (parent!=nil) { // There is a new parent
        @synchronized(self) {
            [self->iArray addObject:parent];
        }
    }
    return answer;
}

-(TreeItem*) getNodeWithURL:(NSURL*)url {
    TreeItem *answer=nil;
    for (TreeBranch *item in self->iArray) {
        if ([item containsURL:url]) {
            answer = [item getNodeWithURL:url];
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
            level++;
            cursor = (TreeBranch*)child;
        }
        [cursor addChild:node]; // Finally add the node
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
