//
//  NodeSortDescriptor.m
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NodeSortDescriptor.h"
#import "SizeGrouping.h"
#import "StringGrouping.h"
#import "DateGrouping.h"

/*
 * Grouping of elements
 */


@implementation AlphabetGroupping
// Distribute Alphabet



@end

BaseGrouping* groupingFor(id objTemplate, BOOL ascending) {
    if ([objTemplate isKindOfClass:[NSDate class]]) {
        return [[DateGrouping alloc] initWithAscending:ascending];
    }
    else if ([objTemplate isKindOfClass:[NSNumber class]]) {
        return [[SizeGrouping alloc] initWithAscending:ascending];
    }
    else if ([objTemplate isKindOfClass:[NSString class]]) {
        return [[StringGrouping alloc] initWithAscending:ascending];
    }
    return nil;
}

@implementation NodeSortDescriptor

-(void) setGrouping:(BOOL)grouping {
    self->_grouping = grouping;
}
-(BOOL) isGrouping {
    return self->_grouping;
}

// Resets the Grouping Object
-(NSArray*) flushGroups {
    NSArray *answer = [self->_groupObject flushGroups];
    for (GroupItem *item in answer)
        [item setDescriptor:self];
    return answer;
}

-(NSArray*) groupItemsForObject:(id)object {
    if (self->_groupObject==nil) {
        self->_groupObject = groupingFor([object valueForKey:self.key], self.ascending);
    }
    NSArray *answer = [self->_groupObject groupItemsFor:[object valueForKey:self.key]];
    for (GroupItem *item in answer)
        [item setDescriptor:self];
    return answer;
}

@end


