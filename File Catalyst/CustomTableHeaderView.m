//
//  CustomTableHeaderView.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "CustomTableHeaderView.h"
#import "TableViewController.h"

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

// Create an array of names sorted by alphabetic order
NSArray* sortedColumnNames() {
    static NSArray *sortedNames=nil;
    if (sortedNames==nil) {
        sortedNames = [columnInfo() keysSortedByValueUsingComparator: ^(NSDictionary *obj1, NSDictionary *obj2) {
            return [[obj1 objectForKey:COL_TITLE_KEY ] localizedCompare:[obj2 objectForKey:COL_TITLE_KEY ]];
        }];
    }
    return sortedNames;
}


NSString* keyForColID(NSString* colID) {
    if ([colID isEqualToString:COL_FILENAME])
        return @"name";
    else // Else uses the identifier that is linked to the treeItem KVO property
        return  [[columnInfo() objectForKey:colID] objectForKey:COL_ACCESSOR_KEY];
}

@implementation CustomTableHeaderView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Blocks the system menu
    [NSApp registerServicesMenuSendTypes:nil
                             returnTypes:nil];
}


-(void)columnSelect:(id)obj {
    NSString *colID = [(NSMenuItem*)obj representedObject];
    NSNumber *colClicked = [NSNumber numberWithInteger:self->columnClicked];
    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              colID, kColumnChanged,
                              colClicked, kReferenceViewKey,
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationColumnSelect object:self userInfo:userinfo];
}

-(void) groupSelect:(id) object {
    //NSLog(@"Send notification for start group");
    NSNumber *colClicked = [NSNumber numberWithInteger:self->columnClicked];
    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              colClicked, kReferenceViewKey,
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationColumnSelect object:self userInfo:userinfo];

}

- (void)rightMouseDown:(NSEvent *)theEvent {
    /* This function creates a menu depending on the actual column selection */

    // Will store the clicked position, so that it is used to insert the new column (always to the right)
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    self->columnClicked = [self columnAtPoint: local_point];
    // Create the menu
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];

    // Adding grouping action
    NSArray *columns = [[self tableView] tableColumns];
    if (self->columnClicked < [columns count]) {
        NSTableColumn *column = [columns objectAtIndex:self->columnClicked];
        NSString *clickedColumnText = [[column headerCell] stringValue];

        // Column Names cannot be groupped
        if (NO == [[column identifier] isEqualToString:COL_FILENAME]) {
            // TODO: !!! Make the ungroup when the field is already being groupped.
            NSString *itemTitle = [NSString stringWithFormat:@"Group using %@", clickedColumnText];
            [theMenu addItemWithTitle:itemTitle action:@selector(groupSelect:) keyEquivalent:@""];

            // Adding a menu divider
            NSMenuItem *sep = [NSMenuItem separatorItem];
            [sep setTitle:@"Columns"];
            [theMenu addItem:sep];
        }
    }
    // Creates the Columns Mmenu
    for (NSString *colID in sortedColumnNames() ) {
        NSDictionary *colInfo = [columnInfo() objectForKey:colID];
        NSString *desc = [colInfo objectForKey:COL_TITLE_KEY];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:desc action:@selector(columnSelect:) keyEquivalent:@""];
        if ([[self tableView] columnWithIdentifier:colID]!=-1) { // is present in tableColumns
            [menuItem setState:NSOnState];
        }
        else {
            [menuItem setState:NSOffState];
        }
        [menuItem setRepresentedObject:colID];
        [theMenu addItem:menuItem];
    }

    // Blocks the Services Menu
    [theMenu setAllowsContextMenuPlugIns:NO];
    // et voila' : add the menu to the view
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
}


// This method is here so that service menu is blocked in the column headers
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType {
    return nil;
}

@end
