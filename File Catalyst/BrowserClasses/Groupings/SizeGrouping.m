//
//  SizeGrouping.m
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//


#import "SizeGrouping.h"
#include "ByteCounterUtils.h"

@implementation SizeGrouping {
    decade_counter_t current_base;
    NSString * firstSize, *lastSize;
}

-(instancetype) initWithAscending:(BOOL)ascending {
    self = [super initWithAscending:ascending];
    self->firstSize = nil;
    self->lastSize = nil;
    return self;
}

-(NSArray*) groupItemsFor:(id) newObject {

    if (self.lastObject==nil) {
        if (newObject!=nil) {
            NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
            long n = [newObject longValue];

            // make initialization here
            adjust_decade_to_value(&current_base, 10); // Starts with 10 Byte
            self->firstSize  = [NSByteCountFormatter stringFromByteCount:n countStyle:NSByteCountFormatterCountStyleFile];
        }
        else {
            self->firstSize = @"Unknown Size";
            self->current_base.decx3=0;
            self->current_base.dec = -1;
        }
        self->lastSize = nil;
        self.lastObject = [[GroupItem alloc] initWithTitle:nil];

    }
    else {
        ((GroupItem*)self.lastObject).nElements++;
        if (newObject!=nil) {
            NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
            long n = [newObject longValue];

            // Return a Header when the new object is not in the same order of magnitude
            decade_counter_t new_base;
            adjust_decade_to_value(&new_base, n);
            if (! decades_equal(new_base,current_base)) {
                NSString *title;
                if (current_base.dec==-1) {
                    title = self->firstSize;
                }
                else {
                    if (self->lastSize)
                        title = [NSString stringWithFormat:@"From %@ to %@", self->firstSize, self->lastSize];
                    else
                        title = [NSString stringWithFormat:@"%@", self->firstSize];
                }
                [self.lastObject setTitle:title];

                self->firstSize = [NSByteCountFormatter stringFromByteCount:n countStyle:NSByteCountFormatterCountStyleFile];
                self->lastSize = nil;
                // Store the answer
                NSArray *answer = [NSArray arrayWithObject:self.lastObject];
                current_base = new_base;
                // Creates a new Object
                self.lastObject = [[GroupItem alloc] initWithTitle:nil];
                return answer;
            }
            else {
                self->lastSize = [NSByteCountFormatter stringFromByteCount:n countStyle:NSByteCountFormatterCountStyleFile];
            }

        }
        else {
            // Create the Unknown Size Group
            // Sizes with nill are a problem because they cannot be stored as Values. Instead
            // and immediate header is created and returned. Then, elements are added to the object
            if (self.lastObject == nil || [[self.lastObject title] isEqualToString:@"Unknown Size"] ==NO) { // Creates the header
                self.lastObject = [[GroupItem alloc] initWithTitle:@"Unknown Size"]; // Creates a ne
            }
        }
    }
    return nil;
}

-(NSArray*) flushGroups {
    id lastObj = self.lastObject;
    self.lastObject =  nil;
    if (lastObj && [lastObj isKindOfClass:[GroupItem class]]) {
        decade_counter_t new_base = current_base;
        increment_decade(&new_base);
        NSString *title;
        if (self->lastSize)
            title = [NSString stringWithFormat:@"From %@ to %@",
                           self->firstSize,
                           self->lastSize];

        else
            title = [NSString stringWithFormat:@"%@", self->firstSize];

        [lastObj setTitle:title];

        return [NSArray arrayWithObject:lastObj];
    }
    return nil;
}


@end