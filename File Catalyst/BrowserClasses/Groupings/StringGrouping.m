//
//  StringGrouping.m
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "StringGrouping.h"


@implementation StringGrouping {
}

-(NSArray*) groupItemsFor:(id) newObject {
    NSAssert([newObject isKindOfClass:[NSString class]], @"Expected NSString");
    if ([self.lastObject isEqualToString: newObject]) {
        return nil;
    }
    self.lastObject = newObject;
    GroupItem *GI = [[GroupItem alloc] initWithTitle:newObject];
    return [NSArray arrayWithObject:GI];
}

@end
