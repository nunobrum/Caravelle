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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [NSApp sendAction:@selector(contextualGotoFolder:) to:nil from:self];
        if(self.delegate && [self.delegate respondsToSelector:@selector(doubleClick:)]) {
            [self.delegate performSelector:@selector(doubleClick:) withObject:self];
        }
#pragma clang diagnostic pop

    }
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // TODO: ! Draw rectangle around the Box
    //[self setBorderColor:[NSColor blueColor]];
    //[self setBorderWidth:1];
    [self setFillColor:[NSColor windowBackgroundColor]];
    [self setTransparent:NO];
    [self setNeedsDisplay:YES];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if(self.delegate && [self.delegate respondsToSelector:@selector(rightClick:)])
        [self.delegate performSelector:@selector(rightClick:) withObject:self];
#pragma clang diagnostic pop

    [super rightMouseDown:theEvent];
}

-(id) representedObject {
    return [self.delegate representedObject];
}


@end
