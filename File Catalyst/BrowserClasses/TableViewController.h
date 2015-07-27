//
//  TableViewController.h
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NodeViewController.h"
#import "CustomTableHeaderView.h"
#import "SizeTableCellView.h"
#import "BrowserTableView.h"

@interface TableViewController : NodeViewController <NodeViewProtocol, NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet BrowserTableView *myTableView;

@property (strong) IBOutlet CustomTableHeaderView *myTableViewHeader;
@property (strong) IBOutlet NSProgressIndicator *myProgressIndicator;

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
- (IBAction)TableDoubleClickEvent:(id)sender;
- (IBAction)filenameDidChange:(id)sender;
-(void) initController;

-(void) setupColumns:(NSArray*) columns;
-(NSArray*) columns;

-(void) loadPreferencesFrom:(NSDictionary*) preferences;
-(NSDictionary*) savePreferences;

@end
