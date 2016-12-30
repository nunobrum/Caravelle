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
    self->_needsRefresh = YES;
    return self;
}

#pragma mark - TreeViewer Protocol
-(void) reset {
    self->_currIndex = -1;
    self->_item = self->_root;
}

-(BOOL) needsRefresh {
    return self->_needsRefresh;
}


-(void) setParent:(TreeBranch *)parent {
    if (parent != self->_root) {
        self->_root = parent;
        self->_needsRefresh = YES;
    }
}

-(TreeBranch*) parent {
    return self->_root;
}

-(void) setDepth:(NSInteger)depth {
    if (depth != self->_maxLevel) {
        self->_maxLevel = depth;
        self->_needsRefresh = YES;
    }
}

-(NSInteger) depth {
    return self->_maxLevel;
}

-(void) setSortDescriptor:(NSSortDescriptor *)sortDesc {
    if (sortDesc != self->sort)  {
        self->sort = sortDesc;
        self->_needsRefresh = YES;
    }
}

-(NSSortDescriptor*) sortDescriptor {
    return self->sort;
}

-(void) setFilter:(NSPredicate *)filter {
    if (filter != self->_filter)  {
        self->_filter = filter;
        self->_needsRefresh = YES;
    }
}

-(NSPredicate*) filter {
    return self->_filter;
}


-(NSInteger) sectionCount {
    if (self->_sections == nil || self->_needsRefresh == YES) {
        if (self->_sections == nil)
            self->_sections = [[NSMutableArray alloc] init];
        else
            [self->_sections removeAllObjects];
        
        // Always start by the current directory
        if (self->_root == nil) // but first a sanity check.
            return 0;
        
        [self->_sections addObject:self->_root];
        // Then adding the remaining sections.
        if (self->_maxLevel > 0) {
            NSPredicate *onlySections = [NSPredicate predicateWithFormat:@"SELF.hasChildren==YES"];
            [self->_root harvestItemsInBranch:self->_sections
                                        depth:self->_maxLevel-1 // Subtracting one because the depth of one,
             //corresponds to only capturing secions of the current level.
                                       filter:onlySections];
        }
        self->_needsRefresh = NO;
    }
    return [self->_sections count];
}

-(NSInteger) itemCountAtSection:(NSInteger)section {
    TreeBranch *sec = [self sectionNumber:section];
    NSInteger count = [sec numberOItemsWithPredicate:self->_filter tillDepth:0];
    return count;
}

-(TreeBranch*) sectionNumber:(NSInteger) number {
    return self->_sections[number];
}

-(TreeItem*) itemAtIndexPath:(NSIndexPath *)indexPath {
    TreeBranch *sec = [self sectionNumber: indexPath.section];
    if (self->_currSection != indexPath.section) {
        self->_currIndex = NSNotFound;
        self->_currSection = indexPath.section;
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

-(NSString*) groupTitle {
    TreeBranch *section = [self sectionNumber:self->_currSection];
    NSString *answer = [section path];
    return answer;
}

@end
