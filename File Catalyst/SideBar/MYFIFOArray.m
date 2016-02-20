//
//  MYFIFOArray.m
//  Caravelle
//
//  Created by Nuno on 20/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "MYFIFOArray.h"

@implementation MYFIFOArray

-(instancetype) init {
    self = [super init];
    self->fifo = [[NSMutableArray alloc] init];
    return self;
}

-(instancetype) initWithArray:(NSArray *)array {
    self = [super init];
    self->fifo = [[NSMutableArray alloc] initWithArray:array];
    return self;
}

-(void) push:(NSObject*)obj {
    [self->fifo addObject:obj];
}

-(id) pop {
    id obj = [self->fifo firstObject];
    [self->fifo removeObjectAtIndex:0];
    return obj;
}

-(NSArray*) array {
    return self->fifo;
}

-(NSInteger) count {
    return [self->fifo count];
}

@end

@implementation MYFIFOArrayUnique

-(instancetype) init {
    self = [super init];
    self->selComparator = nil;
    return self;
}

-(void) setComparator:(SEL)comparator {
    self->selComparator = comparator;
}

-(NSInteger) indexOfObject:(id)obj {
    if (self->selComparator==nil) {
        return [self->fifo indexOfObject:obj];
    }
    NSInteger index = 0;
    for (id p in self->fifo) {
        if ([p performSelector:self->selComparator withObject:obj]) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

-(void) push:(NSObject*)obj {
    if (self->selComparator==nil) {
        if (NO==[self->fifo containsObject:obj]) {
            [super push:obj];
        }
    }
    else {
        NSAssert1([obj respondsToSelector:self->selComparator], @"MYFIFOArrayUnique: push must respond to %@", NSStringFromSelector(self->selComparator));
        
        NSInteger index = [self indexOfObject:obj];
        if (index == NSNotFound) {
            [super push:obj];
        }
    }
}

-(void) pushFirst:(NSObject*)obj {
    // First will try to find and delete if exists
    if (self->selComparator==nil) {
        [self->fifo removeObject:obj];
    }
    else {
        NSAssert1([obj respondsToSelector:self->selComparator], @"MYFIFOArrayUnique: push must respond to %@", NSStringFromSelector(self->selComparator));
        
        NSInteger index = [self indexOfObject:obj];
        if (index == NSNotFound) {
            [self->fifo removeObjectAtIndex:index];
        }
    }
    [super push:obj];
}


@end
