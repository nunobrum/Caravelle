/*
     File: SidebarTableCellView.h  
  
*/

#import <Cocoa/Cocoa.h>

@interface SidebarTableCellView : NSTableCellView {
@private
    NSButton *_button;
    NSTrackingRectTag trackingArea;
}

@property(retain) IBOutlet NSButton *button;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;

@end
