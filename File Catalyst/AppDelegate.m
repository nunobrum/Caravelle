//
//  AppDelegate.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "AppDelegate.h"
#import "FileCollection.h"
#import "TreeLeaf.h"

#include "Definitions.h"

NSString *notificationStatusUpdate=@"StatusUpdateNotification";
NSString *selectedFilesNotificationObject=@"FilesSelected";


@implementation AppDelegate


// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (NSString *)windowNibName {
    return @"File Catalyst";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // Insert code here to initialize your application
    myLeftView  = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
    myRightView = [[BrowserController alloc] initWithNibName:@"BrowserView" bundle:nil ];
    [myLeftView initController];
    [myRightView initController];
    
    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myLeftView];

    [center addObserver:self selector:@selector(statusUpdate:) name:notificationStatusUpdate object:myRightView];


    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [myLeftView setCatalystMode:YES];
        [myLeftView setFoldersDisplayed:YES];
    }

    [_ContentSplitView addSubview:myLeftView.view];
    [_ContentSplitView addSubview:myRightView.view];

    //[_chkMP3_ID setEnabled:NO];
    //[_chkPhotoEXIF setEnabled:NO];
    //[_pbRemove setEnabled:NO];
 
    [self DirectoryScan: @"/Users/vika"];
    //[self DirectoryScan: @"/"];

}


-(void)DirectoryScan:(NSString*)rootPath {
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
    FileCollection *fileCollection_inst = nil;
    NSInteger canAdd = [(BrowserController*)myLeftView canAddRoot:rootPath];
    
    if (rootCanBeInserted==canAdd) {
        if ([(BrowserController*)myLeftView getCatalystMode ]==YES) {
            if (nil==fileCollection_inst)
                fileCollection_inst = [[FileCollection new] init];
        
            [fileCollection_inst addFilesInDirectory:rootPath callback:^(NSInteger fileno) {
            //[[self StatusText] setIntegerValue:fileno];
            }];
            [(BrowserController*)myLeftView addWithFileCollection:fileCollection_inst callback:^(NSInteger fileno) {
            //[[self StatusText] setIntegerValue:fileno];
            }];
        }
        else { // Will only add the Root

            [(BrowserController*)myLeftView addWithRootPath:[NSURL URLWithString: rootPath]];
        }
        [(BrowserController*)myLeftView refreshTrees];
        // This is important so that the Table is correctly refreshed
        [_toolbarDeleteButton setEnabled:NO];
    }
    //[pool release];
}

- (IBAction)toolbarDelete:(id)sender {
    NSLog(@"Menu Delete clicked");
}

- (IBAction)toolbarCatalystSwitch:(id)sender {
}


- (IBAction)RemoveDirectory:(id)sender {
    [(BrowserController*)myLeftView removeSelectedDirectory];
    [_toolbarDeleteButton setEnabled:NO];
}


//- (IBAction)LeftRootBrowse:(id)sender {
//
//    //NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG";
//    //NSArray *     types = [extensions pathComponents];
//    
//	// Let the user choose an output file, then start the process of writing samples
//	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    //[openPanel setAllowedFileTypes:types];
//	//[openPanel setCanSelectHiddenExtension:NO];
//    [openPanel setCanChooseDirectories:YES];
//    [openPanel setCanChooseFiles:NO];
//    [openPanel setPrompt:@"Add"];
//
//
//	[openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
//        if (result == NSFileHandlingPanelOKButton)
//        {
//            // user did select an directory...
//            NSString *RootPath = [[openPanel URL] path];
//            [self performSelectorOnMainThread:@selector(DirectoryScan:) withObject:RootPath waitUntilDone:NO];
//            //[NSThread detachNewThreadSelector:@selector(ButtonClick:) toTarget:self withObject:nil]
//            
//
//        }
//    }];
//}



- (IBAction)FindDuplicates:(id)sender {
    comparison_options_t options;
    FileCollection *duplicates;
    FileCollection *collection = [(BrowserController*)myLeftView concatenateAllCollections];
    // This will eliminate any results from previous searches
    [collection resetDuplicateLists];
    
    //Sets all options to FALSE;
    memset(&options,0,sizeof(comparison_options_t));
    
//    options.names = [_chkFilename state];
//    options.contents = [_chkContents state];
//    options.sizes = [_chkSize state];
//    options.dates = [_chkModifiedDate state];
//    options.mp3_id3 = [_chkMP3_ID state];
//    options.photo_exif = [_chkPhotoEXIF state];
    
    duplicates = [collection findDuplicates:options];

    [(BrowserController*)myLeftView addWithFileCollection:duplicates callback:^(NSInteger fileno) {
        //[[self StatusText] setIntegerValue:fileno];
    }];

    [(BrowserController*)myLeftView refreshTrees];
    [_toolbarDeleteButton setEnabled:NO];
    
    //[_LeftOutlineView setDataSource:_LeftDataSrc];
    //[_LeftOutlineView reloadItem:nil reloadChildren:YES];
}


- (void) statusUpdate:(NSNotification*)theNotification {
    NSDictionary *receivedData = [theNotification userInfo];
    NSArray *selectedFiles = [receivedData objectForKey:selectedFilesNotificationObject];
    if (selectedFiles != nil) {
        NSString *statusText = [NSString stringWithFormat:@"Selection Count %lu", (unsigned long)[selectedFiles count]];
        [_StatusBar setTitle: statusText];
    }
    else {
        [_StatusBar setTitle: @"Received Notification without User Info"];
    }
}


@end
