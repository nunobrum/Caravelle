//
//  TreeRoot.m
//  Caravelle
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeCollection.h"
#import "TreeBranchCatalyst.h"

@implementation TreeCollection

-(NSArray*) roots {
    return self->_children;
}

-(BOOL) addTreeItem:(TreeItem*)item {
    NSUInteger index=0;
    BOOL OK = NO;
    
    [self willChangeValueForKey:kvoTreeBranchPropertyChildren];  // This will inform the observer about change
    
    @synchronized(self) {
        while (index < [self->_children count]) {
            TreeBranchCatalyst *child = self->_children[index];
            enumPathCompare comparison = [child relationToPath:item.path];
            if (comparison == pathIsSame) {
                // No need to add, its already present
                OK = YES;
                break;
            }
            else if (comparison == pathIsChild) {
                //NSLog(@"TreeCollection.addTreeItem: Adding %@ to %@", item.url, child.url);
                OK = [child addTreeItem:item];
                break;
            }
            else if (comparison==pathIsParent) {
                if (OK==NO) {
                    NSLog(@"TreeCollection.addTreeItem: Replacing %@ with %@ as parent", child.url, item.url);
                    // creates the new node and replaces the existing one.
                    // It will inclose the former in itself.
                    // If the path is a parent, then inherently it should be a Branch
                    OK = [(TreeBranchCatalyst*)item addTreeItem:child];
                    if (OK) {
                        // answer can now replace item in iArray.
                        [self->_children setObject:item atIndexedSubscript:index];
                        index++; // Since the item was replaced, move on to the next
                    }
                    else {
                        break;
                    }
                }
                else {
                    // In this case, what happens is that the item can be removed and added into answer
                    NSLog(@"TreeCollection.addTreeItem: Removing %@", child.url);
                    BOOL OK1 = [(TreeBranchCatalyst*)item addTreeItem:child];
                    if (OK1) {
                        // answer can now replace item in iArray.
                        [self->_children removeObjectAtIndex:index];
                    }
                    else {
                        break; // Failed to insert the child
                    }
                }
            }
            else {
                index++; // If paths are unrelated just increment to the next item
            }
            
        }
        if (OK==NO) { // If not found in existing trees will create it
            if (self->_children==nil)
                self->_children = [[NSMutableArray alloc] init];
            if ([item isLeaf]) {
                // Creates the parent
                NSURL *par_url = [item.url URLByDeletingLastPathComponent];
                TreeBranchCatalyst *parent = [[TreeBranchCatalyst alloc] initWithURL:par_url parent:self];
                
                NSLog(@"TreeCollection.addTreeItem: Adding %@ and %@", parent, item);
                
                [self->_children addObject:parent];
                [parent addTreeItem:item];
            }
            else {
                NSLog(@"TreeCollection.addTreeItem: Adding %@", item);
                [self->_children addObject:item];
            }
            OK = YES;
        }
    }
    if (OK) [self notifyDidChangeTreeBranchPropertyChildren];  // This will inform the observer about change
    return OK;
}


-(void) addFileCollection:(FileCollection*)collection {
    
    for (TreeItem *finfo in collection.fileArray) {
        [self addTreeItem:finfo];
    }
}


@end
