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


@implementation NodeSortDescriptor

-(void) setGrouping:(BOOL)grouping using:(NSString*)groupID {
    self->_grouping = grouping;
    if (grouping) {
        if ([groupID isEqualToString:@"size"])
            self->_groupObject = [[SizeGrouping alloc] initWithAscending:self.ascending];
        else if ([groupID isEqualToString:@"date"])
            self->_groupObject = [[DateGrouping alloc] initWithAscending:self.ascending];
        else if ([groupID isEqualToString:@"string"])
            self->_groupObject = [[StringGrouping alloc] initWithAscending:self.ascending];
        else {
            NSLog(@"NodeSortDescriptor.setGrouping:using:  Not supported");
            self->_grouping = NO;
        }
    }
}


-(void) copyGroupObject:(NodeSortDescriptor *)other {
    self->_grouping = other->_grouping;
    self->_groupObject = other->_groupObject;
}

-(BaseGrouping*) groupOpject {
    return self->_groupObject;
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
    NSArray *answer = [self->_groupObject groupItemsFor:[object valueForKey:self.key]];
    for (GroupItem *item in answer)
        [item setDescriptor:self];
    return answer;
}

-(void) reset {
    [self->_groupObject reset];
}

@end


