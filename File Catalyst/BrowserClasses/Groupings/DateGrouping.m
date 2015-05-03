//
//  DateGrouping.m
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DateGrouping.h"

@implementation DateGrouping {
    NSMutableArray *values;
}


-(NSArray*) groupItemsFor:(id) newObject {
    // Just accumulates values
    if (values==nil) {
        values = [[NSMutableArray alloc] initWithCapacity:100];
    }
    if (newObject!=nil) {
        NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
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
    // Calculates the differential
    NSInteger *differential = malloc([values count] * sizeof(NSInteger));
    long long sum = 0;
    //NSInteger min;
    NSInteger max = 0;
    sum = differential[0] = [values[0] longValue];
    for (int i=1 ; i < [values count] ; i++) {
        differential[i] = [values[i] longLongValue] - differential[i-1];
        if (differential[i] > differential[max]) max = i;
        //if (differential[i]< min) max = differential[i];
        sum += differential[i];
    }
    NSInteger average = sum / [values count];
    NSInteger groupCount = 0;
    NSMutableArray * groupItems = [NSMutableArray arrayWithCapacity:20];

    while (groupCount++ < 20) {
        GroupItem *item = [GroupItem alloc];
        [item setNElements:max];
        [groupItems addObject:item];

        differential[max]=0; // Kills the current max
        // searches for a new max
        for (int i=0 ; i < [values count] ; i++) {
            if (differential[i] > differential[max]) max = i;
        }

        // stops if the differential is too small
        if (differential[max] < average && groupCount > 10) break;
    }
    free(differential);

    // groups need to placed in correct Order. // TODO:!!!!! This needs to be consistent with the ascending rule in the descriptor
    [groupItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(GroupItem*)obj1 nElements] > [(GroupItem*)obj1 nElements];
    }];

    NSString *prevTitle = [NSByteCountFormatter stringFromByteCount:[values[0] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    GroupItem *next = groupItems[0];
    for (NSInteger i=0; i < [groupItems count]-1; i++) {
        GroupItem *item = next;
        next= groupItems[i+1];
        NSString *currTitle = [NSByteCountFormatter stringFromByteCount:[values[next.nElements] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        [item setTitle:  [NSString stringWithFormat:@"From %@ To %@",prevTitle, currTitle]];
        item.nElements = [next nElements] - item.nElements;
        prevTitle = currTitle;

    }
    next = [values lastObject];
    NSString *lastTitle = [NSByteCountFormatter stringFromByteCount:[values[next.nElements] longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    GroupItem *lastItem = [[GroupItem alloc] initWithTitle:[NSString stringWithFormat:@"From %@ To %@", prevTitle, lastTitle]];
    [groupItems addObject:lastItem];
    return groupItems;
    
}


@end
