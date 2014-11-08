//
//  CustomTableHeaderView.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "CustomTableHeaderView.h"

#ifdef COLUMN_NOTIFICATION
NSString *notificationColumnSelect = @"ColumnSelectNotification";
NSString *kReferenceViewKey = @"columnClicked";
NSString *kColumnChanged = @"columnChanged";
#endif

@implementation CustomTableHeaderView

@synthesize columnControl;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(void)columnSelect:(id)obj {
    NSString *menuTitle = [(NSMenuItem*)obj title];
    NSInteger menuState = [(NSMenuItem*)obj state];

    // Look up the column control structure to match by the title
    for (NSString *colID in [self columnControl]) {

        NSDictionary *colInfo = [[self columnControl] objectForKey:colID];
        NSString *colTitle = [colInfo objectForKey:COL_TITLE_KEY];

        if ([colTitle isEqualToString:menuTitle]) { // If matches
            NSNumber *colSelected = [NSNumber numberWithBool:(menuState==NSOnState)];
            [colInfo setValue:colSelected forKey:COL_SELECTED_KEY];
            NSNumber *colClicked = [NSNumber numberWithInteger:self->columnClicked];
            NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      colID, kColumnChanged,
                                      colClicked, kReferenceViewKey,
                                      nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationColumnSelect object:self userInfo:userinfo];
            break; // No need to continue
        }
    }
}


- (void)rightMouseDown:(NSEvent *)theEvent {
    /* This function creates a menu depending on the actual column selection */

    // Will store the clicked position, so that it is used to insert the new column (always to the right)
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    self->columnClicked = [self columnAtPoint: local_point];
    // Create the menu
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    int index=0;
    // Create an array of names sorted by alphabetic order
    NSArray *names = [[self columnControl] keysSortedByValueUsingComparator: ^(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 objectForKey:COL_TITLE_KEY ] localizedCompare:[obj2 objectForKey:COL_TITLE_KEY ]];
    }];

    // Creates the menu
    for (NSString *colID in names) {
        NSDictionary *colInfo = [[self columnControl] objectForKey:colID];
        NSString *desc = [colInfo objectForKey:COL_TITLE_KEY];
        [theMenu insertItemWithTitle:desc action:@selector(columnSelect:) keyEquivalent:@"" atIndex:index];
        if ([[colInfo objectForKey:COL_SELECTED_KEY] boolValue]) {
            [[theMenu itemAtIndex:index] setState:NSOnState];
        }
        else {
            [[theMenu itemAtIndex:index] setState:NSOffState];
        }
        index++;
    }
    // et voila' : add the menu to the vuew
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
}


@end
