//
//  IconViewBox.m
//  Caravelle
//
//  Created by Nuno Brum on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "IconViewBox.h"

@implementation IconViewBox

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

// -------------------------------------------------------------------------------
//	hitTest:aPoint
// -------------------------------------------------------------------------------
- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this view
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
        return self;
    } else {
        return nil;
    }
}

-(id) representedObject {
    return [self.delegate representedObject];
}


@end
