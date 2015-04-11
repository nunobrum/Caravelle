//
//  IconViewBox.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 09/04/15.
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

-(void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];

    // check for click count above one, which we assume means it's a double click
    if([theEvent clickCount] > 1) {
        //NSLog(@"double click!");
        if(delegate && [delegate respondsToSelector:@selector(doubleClick:)]) {
            [delegate performSelector:@selector(doubleClick:) withObject:self];
        }
    }
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // TODO: !!!! Draw rectangle around the Box
    if(delegate && [delegate respondsToSelector:@selector(rightClick:)])
        [delegate performSelector:@selector(rightClick:) withObject:self];
    [super rightMouseDown:theEvent];
}


@end
