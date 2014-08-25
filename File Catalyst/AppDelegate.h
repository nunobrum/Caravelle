//
//  AppDelegate.h
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileCollection.h"
#import "BrowserController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSFileManagerDelegate> {
    //FileCollection *fileCollection;
    BrowserController *myLeftView;
    BrowserController *myRightView;
    //__weak LeftDataSource *_RightDataSrc;
    BOOL firstAppActivation;
}
@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextFieldCell *StatusBar;
@property (weak) IBOutlet NSToolbarItem *toolbarDeleteButton;
@property (weak) IBOutlet NSSplitView *ContentSplitView;
@property (weak) IBOutlet NSProgressIndicator *statusProgressIndicator;
@property (weak) IBOutlet NSTextField *statusProgressLabel;

@property (unsafe_unretained) IBOutlet NSWindow *myWindow;


//- (IBAction)LeftRootBrowse:(id)sender; // Add Directories to Left View
- (IBAction)RemoveSelected:(id)sender; // Remove Selected Items

- (IBAction)FindDuplicates:(id)sender;

- (IBAction)toolbarDelete:(id)sender;
- (IBAction)toolbarCatalystSwitch:(id)sender;

- (void) statusUpdate:(NSNotification*)theNotification;
- (void)   rootUpdate:(NSNotification*)theNotification;


@end
