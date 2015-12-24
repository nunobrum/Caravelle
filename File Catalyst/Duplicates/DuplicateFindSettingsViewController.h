//
//  DuplicateFindSettingsViewController.h
//  File Catalyst
//
//  Created by Nuno Brum on 25/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *notificationStartDuplicateFind;

@interface DuplicateFindSettingsViewController : NSWindowController

/*
 * General Pane
 */


@property (strong) IBOutlet NSButton *cbFileName;
@property (strong) IBOutlet NSButton *cbFileSize;
@property (strong) IBOutlet NSButton *cbFileContents;
@property (strong) IBOutlet NSButton *cbFileDate;

@property (strong) IBOutlet NSMatrix *rbGroupContents;
@property (strong) IBOutlet NSMatrix *rbGroupDates;
@property (strong) IBOutlet NSObjectController *objectController;

@property (strong) IBOutlet NSArrayController *pathContents;

/*
 * Filters Panel
 */
@property (weak) IBOutlet NSTextField *ebFilenameFilter;
@property (weak) IBOutlet NSTextField *ebMinimumFileSize;
@property (weak) IBOutlet NSComboBox *cbMinimumFileSizeUnit;
@property (weak) IBOutlet NSDatePicker *dpStartDateFilter;
@property (weak) IBOutlet NSDatePicker *dpEndDateFilter;



/*
 * Actions
 */

- (IBAction)addRemoveFolderButton:(id)sender;
- (IBAction)pbOKAction:(id)sender;
- (IBAction)pbCancelAction:(id)sender;

-(void) setPaths:(NSArray*) paths;

@end
