//
//  BrowserOutlineView.m
//  File Catalyst
//
//  Created by Nuno Brum on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserOutlineView.h"
#import "BrowserController.h"

@implementation BrowserOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    //[self setRightMouseLocation:BROWSER_TABLE_VIEW_INVALIDATED_ROW];

    // Drawing code here.

}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Now register menu location for the delegate to read
    /*NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    NSInteger row = [self rowAtPoint:local_point];
    [self setRightMouseLocation: row];*/
    [(BrowserController*)[self delegate] tableSelected:self];
    [super rightMouseDown:theEvent];
}


- (void)keyDown:(NSEvent *)theEvent {
    NSString *key = [theEvent characters];
    //NSLog(@"KD: code:%@",[theEvent characters]);

    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVOUR] ;

    if (behave == APP_BEHAVIOUR_MULTIPLATFORM &&
        ([key isEqualToString:@"\r"] || // The Return key will open the file
         [key isEqualToString:@"\t"] || // the tab key will switch Panes
         [key isEqualToString:@"\x19"] || // Shift-Tab will also switch Panes
         [key isEqualToString:@" "])) {  // The space will mark the file
            [[self delegate ] performSelector:@selector(keyDown:) withObject:theEvent];
        }
    else if (behave == APP_BEHAVIOUR_NATIVE &&
             ([key isEqualToString:@" "] || // The Space will open the file
              [key isEqualToString:@"\x19"] || // Shift-Tab will move to previous file
              [key isEqualToString:@"\t"])) { // the tab key will move to next file
                 [[self delegate ] performSelector:@selector(keyDown:) withObject:theEvent];
             }

    // perform nextView
    else {
        // propagate to super
        [super keyDown:theEvent];
    }
}


/* The menu handling is forwarded to the Delegate. 
   For the contextual Menus the selection is different, than for the application */
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    return [(id<MYViewProtocol>)[self delegate] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    return [(id<MYViewProtocol>)[self delegate] writeSelectionToPasteboard:pboard types:types];
}

@end
