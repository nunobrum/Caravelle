//
//  BrowserTableView.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserTableView.h"

@implementation BrowserTableView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Now register menu location for the delegate to read
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    NSInteger row = [self rowAtPoint:local_point];
    [self setRightMouseLocation: row];
    [super rightMouseDown:theEvent];
}



/*
 * This will enable the View to respond to Keys and mouse events
 * Will take what is interesting to process, such as normal keys for file navigation,
 * Copy, Cut and Paste : to decide if processed here if sent to AppDelegate.
 */
// This is here for memory only. If later this becomes useful
//-(BOOL) acceptsFirstResponder {
//    NSLog(@"Accepted First Responder: BroswerController");
//    return YES;
//}
//
//- (BOOL)validateProposedFirstResponder:(NSResponder *)responder
//                              forEvent:(NSEvent *)event {
//    // This is only here for a test
//    NSLog(@"validateProposedFirstResponder:forEvent BrowserController");
//    return [super validateProposedFirstResponder:responder forEvent:event];
//}


@end
