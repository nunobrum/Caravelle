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

// This is needed to update screen information
-(void) mouseDown:(NSEvent *)theEvent {
    [(id<ParentProtocol>)[self delegate] updateFocus:self];
    [super mouseDown:theEvent];
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Before this was done to ensure that the right click got the correct view.
    [(id<ParentProtocol>)[self delegate] contextualFocus:self];
    [super rightMouseDown:theEvent];
}


- (void)keyDown:(NSEvent *)theEvent {
    NSString *key = [theEvent characters];
    unichar keyCode = [key characterAtIndex:0];
    
    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVIOUR] ;

    if ((([theEvent modifierFlags] & NSCommandKeyMask) &&
         (keyCode == KeyCodeUp  ||
          keyCode == KeyCodeDown )) ||
        (behave == APP_BEHAVIOUR_MULTIPLATFORM &&
         ([key isEqualToString:@"\r"] || // The Return key will open the file
          [key isEqualToString:@"\t"] || // the tab key will switch Panes
          [key isEqualToString:@"\x19"] || // Shift-Tab will also switch Panes
          [key isEqualToString:@" "])) ||   // The space will mark the file
        (behave == APP_BEHAVIOUR_NATIVE &&
         ([key isEqualToString:@" "] || // The Space will open the file
          [key isEqualToString:@"\x19"] || // Shift-Tab will move to previous file
          [key isEqualToString:@"\t"]))) { // the tab key will move to next file
             [[self delegate ] performSelector:@selector(keyDown:) withObject:theEvent];
         }

    // perform nextView
    else {
        // propagate to super
        [super keyDown:theEvent];
    }
}

- (void)cancelOperation:(id)sender {
    // clean the filter
    [[self delegate] performSelector:@selector(cancelOperation:) withObject:self];
    // and pass the cancel operation upwards anyway
    //[super cancelOperation:sender];
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
