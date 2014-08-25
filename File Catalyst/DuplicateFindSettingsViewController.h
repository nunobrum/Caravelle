//
//  DuplicateFindSettingsViewController.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 25/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DuplicateFindSettingsViewController : NSViewController
@property (strong) IBOutlet NSTableView *folderList;

@property (strong) IBOutlet NSButton *cbFileName;
@property (strong) IBOutlet NSButton *cbFileSize;
@property (strong) IBOutlet NSButton *cbFileContents;
@property (strong) IBOutlet NSButton *cbFileDate;

@property (strong) IBOutlet NSMatrix *rbGroupContents;
@property (strong) IBOutlet NSMatrix *rbGroupDates;


- (IBAction)addRemoveFolderButton:(id)sender;
- (IBAction)pbOKAction:(id)sender;
- (IBAction)pbCancelAction:(id)sender;

@end
