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


NSDictionary *columnInfo () {
    static NSDictionary *columnInfo = nil;
    if (columnInfo==nil) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AvailableColumns" ofType:@"plist"];
        columnInfo = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    return columnInfo;
}

@implementation CustomTableHeaderView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Blocks the system menu
    [NSApp registerServicesMenuSendTypes:nil
                             returnTypes:nil];
}
// Create an array of names sorted by alphabetic order
-(NSArray*) sortedNames {
    static NSArray *sortedNames=nil;
    if (sortedNames==nil) {
    sortedNames = [columnInfo() keysSortedByValueUsingComparator: ^(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 objectForKey:COL_TITLE_KEY ] localizedCompare:[obj2 objectForKey:COL_TITLE_KEY ]];
    }];
    }
    return sortedNames;
}


-(void)columnSelect:(id)obj {
    NSString *menuTitle = [(NSMenuItem*)obj title];

    // Look up the column control structure to match by the title
    for (NSString *colID in columnInfo()) {

        NSDictionary *colInfo = [columnInfo() objectForKey:colID];
        NSString *colTitle = [colInfo objectForKey:COL_TITLE_KEY];

        if ([colTitle isEqualToString:menuTitle]) { // If matches
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

    // Creates the menu
    for (NSString *colID in [self sortedNames]) {
        NSDictionary *colInfo = [columnInfo() objectForKey:colID];
        NSString *desc = [colInfo objectForKey:COL_TITLE_KEY];
        [theMenu insertItemWithTitle:desc action:@selector(columnSelect:) keyEquivalent:@"" atIndex:index];
        if ([[self tableView] columnWithIdentifier:colID]!=-1) { // is present in tableColumns
            [[theMenu itemAtIndex:index] setState:NSOnState];
        }
        else {
            [[theMenu itemAtIndex:index] setState:NSOffState];
        }
        index++;
    }

    // et voila' : add the menu to the view
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
}


@end
