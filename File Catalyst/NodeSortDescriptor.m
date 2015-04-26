//
//  NodeSortDescriptor.m
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NodeSortDescriptor.h"



/*
 * Grouping of elements
 */

@implementation BaseGroupingObject
-(instancetype) initWithAscending:(BOOL)ascending {
    self->_ascending = ascending;
    self->_lastObject = nil;
    return self;
}
-(NSString*) groupTitleFor:(id) newObject {
    return nil; // No groups are created for the base class
}
-(void) restart {
    self->_lastObject = nil;
}
@end

@implementation NumberGrouping {
    NSUInteger base;
}

// Distribute : < 1k < 10k < 100k < 1Meg < 10Meg < 100Meg < 1G < 10G < 100G< More
-(NSString*) groupTitleFor:(id) newObject {
    NSAssert([newObject isKindOfClass:[NSNumber class]], @"Expected NSNumber");
    NSString *title=nil;
    if (self->_ascending){
        NSUInteger value = [(NSNumber*)newObject integerValue];
        NSUInteger b;
        if (self->_lastObject==nil) {
            base=0;
            b = 1000; // Starts with less than 1kB
        }
        while (b < value) b *= 10;
        if (b!=base) {
            // A new Title is needed
            base = b;
            title = [NSString stringWithFormat:@"Smaller than %@", [NSByteCountFormatter stringFromByteCount:base countStyle:NSByteCountFormatterCountStyleFile]];
            self->_currentTitle = title;
        }

    }
    else {
        NSUInteger value = [(NSNumber*)newObject integerValue];
        NSUInteger b;
        if (self->_lastObject==nil) {
            base=1;
            while (base < value) {
                base *=10;
            }
            b = base;
        }
        while (b > value) b /= 10;
        if (b!=base) {
            // A new Title is needed
            base = b;
            title = [NSString stringWithFormat:@"Bigger than %@", [NSByteCountFormatter stringFromByteCount:base countStyle:NSByteCountFormatterCountStyleFile]];
            self->_currentTitle = title;
        }

    }
    if (self->_lastObject == newObject) {
        return nil;
    }
    self->_lastObject = newObject;
    return title;
}


@end

@implementation DateGrouping
// Distribute : Today, Yesterday, Week{2.4}, Month{2..12}, Year{1..5}, Older


@end

@implementation StringGrouping

-(NSString*) groupTitleFor:(id) newObject {
    NSAssert([newObject isKindOfClass:[NSString class]], @"Expected NSString");
    if ([self->_lastObject isEqualToString: newObject]) {
        return nil;
    }
    self->_lastObject = newObject;
    return newObject;
}

@end

@implementation AlphabetGroupping
// Distribute Alphabet



@end

BaseGroupingObject* groupingFor(id objTemplate, BOOL ascending) {
    if ([objTemplate isKindOfClass:[NSDate class]]) {
        return [[DateGrouping alloc] initWithAscending:ascending];
    }
    else if ([objTemplate isKindOfClass:[NSNumber class]]) {
        return [[NumberGrouping alloc] initWithAscending:ascending];
    }
    else if ([objTemplate isKindOfClass:[NSString class]]) {
        return [[StringGrouping alloc] initWithAscending:ascending];
    }
    return nil;
}

@implementation NodeSortDescriptor

-(void) setGrouping:(BOOL)grouping {
    self->_grouping = grouping;
}
-(BOOL) isGrouping {
    return self->_grouping;
}

// Resets the Grouping Object
-(void) restart {
    [self->_groupObject restart];
}

-(NSString*) groupTitleForObject:(id)object {
    if (self->_groupObject==nil) {
        self->_groupObject = groupingFor([object valueForKey:self.key], self.ascending);
    }
    return [self->_groupObject groupTitleFor:[object valueForKey:self.key]];
}

@end


