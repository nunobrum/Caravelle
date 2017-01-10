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
    self->sort = nil; //[NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
    self->_currIndex = NSNotFound; // This will trigger a reset at the first seek
    self->_currSection = NSNotFound;
    self->_sections = nil;
    self->_needsRefresh = (parent != nil); // Only generate a refresh if the receiving branch is not zero.
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


-(NSInteger) countForSection:(TreeBranch*) section {
    NSInteger count;
    NSInteger childLevel = [section degreeToAncester:self->_root];
    if (self->_maxLevel == childLevel)
        count = [section numberOfItemsWithPredicate:self->_filter tillDepth:0];
    else
        count = [section numberOfLeafsWithPredicate:self->_filter tillDepth:0];
    return count;
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
            NSMutableArray <TreeBranch*> *childSections = [[NSMutableArray alloc] init];
            NSPredicate *onlySections = [NSPredicate predicateWithFormat:@"SELF.hasChildren==YES"];
            [self->_root harvestItemsInBranch:childSections
                                        depth:self->_maxLevel-1 // Subtracting one because the depth of one,
             //corresponds to only capturing secions of the current level.
                                       filter:onlySections];
            
            // Finally the sections that will appear empty should be removed.
            for (TreeBranch *child in childSections) {
                NSInteger count = [self countForSection:child];
                if (count != 0) {
                    [self->_sections addObject:child];
                }
            }
        }
        self->_currSection = NSNotFound; // This is needed so that the iterator gets updated.
        self->_needsRefresh = NO;
    }
    return [self->_sections count];
}

-(NSInteger) itemCountAtSection:(NSInteger)section {
    TreeBranch *sec = [self sectionNumber:section];
    NSInteger count = [self countForSection:sec];
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
        NSInteger childLevel = [sec degreeToAncester:self->_root];
        if (childLevel == self->_maxLevel) {
            self->se = [[SortedEnumerator alloc] initWithParent:sec sort:self->sort filter:self->_filter];
        }
        else {
            NSPredicate *noSections = [NSPredicate predicateWithFormat:@"SELF.hasChildren==NO"];
            NSArray <NSPredicate*>* filters = [[NSArray alloc] initWithObjects:noSections, self->_filter, nil];
            NSCompoundPredicate *newFilter = [NSCompoundPredicate andPredicateWithSubpredicates:filters];
            self->se = [[SortedEnumerator alloc] initWithParent:sec sort:self->sort filter:newFilter];
        }
    }
    // Now will check if the we are located at the right element
    if (self->_currIndex != indexPath.item) {
        if (indexPath.item < self->_currIndex) {
            [self->se reset];
            // Advances to the right position
            self->_currIndex = 0;
            self->_item = [self->se nextObject];
        }
        while (self->_currIndex < indexPath.item) {
            self->_item = [self->se nextObject];
            if (self->_item == nil)
                break;
            self->_currIndex++;
        }
    }
    //NSLog(@"s:%ld,i: %ld item:%@",(long)indexPath.section, (long)indexPath.item, self->_item );
    return self->_item;
}

-(NSString*) titleForGroup:(NSInteger)section {
    TreeBranch *STB = [self sectionNumber:section];
    NSString *answer = [STB path];
    return answer;
}

@end
