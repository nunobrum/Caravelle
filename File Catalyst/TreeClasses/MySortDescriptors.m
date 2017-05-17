//
//  MySortDescriptors.m
//  Caravelle
//
//  Created by Nuno Brum on 20.02.17.
//  Copyright © 2017 Nuno Brum. All rights reserved.
//

#import "MySortDescriptors.h"
#import "CustomTableHeaderView.h"

@implementation MySortDescriptors

-(instancetype) init {
    self = [super init];
    self->_sortDescArray = nil;
    return self;
}

-(NSComparisonResult) compareObject:(id _Nonnull)object1 toObject:(id _Nonnull)object2 {
    for (NSSortDescriptor *sd in self->_sortDescArray) {
        NSComparisonResult test = [sd compareObject:object1 toObject:object2];
        if (test != NSOrderedSame)
            return test;
    }
    return NSOrderedSame;
}

-(NSInteger) count {
    return self->_sortDescArray.count;
}

-(NodeSortDescriptor*) objectAtIndexedSubscript:(NSUInteger)idx {
    return self->_sortDescArray[idx];
}

-(void) addSortDescriptor:(NodeSortDescriptor *)sortDesc {
    if (self->_sortDescArray == nil) {
        self->_sortDescArray = [[NSMutableArray alloc] initWithCapacity:1];
    }
    else {
        // First check whether it was already in
        [self removeSortOnField:sortDesc.field];
    }
    [self->_sortDescArray insertObject:sortDesc atIndex:0];
    
}

-(void) removeAll {
    [self->_sortDescArray removeAllObjects];
}

- (void) removeSortOnField:(NSString*)field {
    int i = 0 ;
    while ( i < self->_sortDescArray.count) {
        NodeSortDescriptor *s = self->_sortDescArray[i];
        if ([s.field isEqualToString:field]) {
            [self->_sortDescArray removeObjectAtIndex:i];
        }
        else
            i++;
    }
}

-(NodeSortDescriptor*) sortDescriptorForFieldID:(NSString * _Nonnull)fieldID {
    for (NodeSortDescriptor* desc in self->_sortDescArray) {
        if ([desc.field isEqualToString:fieldID]) {
            return desc;
        }
    }
    return nil;
}

//-(NSInteger) indexOfFieldID:(NSString * _Nonnull)fieldID {
//    NSUInteger idx = 0;
//    for (NodeSortDescriptor* desc in self->_sortDescArray) {
//        if ([desc.field isEqualToString:fieldID]) {
//            return idx;
//        }
//        idx++;
//    }
//    return -1;
//}

-(BOOL) hasFieldID:(NSString *)fieldID {
    return [self sortDescriptorForFieldID:fieldID] != nil;
}

// This makes the TreeBranch enumeratable, by passing the Fast Enumerating method to the children array
-(NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [self->_sortDescArray countByEnumeratingWithState:state
                                              objects:buffer
                                                count:len];
}

@end
