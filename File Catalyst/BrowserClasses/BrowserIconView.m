//
//  BrowserIconView.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserIconView.h"
#import "Definitions.h"

@implementation BrowserIconView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
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


@end
