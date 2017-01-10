//
//  CollectionViewer.m
//  Caravelle
//
//  Created by Nuno Brum on 28.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "TreeViewer.h"

@implementation TreeViewer


-(instancetype) initWithParent:(TreeBranch *)parent depth:(NSUInteger)depth {
    self->_maxLevel = depth;
    self->_root = parent;
    self->_item = nil;
    // Default sortDescriptor
    self->sort = nil; //[NSSortDescriptor sortDescriptorWithKey:@"isFolder" ascending:NO];
    self->_currRange = NSMakeRange(0, 0); // This will trigger a reset at the first seek
    self->_currSection = NSNotFound;
    self->_sections = nil;
    self->_sectionIndexes = nil;
    self->_needsRefresh = (parent != nil); // Only generate a refresh if the receiving branch is not zero.
    return self;
}

#pragma mark - TreeViewer Protocol
-(void) reset {
    self->_currRange = NSMakeRange(0, 0);
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

-(NSUInteger) count {
    if (self->_sections == nil || self->_needsRefresh == YES) {
        self->_currRange = NSMakeRange(0, 0);
        if (self->_root == nil) // but first a sanity check.
            return 0;
        
        if (self->_sections == nil) {
            self->_sections = [[NSMutableArray alloc] init];
            self->_sectionIndexes = [[NSMutableIndexSet alloc] init];
        }
        else {
            [self->_sections removeAllObjects];
            [self->_sectionIndexes removeAllIndexes];
        }
        
        // Always start by the current directory
        
        [self->_sections addObject:self->_root];
        NSUInteger count = [self countForSection:self->_root];
        [self->_sectionIndexes addIndex:count];
        
        // Then adding the remaining sections.
        if (self->_maxLevel > 0) {
            NSPredicate *onlySections = [NSPredicate predicateWithFormat:@"SELF.hasChildren==YES"];
            NSMutableArray *childSections = [[NSMutableArray alloc] init];
            
            [self->_root harvestItemsInBranch:childSections
                                        depth:self->_maxLevel-1 // Subtracting one because the depth of one,
             //corresponds to only capturing secions of the current level.
                                       filter:onlySections];
            for (TreeBranch* section in childSections) {
                NSInteger itemsInSection = [self countForSection:section];
                if (itemsInSection != 0) { // Only adds non empty sections
                    count += itemsInSection + 1; // Adding the row for the header itself.
                    [self->_sectionIndexes addIndex:count];
                    [self->_sections addObject:section];
                }
            }

        }
        else  { // if (self->_maxLevel == 0)

        }
        self->_currSection = NSNotFound; // This is needed so that the iterator gets updated.
        self->_needsRefresh = NO;
        


    }
    return [self->_sectionIndexes lastIndex];
}


-(TreeItem*) itemAtIndex:(NSUInteger)index; {
    // First find if the requested index is on the right section
    
    if (!NSLocationInRange(index, self->_currRange)) {
        NSInteger __block section = 0; // When incremented this will be 0
        self->_currRange.location = 0;
        [self->_sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            if (index < idx) {
                *stop = YES;
            }
            else {
                section++;
                self->_currRange.location = idx;
            }
        }];
//        NSInteger test_location = [self->_sectionIndexes indexLessThanOrEqualToIndex:index];
//        if (test_location == NSNotFound)
//            test_location = 0;
//        NSAssert(test_location == self->_currRange.location,
//                 @"Dammit this is not working well");
        NSInteger stop = [self->_sectionIndexes indexGreaterThanIndex:index];

        self->_currSection = section;
        if (stop == NSNotFound) { // This means that it reached the end
            self->_item = nil;
            return nil;
        }
        else {
            self->_currRange.length = stop - self->_currRange.location;
        }
        TreeBranch *sec = self->_sections[section];
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
        
        self->_currIndex = self->_currRange.location;
        if (self->_maxLevel > 0) {
            self->_item = self->_sections[self->_currSection];
        }
        else {
            self->_item = [self->se nextObject];
        }
    }
    // Now will check if the we are located at the right element
    if (self->_currIndex != index) {
        if (index < self->_currIndex) {
            // Check if a roll back is needed
            [self->se reset];
            self->_currIndex = self->_currRange.location;
            if (self->_maxLevel > 0) {
                self->_item = self->_sections[self->_currSection];
            }
            else {
                self->_item = [self->se nextObject];
            }
        }
        // Advances to the right position
        
        while (self->_currIndex < index) {
            self->_item = [self->se nextObject];
            self->_currIndex++;
            if (self->_item == nil) {
                //NSLog(@"foi aqui que correu mal, acho eu index: %ld",(long)index);
                break;
            }
        }
    }
    //if (self->_item == nil)
    //    NSLog(@"index: %ld item:%@",(long)index, self->_item );
    return self->_item;
}

-(TreeItem*) nextObject {
    return [self itemAtIndex:self->_currIndex+1];
}

-(BOOL) isGroup:(NSUInteger)index {
    if (self->_maxLevel > 0 && index == 0)
        return YES;
    return [self->_sectionIndexes containsIndex:index] == YES;
    // TODO:!!!!!! Optimise this, this will be too slow
}

-(NSString*) groupTitle {
    TreeBranch *section = self->_sections [self->_currSection];
    NSString *answer = [section path];
    return answer;
}

@end
