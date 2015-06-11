//
//  BrowserIconView.m
//  Caravelle
//
//  Created by Nuno Brum on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserIconView.h"
#import "Definitions.h"
#import "IconViewController.h"

@implementation BrowserIconView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(IconViewBox*) iconForEvent:(NSEvent*) theEvent {
    NSPoint xy =[theEvent locationInWindow];
    NSPoint x1y1 = [self convertPoint:xy fromView:nil];
    NSView *view = [self hitTest:x1y1];
    if ([view isKindOfClass:[IconViewBox class]])
        return (IconViewBox*)view;
    else
        return nil;
}

-(IconViewBox*) lastClick {
    return self->_lastClick;
}

- (IBAction)mouseDown:(NSEvent *)theEvent {
    self->_lastClick = [self iconForEvent:theEvent];
    if([theEvent clickCount] > 1) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(doubleClick:)]) {
            [(IconViewController*)self.delegate doubleClick:self->_lastClick];
        }
    }
    else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(lastClick:)]) {
            [(IconViewController*)self.delegate lastClick:self->_lastClick];
        }
    }
    [super mouseDown:theEvent];
    
}

- (IBAction)rightMouseDown:(NSEvent *)theEvent {
    self->_lastClick = [self iconForEvent:theEvent];
    if(self.delegate && [self.delegate respondsToSelector:@selector(lastClick:)]) {
        [(IconViewController*)self.delegate lastClick:self->_lastClick];
    }
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

-(IconViewBox*) iconWithItem:(id) item {
    for (IconViewBox *icon in [self subviews]) {
        if ([[icon representedObject] isEqual:item])
            return icon;
    }
    return nil;
}

- (void)cancelOperation:(id)sender {
    // clean the filter
    [[self delegate] performSelector:@selector(cancelOperation:) withObject:self];
    // and pass the cancel operation upwards anyway
    //[super cancelOperation:sender];
}

- (BOOL)becomeFirstResponder {
    // Highlight the selections
    for (IconViewBox *icon in [self subviews]) {
        [icon setFillColor:[NSColor alternateSelectedControlColor]];
    }
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    // Set selected fill color to grey
    for (IconViewBox *icon in [self subviews]) {
        [icon setFillColor:[NSColor secondarySelectedControlColor]];
    }
    return[super resignFirstResponder];
}
@end
