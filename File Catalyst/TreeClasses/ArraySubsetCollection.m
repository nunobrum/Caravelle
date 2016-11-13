//
//  ArraySubsetCollection.m
//  Caravelle
//
//  Created by Nuno Brum on 04/10/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "ArraySubsetCollection.h"

@implementation ArraySubsetCollection

-(NSUInteger) count {
    NSUInteger count = 0;
    
    for (ArraySubset *arr in self.subarrays) {
        count += arr.array.count;
    }
    return count;
}

-(NSUInteger) countOfSubarrays {
    return self.subarrays.count;
}

-(ElemEnumerator*) tableElements {
    ElemEnumerator *answer = [[ElemEnumerator alloc] initWithParent:self];
    return answer;
}

@end

@implementation ElemEnumerator

-(instancetype) initWithParent:(ArraySubsetCollection *)parent {
    self->index = 0;
    self->section = 0;
    self->_parent = parent;
    return self;
}

-(id) nextObject {
    if (section < [self->_parent countOfSubarrays]) {
        ArraySubset *sa = self->_parent.subarrays[section];
        id obj = [sa objectInRangeAtIndex:index++];
        if (index >= sa.range.length) {
            section ++;
            index = 0;
        }
        return obj;
    }
    return nil;
}


@end
