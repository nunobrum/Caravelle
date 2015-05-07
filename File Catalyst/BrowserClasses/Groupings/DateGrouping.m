//
//  DateGrouping.m
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DateGrouping.h"

#define MAX_GROUPS 20
#define SECONDS_IN_DAY (24*60*60)

NSString *titleForDates(NSDate *first, NSDate *last) {
    NSString *answer = nil;
    static NSDateFormatter *dateFormater = nil;
    if (dateFormater== nil) {
        dateFormater = [[NSDateFormatter alloc] init];
        [dateFormater setDateStyle:NSDateFormatterMediumStyle];
    }
    NSString *prevTitle = [dateFormater stringFromDate: first ];
    NSString *currTitle = [dateFormater stringFromDate: last];

    if ( [prevTitle isEqualToString:currTitle]) { // Less than one day
        answer = currTitle;
    }
    else {
        if (first < last)
            answer = [NSString stringWithFormat:@"Since %@ To %@",prevTitle, currTitle];
        else
            answer = [NSString stringWithFormat:@"Between %@ and %@",prevTitle, currTitle];
    }
    return answer;
}

@implementation DateGrouping {
    NSMutableArray *values;
}

-(void) reset {
    [super reset];
    [self->values removeAllObjects];
}


-(NSArray*) groupItemsFor:(id) newObject {
    // Just accumulates values
    if (values==nil) {
        values = [[NSMutableArray alloc] initWithCapacity:100];
    }
    if (newObject!=nil) {
        NSAssert([newObject isKindOfClass:[NSDate class]], @"Expected NSDate");
        [values addObject:newObject];
        self.lastObject = newObject;
    }
    else {
        // Create the Unknown Size Group
        // Sizes with nill are a problem because they cannot be stored as Values. Instead
        // and immediate header is created and returned. Then, elements are added to the object
        if ([self.lastObject isKindOfClass:[GroupItem class]]==NO) { // Creates the header
            GroupItem *GI = [[GroupItem alloc] initWithTitle:@"Unknown Size"];
            self.lastObject = GI; // This is done just to avoid repeating this block
            return [[NSArray arrayWithObject:GI] arrayByAddingObjectsFromArray:[self flushGroups]];
        }
    }
    return nil;
}

-(NSArray*) flushGroups {
    if (values==nil || [values count]==0)
        return nil;
    // Calculates the differential
    NSTimeInterval *differential = malloc(([values count]-1) * sizeof(NSTimeInterval));
    NSTimeInterval sum = 0;
    //NSInteger min;
    NSInteger max = 0;
    sum  = 0;
    for (int i=0 ; i < [values count]-1 ; i++) {
        differential[i] = abs([values[i+1] timeIntervalSinceDate:values[i]]);
        if (differential[i] > differential[max]) max = i;
        //if (differential[i]< min) max = differential[i];
        sum += differential[i];
        //NSLog(@"From %@ to %@ (%f)",values[i], values[i+1], differential[i]);
    }
    NSInteger average = sum / [values count];
    NSInteger groupCount = 0;
    NSMutableArray * groupIndexes = [NSMutableArray arrayWithCapacity:MAX_GROUPS-1];

    if (average < SECONDS_IN_DAY)
        average = SECONDS_IN_DAY;

    NSInteger max_count;
    max_count = MAX_GROUPS - 1;
    if (max_count > [values count]-1)
        max_count = [values count]-1;
    while (groupCount < max_count) {
        groupCount++;
        [groupIndexes addObject:[NSNumber numberWithInteger:max]];

        differential[max]=0; // Kills the current max
        // searches for a new max
        for (int i=0 ; i < [values count]-1 ; i++) {
            if (differential[i] > differential[max]) max = i;
        }
        // stops if the differential is too small
        if (differential[max] < average && groupCount > 10) break;
    }
    free(differential);

    // indexes need to placed in ascending order for the next step
    [groupIndexes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare: obj2];
    }];

    NSMutableArray * groupItems = [NSMutableArray arrayWithCapacity:MAX_GROUPS];
    NSInteger aux = [[groupIndexes firstObject] integerValue];
    GroupItem *item = [[GroupItem alloc] initWithTitle:titleForDates([values firstObject], values[aux])];
    item.nElements = [values count] - 1;
    [groupItems addObject:item];

    max_count = [groupIndexes count];
    max_count -= 2;
    for (NSInteger i=0; i < max_count; i++) {
        NSInteger first = [groupIndexes[i] integerValue]+1;
        NSInteger last = [groupIndexes[i+1] integerValue];

        GroupItem *item = [[GroupItem alloc] initWithTitle:titleForDates([values objectAtIndex:first], [values objectAtIndex:last])];
        item.nElements = [values count] - 1 - first;
        [groupItems addObject:item];
    }
    if ([groupIndexes count] > 0) {
        aux = [[groupIndexes lastObject] integerValue] + 1;
        item = [[GroupItem alloc] initWithTitle:titleForDates([values objectAtIndex:aux], [values lastObject])];
        item.nElements = [values count] - 1 - aux;
        [groupItems addObject:item];
    }
    return groupItems;
}


@end
