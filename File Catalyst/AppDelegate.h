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
}
@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextFieldCell *StatusBar;
@property (weak) IBOutlet NSSplitView *ContentSplitView;
@property (weak) IBOutlet NSProgressIndicator *statusProgressIndicator;
@property (weak) IBOutlet NSTextField *statusProgressLabel;

@property (unsafe_unretained) IBOutlet NSWindow *myWindow;
@property (weak) IBOutlet NSButton *statusCancelButton;

- (IBAction)FindDuplicates:(id)sender;


/* Toolbar Actions */
- (IBAction)toolbarDelete:(id)sender;
- (IBAction)toolbarCopy:(id)sender;
- (IBAction)toolbarMove:(id)sender;

- (IBAction)operationCancel:(id)sender;

- (void) statusUpdate:(NSNotification*)theNotification;
- (void)   rootUpdate:(NSNotification*)theNotification;


@end
