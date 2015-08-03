//
//  BrowserTableView.m
//  File Catalyst
//
//  Created by Nuno Brum on 08/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserTableView.h"
#import "BrowserController.h"

@implementation BrowserTableView {
    //BOOL blockServices;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    //[self setRightMouseLocation:BROWSER_TABLE_VIEW_INVALIDATED_ROW];

    // Drawing code here.
}

-(IBAction)groupContextSelect:(id)sender {
    [[self delegate] performSelector:@selector(groupContextSelect:) withObject:sender];
}

// This is needed to update screen information
-(void) mouseDown:(NSEvent *)theEvent {
    [(id<ParentProtocol>)[self delegate] updateFocus:self];
    [super mouseDown:theEvent];
}

-(void) rightMouseDown:(NSEvent *)theEvent {
    // Before this was done to ensure that the right click got the correct view.
    [(id<ParentProtocol>)[self delegate] contextualFocus:self];

    /* This function creates a menu depending on the actual column selection */
    // Will store the clicked position, so that it is used to insert the new column (always to the right)
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    _rightClickedRow = [self rowAtPoint:local_point];
    if (_rightClickedRow != -1) {
        NSString *identifier = [[self viewAtColumn:0 row:_rightClickedRow makeIfNecessary:YES] identifier];
        NSLog(@"Identifier %@", identifier);
        if ([identifier isEqualToString:ROW_GROUP]) {
            
            // Load the menu
            NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
            [theMenu addItemWithTitle:@"Sort Ascending" action:@selector(groupContextSelect:) keyEquivalent:@""];
            [theMenu addItemWithTitle:@"Sort Descending" action:@selector(groupContextSelect:) keyEquivalent:@""];
            [theMenu addItemWithTitle:@"Remove Grouping" action:@selector(groupContextSelect:) keyEquivalent:@""];

            // Number the items for later processing
            // The number is consisten with the defines in the header file.
            // GROUP_SORT_ASCENDING  0
            // GROUP_SORT_DESCENDING 1
            // GROUP_SORT_REMOVE     2
            NSInteger i = 0;
            for (NSMenuItem *item in [theMenu itemArray])
                [item setTag:i++];

            // Make sure that no services menu is added to the menu
            //blockServices = YES;

            // et voila' : add the menu to the view
            [theMenu setAllowsContextMenuPlugIns:NO];
            [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
            return; // Block the other menu
        }
    }
    //blockServices = NO;
    [super rightMouseDown:theEvent];
}



- (void)keyDown:(NSEvent *)theEvent {
    NSString *key = [theEvent characters];
//    NSString *keyIM = [theEvent charactersIgnoringModifiers];
    unichar keyCode = [key characterAtIndex:0];
    //NSLog(@"KD: code:%@ - %hu",key, keyCode);

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
    /* if (([theEvent modifierFlags] & NSCommandKeyMask) &&
     keyCode == KeyCodeLeft ||
     keyCode == KeyCodeRight)
     // TODO:1.6 In the future this will rather "transport" the selected items to the view on the right (if exists)
     // The concept of transport mode needs to be further defined.
     */
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
    //[super cancelOperation:sender];
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


// TODO:!!! Handle here the menus, in order to have an uniform Menu Generation. 


/* The menu handling is forwarded to the Delegate.
 For the contextual Menus the selection is different, than for the application */
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    /*if (blockServices)
        return nil;
    else*/
        return [(id<MYViewProtocol>)[self delegate] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    return [(id<MYViewProtocol>)[self delegate] writeSelectionToPasteboard:pboard types:types];
}

@end
