//
//  BrowserTableView.m
//  File Catalyst
//
//  Created by Nuno Brum on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserTableView.h"
#import "BrowserController.h"

@implementation BrowserTableView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    //[self setRightMouseLocation:BROWSER_TABLE_VIEW_INVALIDATED_ROW];

    // Drawing code here.
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Before this was done to ensure that the right click got the correct view.
    [(id<ParentProtocol>)[self delegate] updateFocus:self];
    [super rightMouseDown:theEvent];
}


- (void)keyDown:(NSEvent *)theEvent {
    NSString *key = [theEvent characters];
//    NSString *keyIM = [theEvent charactersIgnoringModifiers];
//    NSLog(@"KD: code:%@ - %@",key, keyIM);

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

//- (void)interpretKeyEvents:(NSArray *)eventArray {
//    NSLog(@"intrepret");
//    [super interpretKeyEvents:eventArray];
//}
//
//- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
//    NSLog(@"PKE: type:%lu code:%@",[theEvent type],[theEvent characters]);
//    return NO;
//}
//
//- (void)flagsChanged:(NSEvent *)theEvent {
//    NSLog(@"flagsChanged:");
//    [super flagsChanged:theEvent];
//}
//
- (void)cancelOperation:(id)sender {
    // clean the filter
    [[self delegate] performSelector:@selector(cancelOperation:) withObject:self];
    // and pass the cancel operation upwards anyway
    [super cancelOperation:sender];
}

//- (void) insertTab:(id)sender {
//    NSLog(@"insertTab:");
//}
//- (void)moveLeft:(id)sender {
//    NSLog(@"moveLeft");
//}

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
