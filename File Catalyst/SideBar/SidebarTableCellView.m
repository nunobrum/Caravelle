/*
     File: SidebarTableCellView.m 
*/

#import "SidebarTableCellView.h"


@implementation SidebarTableCellView

@synthesize button = _button;

- (void)awakeFromNib {
    // We want it to appear "inline"
    [[self.button cell] setBezelStyle:NSInlineBezelStyle];
    trackingArea = [self addTrackingRect:self.bounds owner:self userData:nil assumeInside:NO];
}


// The standard rowSizeStyle does some specific layout for us. To customize layout for our button, we first call super and then modify things
- (void)viewWillDraw {
    [self removeTrackingRect:trackingArea];
    [super viewWillDraw];
//    if (![self.button isHidden]) {
//        [self.button sizeToFit];
//        NSRect textFrame = self.textField.frame;
//        NSRect buttonFrame = self.button.frame;
//        buttonFrame.origin.x = NSWidth(self.frame) - NSWidth(buttonFrame);
//        self.button.frame = buttonFrame;
//        textFrame.size.width = NSMinX(buttonFrame) - NSMinX(textFrame);
//        self.textField.frame = textFrame;
//    }
    
    trackingArea = [self addTrackingRect:self.bounds owner:self userData:nil assumeInside:NO];
}

-(void) mouseEntered:(NSEvent *)theEvent {
    [self.button setHidden:NO];
}

-(void) mouseExited:(NSEvent *)theEvent {
    [self.button setHidden:YES];
}


@end
