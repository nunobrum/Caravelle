//
//  SideBarObject.m
//  Caravelle
//
//  Created by Nuno on 14/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "SideBarObject.h"

@implementation SideBarObject

-(NSString*) hint {
    if ([self->_objValue respondsToSelector:@selector(hint)]) {
        return [self->_objValue performSelector:@selector(hint)];
    }
    return @"";
}

@end
