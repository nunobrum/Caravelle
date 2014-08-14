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

NSString *notificationCatalystRootUpdate=@"RootUpdate";
NSString *catalystRootUpdateNotificationPath=@"RootUpdatePath";


@implementation AppDelegate {
    NSArray *selectedFiles;
    id  selectedView;
}


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
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myLeftView];
    [center addObserver:self selector:@selector(rootUpdate:) name:notificationCatalystRootUpdate object:myRightView];

    if ([myLeftView isKindOfClass:[BrowserController class]]) {
        [myLeftView setCatalystMode:YES];
        [myLeftView setFoldersDisplayed:YES];
        //[myLeftView setParent:self];
    }
    if ([myRightView isKindOfClass:[BrowserController class]]) {
        [myRightView setCatalystMode:NO];
        [myRightView setFoldersDisplayed:YES];
        //[myRightView setParent:self];
    }

    [_ContentSplitView addSubview:myLeftView.view];
    [_ContentSplitView addSubview:myRightView.view];


    //[_chkMP3_ID setEnabled:NO];
    //[_chkPhotoEXIF setEnabled:NO];
    //[_pbRemove setEnabled:NO];
    firstAppActivation = YES;

}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    if (firstAppActivation == YES) {
        firstAppActivation = NO;
        NSString *homeDir = NSHomeDirectory();
        [self DirectoryScan: homeDir to:myLeftView];
        [(BrowserController*)myRightView addTreeRoot: [TreeRoot treeWithURL:[NSURL URLWithString:homeDir]]];
        [_StatusBar setTitle:@"Done!"];

    }
    /* Ajust the subView window Sizes */
    [_ContentSplitView adjustSubviews];
    [_ContentSplitView setNeedsDisplay:YES];

}


-(void) DirectoryScan:(NSString*)rootPath to:(BrowserController*) BrowserView {
    FileCollection *fileCollection_inst = [[FileCollection new] init];
    [fileCollection_inst addFilesInDirectory:rootPath callback:^(NSInteger fileno) {
        [_StatusBar setTitle:@"Scanning..."];
    }];
    TreeRoot *root = [TreeRoot treeWithFileCollection:fileCollection_inst callback:^(NSInteger fileno) {
        // Put Code here
        [_StatusBar setTitle:@"Adding Files to Tree..."];
    }];
    [BrowserView addTreeRoot:root];
    [_StatusBar setTitle:@"Done!"];
}

- (void) rootUpdate:(NSNotification*)theNotification {
    NSDictionary *receivedData = [theNotification userInfo];
    NSString *rootPath = [[receivedData objectForKey:catalystRootUpdateNotificationPath] path];
    BrowserController *BrowserView = [theNotification object];
    /* In a normal mode the Browser only has one Root */
    [BrowserView removeRootWithIndex:0];
    [self DirectoryScan:rootPath to:BrowserView];
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
    TreeRoot *root = [TreeRoot treeWithFileCollection:duplicates callback:^(NSInteger fileno) {
        // Put Code here
        //[[self StatusText] setIntegerValue:fileno];
    }];
    [(BrowserController*)myLeftView addTreeRoot:root];

    [(BrowserController*)myLeftView refreshTrees];
    [_toolbarDeleteButton setEnabled:NO];
    
    //[_LeftOutlineView setDataSource:_LeftDataSrc];
    //[_LeftOutlineView reloadItem:nil reloadChildren:YES];
}


- (void) statusUpdate:(NSNotification*)theNotification {
    NSString *statusText;
    NSDictionary *receivedData = [theNotification userInfo];
    selectedFiles = [receivedData objectForKey:selectedFilesNotificationObject];
    selectedView = [theNotification object];
    if (selectedFiles != nil) {
        NSInteger num_files=0;
        NSInteger total_size=0;
        NSInteger num_directories=0;
        for (TreeItem *item in selectedFiles ) {
            if ([item isKindOfClass:[TreeLeaf class]]) {
                num_files++;
                total_size += [(TreeLeaf*)item byteSize];
            }
            else if ([item isKindOfClass:[TreeBranch class]]) {
                num_directories++;
                total_size += [item byteSize];
            }
        }
        if ([selectedFiles count]==0) {
            statusText = [NSString stringWithFormat:@"Ready"];
        }
        else {
            NSString *sizeText = [NSByteCountFormatter stringFromByteCount:total_size countStyle:NSByteCountFormatterCountStyleFile];
            statusText = [NSString stringWithFormat:@"%lu Files, %lu Directories, Total Size %@", num_files, num_directories, sizeText];
        }
        [_StatusBar setTitle: statusText];
    }
    else {
        [_StatusBar setTitle: @"Ooops! Received Notification without User Info"];
    }
}


@end
