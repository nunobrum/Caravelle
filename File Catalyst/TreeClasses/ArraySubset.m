//
//  ArraySubset.m
//  Caravelle
//
//  Created by Nuno Brum on 04/10/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "ArraySubset.h"

@implementation ArraySubset

-(id) objectInRangeAtIndex:(NSUInteger)index {
    return self.array[self.range.location+index];
}

@end
