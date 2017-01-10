//
//  CatalogBranch.m
//  Caravelle
//
//  Created by Nuno Brum on 26/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "CatalogBranch.h"

@implementation CatalogBranch

/* In this class all children are filterBranches
 * All objects that are detractors of this rule will be fitted into 
 * a filter subfolder */
-(BOOL) addTreeItem:(TreeItem*)treeItem {
    // Checks if it can add
    if ([self canContainTreeItem:treeItem] ) {
        assert(self.catalogKey!=nil);
        id branchName = [treeItem valueForKey:self.catalogKey];
        if (self.valueTransformer) {
            @try {
                branchName = [self.valueTransformer transformedValue:branchName];
            }
            @catch (NSException *exception) {
                branchName = nil;
            }
        }
        if (branchName == nil) {
            NSLog(@"CatalogBranch.addTreeItem: - Cant create a branch with this name");
            // then not adds it to itself. TODO:1.5 Can also create an "others" branch.
            return [super addTreeItem:treeItem];
        }
        // Will try to find if already exists
        filterBranch *fb = (filterBranch*)[self childWithName:branchName class:[filterBranch class]];
        if (fb==nil) {
            // The folder doesn't exist. It will created it
            NSPredicate *pred = nil; 
            fb = [[filterBranch alloc] initWithFilter:pred name:branchName parent:self];
            return [self addChild:fb];
        }
        // Adding the treeItem
        if (fb) {
            // Retesting if it was created
            return [fb addTreeItem:treeItem];
        }
        else {
            // if not adds it to itself 
            return [self addChild:treeItem];
        }
    }
    return NO;
}

@end
