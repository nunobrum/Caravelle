//
//  NumberGrouping.m
//  Caravelle
//
//  Created by Nuno on 17/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NumberGrouping.h"

@implementation NumberGrouping


-(NSArray*) groupItemsFor:(id) newObject {
    NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
    if ([self.lastObject isEqualToNumber: newObject]) {
        return nil;
    }
    self.lastObject = newObject;
    GroupItem *GI = [[GroupItem alloc] initWithTitle:[NSString stringWithFormat:@"%@", newObject]];
    return [NSArray arrayWithObject:GI];
}

@end
