//
//  TableViewController.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CustomTableHeaderView.h"
#import "BrowserTableView.h"

@interface TableViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet BrowserTableView *myTableView;

@property (strong) IBOutlet CustomTableHeaderView *myTableViewHeader;


/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
/*
 * Table Data Delegate Protocol
 */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
/* Binding is done manually in the initialization procedure */
- (IBAction)OutlineDoubleClickEvent:(id)sender;
- (IBAction)TableDoubleClickEvent:(id)sender;


@end
