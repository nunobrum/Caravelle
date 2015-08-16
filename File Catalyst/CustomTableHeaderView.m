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


NSString* keyForFieldID(NSString* fieldID) {
    return  [[columnInfo() objectForKey:fieldID] objectForKey:COL_ACCESSOR_KEY];
}

id fieldOnItem(id object, NSString *fieldID) {
    NSString *prop_name = keyForFieldID(fieldID);
    id prop = nil;
    @try {
        prop = [object valueForKey:prop_name];
    }
    @catch (NSException *exception) {
        NSLog(@"Property '%@' not found", prop_name);
    }
    return prop;
}

NSString *transformerOnField(id field, NSString *fieldID) {
    NSString *trans_name = [[columnInfo() objectForKey:fieldID] objectForKey:COL_TRANS_KEY];
    if (trans_name) {
        NSValueTransformer *trans=[NSValueTransformer valueTransformerForName:trans_name];
        if (trans) {
            NSString *text = [trans transformedValue:field];
            if (text)
                return text;
            else
                NSLog(@"error transforming value");
        }
        else
            NSLog(@"invalid transformer");
    }
    else
        NSLog(@"no transformer found");
    return nil;
}

NSString *stringOnField(id object, NSString* fieldID) {
    id prop = fieldOnItem(object, fieldID);

    if (prop){
        if ([prop isKindOfClass:[NSString class]])
            return prop;
        else { // Need to use one of the NSValueTransformers
            return transformerOnField(prop, fieldID);
        }
    }
    return nil;
}


// Function used on the FileExistsChoice menu
NSDictionary *compareForField(id source, id dest, NSString *colKey, BOOL exclude_equals) {
    id src_field, dst_field;

    if ([colKey isEqualToString:@"COL_SIZE"]) { // Do not transform sizes
        src_field = fieldOnItem(source, colKey);
        dst_field = fieldOnItem(dest, colKey);
        if (exclude_equals && [src_field isEqualToNumber:dst_field]) {
            return nil;
        }
    }
    else {
        src_field = stringOnField(source, colKey);
        dst_field = stringOnField(dest, colKey);
        if (exclude_equals && [src_field isEqualToString:dst_field])
            return nil;
    }

    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         columnInfo()[colKey][COL_TITLE_KEY],@"name",
                         src_field,@"source",
                         dst_field,@"destination",
                         nil];
    return dic;
    
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
        if ([[columnInfo() objectForKey:[column identifier]] objectForKey:COL_GROUPING_KEY]!=nil) { // and can be grouped
            // TODO: !!!! Label the item ungroup when the field is already being groupped.
            NSString *itemTitle = [NSString stringWithFormat:@"Group using %@", clickedColumnText];
            [theMenu addItemWithTitle:itemTitle action:@selector(groupSelect:) keyEquivalent:@""];

            // Adding a menu divider
            NSMenuItem *sep = [NSMenuItem separatorItem];
            [sep setTitle:@"Columns"];
            [theMenu addItem:sep];
        }
    }
    // Creates the Columns Menu
    for (NSString *colID in sortedColumnNames() ) {
        NSDictionary *colInfo = [columnInfo() objectForKey:colID];
        
        // Restraining columns that do not belong in this mode
        NSNumber *app_mode = [colInfo objectForKey:COL_APP_MODE];
        if (app_mode != nil) {
            if (([app_mode longValue] & applicationMode) == 0)
            continue; // This blocks Columns that are not to be displayed in the current mode.
        }
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
