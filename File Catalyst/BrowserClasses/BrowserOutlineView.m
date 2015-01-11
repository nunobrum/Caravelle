//
//  BrowserOutlineView.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserOutlineView.h"

@implementation BrowserOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.

}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Now register menu location for the delegate to read
    NSPoint point = [theEvent locationInWindow];
    NSInteger row = [self rowAtPoint:point];
    [self setRightMouseLocation: row];
    [super rightMouseDown:theEvent];
}

@end
