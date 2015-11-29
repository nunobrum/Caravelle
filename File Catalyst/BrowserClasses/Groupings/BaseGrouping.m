//
//  BaseGrouping.m
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BaseGrouping.h"

@implementation GroupItem

-(instancetype) initWithTitle:(NSString*)title {
    self.title = title;
    self.descriptor = nil;
    self.nElements = 0;
    return self;
}
@end


@implementation BaseGrouping
-(instancetype) initWithAscending:(BOOL)ascending {
    self->_ascending = ascending;
    self->_lastObject = nil;
    return self;
}

-(void) reset {
    self->_lastObject = nil;
}

-(NSArray*) groupItemsFor:(id) newObject {
    return nil; // No groups are created for the base class
}

-(NSArray*) flushGroups {
    self->_lastObject = nil;
    return nil;
}
@end



