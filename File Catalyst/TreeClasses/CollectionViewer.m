//
//  CollectionViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 28.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "CollectionViewer.h"

@implementation CollectionViewer


-(instancetype) initWithParent:(TreeBranch *)parent depth:(NSUInteger)depth {
    self->_maxLevel = depth;
    self->_root = parent;
    self->_item = nil;
    // Default sortDescriptor
    self->sort = [NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
    self->_currIndex = NSNotFound; // This will trigger a reset at the first seek
    self->_currSection = NSNotFound;
    self->_sections = nil;
    return self;
}

-(NSInteger) sectionCount {
    if (self->_sections == nil) {
        self->_sections = [[NSMutableArray alloc] init];
        NSPredicate *onlySections = [NSPredicate predicateWithFormat:@"SELF.hasChildren==YES"];
        [self->_root harvestItemsInBranch:self->_sections
                                    depth:self->_maxLevel
                                   filter:onlySections];
    }
    return [self->_sections count];
}

-(TreeBranch*) sectionNumber:(NSInteger) number {
    return self->_sections[number];
}

-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath {
    TreeBranch *sec = [self sectionNumber: indexPath.section];
    if (self->_currSection != indexPath.section) {
        self->_currIndex = NSNotFound;
        self->se = [[SortedEnumerator alloc] initWithParent:sec sort:self->sort];
    }
    // Now will check if the we are located at the right element
    if (self->_currIndex != indexPath.item) {
        if (indexPath.item < self->_currIndex) {
            [self->se reset];
            // Advances to the right position
            self->_currIndex = 0;
        }
        while (self->_currIndex++ < indexPath.item) {
            [self->se nextObject];
        }
    }
    return [sec itemAtIndex:indexPath.item];
}

@end
