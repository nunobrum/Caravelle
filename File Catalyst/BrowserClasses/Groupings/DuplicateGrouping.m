//
//  NumberGrouping.m
//  Caravelle
//
//  Created by Nuno on 17/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DuplicateGrouping.h"

@implementation DuplicateGrouping


-(NSArray*) groupItemsFor:(id) newObject {
    NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
    if ([self.lastObject isEqualToNumber: newObject]) {
        return nil;
    }
    self.lastObject = newObject;
    long long v = [(NSNumber*) newObject longLongValue];
    GroupItem *GI = [[GroupItem alloc] initWithTitle:[NSString stringWithFormat:@"Duplicate Group #%lld", v]];
    return [NSArray arrayWithObject:GI];
}

@end
