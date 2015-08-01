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
#import "NumberGrouping.h"
#include "Definitions.h"
#import "CustomTableHeaderView.h"

/*
 * Grouping of elements
 */


@implementation AlphabetGroupping
// Distribute Alphabet



@end


@implementation NodeSortDescriptor

-(instancetype) initWithField:(NSString *)field ascending:(BOOL)ascending grouping:(BOOL)grouping {
    NSString * key =      [[columnInfo() objectForKey:field] objectForKey:COL_ACCESSOR_KEY];
    NSString *column_id  =[[columnInfo() objectForKey:field] objectForKey:COL_COL_ID_KEY];
    
    if ([column_id isEqualToString:@"COL_NAME"]) // testing the col_id instead of the FieldID. This will also cover the COL_PATH field
        self = [super initWithKey:key ascending:ascending comparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2 options:NSNumericSearch];
        }];
    else
        self = [super initWithKey:key ascending:ascending];
    
    self->_field = field;
    self->_grouping = grouping;
    
    if (grouping==YES) {
        NSString *groupingSelector =[[columnInfo() objectForKey:field] objectForKey:COL_GROUPING_KEY];
        if (groupingSelector==nil) {
            // Try to get a selector from the transformer
            groupingSelector =[[columnInfo() objectForKey:field] objectForKey:COL_TRANS_KEY];
        }
        if (groupingSelector!=nil) {
            if ([groupingSelector isEqualToString:@"size"])
                self->_groupObject = [[SizeGrouping alloc] initWithAscending:self.ascending];
            else if ([groupingSelector isEqualToString:@"date"])
                self->_groupObject = [[DateGrouping alloc] initWithAscending:self.ascending];
            else if ([groupingSelector isEqualToString:@"string"])
                self->_groupObject = [[StringGrouping alloc] initWithAscending:self.ascending];
            else if ([groupingSelector isEqualToString:@"integer"])
                self->_groupObject = [[NumberGrouping alloc] initWithAscending:self.ascending];
            else {
                NSLog(@"NodeSortDescriptor.setGrouping:using:  Not supported");
                self->_grouping = NO;
            }
        }
        else
            self->_grouping = NO;
    }
    if (self->_grouping != grouping) {
        NSLog(@"NodeSortDescriptor.initWithField:ascending:grouping Failed to set grouping");
    }
    return self;
}


-(NSString*) field {
    return self->_field;
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


