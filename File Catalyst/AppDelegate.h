//
//  AppDelegate.h
//  Caravelle
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "FileCollection.h"
#import "BrowserController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSFileManagerDelegate, NSTextFieldDelegate, ParentProtocol> {
    //FileCollection *fileCollection;
    BrowserController *myLeftView;
    BrowserController *myRightView;
    id<MYViewProtocol> _selectedView;
    //__weak LeftDataSource *_RightDataSrc;
}
@property (unsafe_unretained) IBOutlet NSWindow *myWindow;
@property (weak) IBOutlet NSTextFieldCell *StatusBar;
@property (weak) IBOutlet NSSplitView *ContentSplitView;
@property (weak) IBOutlet NSProgressIndicator *statusProgressIndicator;
@property (weak) IBOutlet NSTextField *statusProgressLabel;
@property (weak) IBOutlet NSButton *buttonCopyTo;
@property (weak) IBOutlet NSButton *buttonMoveTo;

@property (weak) IBOutlet NSButton *statusCancelButton;

- (IBAction)FindDuplicates:(id)sender;

/* Toolbar Actions */
- (IBAction)toolbarInformation:(id)sender;
- (IBAction)contextualInformation:(id)sender;

- (IBAction)toolbarRename:(id)sender;
- (IBAction)contextualRename:(id)sender;

- (IBAction)toolbarDelete:(id)sender;
- (IBAction)contextualDelete:(id)sender;

- (IBAction)toolbarCopyTo:(id)sender;
- (IBAction)contextualCopyTo:(id)sender;

- (IBAction)toolbarMoveTo:(id)sender;
- (IBAction)contextualMoveTo:(id)sender;

- (IBAction)toolbarOpen:(id)sender;
- (IBAction)contextualOpen:(id)sender;

- (IBAction)toolbarNewFolder:(id)sender;
- (IBAction)contextualNewFolder:(id)sender;

- (IBAction)toolbarGotoFolder:(id)sender;

- (IBAction)toolbarSearch:(id)sender;
- (IBAction)toolbarGrouping:(id)sender;
- (IBAction)toolbarRefresh:(id)sender;
- (IBAction)toolbarHome:(id)sender;


- (IBAction)operationCancel:(id)sender;

- (IBAction)orderPreferencePanel:(id)sender;

- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;

- (IBAction)copyName:(id)sender ;
- (IBAction)contextualCopyName:(id)sender ;

- (IBAction)appModeChanged:(id)sender;


@end
