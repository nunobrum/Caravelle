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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    //NSWindowController *startupWindow = [[[StartupWindowController class] alloc] init];
    //[startupWindow showWindow:self];
    fileCollection = [[FileCollection new] init];
    _LeftDataSrc = [[LeftDataSource new] init];
    [_LeftDataSrc setCatalystMode:NO];
    // Sets the Outline view so that the File display can work
    [_LeftDataSrc setTreeOutlineView:_LeftOutlineView];
    //[_RightDataSrc setTreeOutlineView:_RightOutlineView];

    [_LeftTableView setDataSource:_LeftDataSrc];
    [_LeftTableView setDelegate:_LeftDataSrc];
    
    //[_RightDataSrc setTreeOutlineView:_RightOutlineView];
    //[_RightDataSrc setDisplayFilesInSubdirs:YES];
    //[_RightDataSrc setFoldersDisplayed:NO];
    //[_RightOutlineView setDataSource:_RightDataSrc];
    //[_RightTableView setDataSource:_RightDataSrc];
    //[_RightTableView setDelegate:_RightDataSrc];
    //[_chkMP3_ID setEnabled:NO];
    //[_chkPhotoEXIF setEnabled:NO];
    //[_pbRemove setEnabled:NO];
    [_LeftTableView setDoubleAction:@selector(TableDoubleClickEvent:)];

    [self DirectoryScan: @"/Users/vika/Documents"];
    
}


-(void)DirectoryScan:(NSString*)rootPath {
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
    FileCollection *fileCollection_inst = nil;
    NSInteger canAdd = [_LeftDataSrc canAddRoot:rootPath];
    
    if (rootCanBeInserted==canAdd) {
        [_LeftPathRoot setURL:[NSURL URLWithString:rootPath]];
        if ([_LeftDataSrc getCatalystMode ]==YES) {
            if (nil==fileCollection_inst)
                fileCollection_inst = [[FileCollection new] init];
        
            [fileCollection_inst addFilesInDirectory:rootPath callback:^(NSInteger fileno) {
            //[[self StatusText] setIntegerValue:fileno];
            }];
            [_LeftDataSrc addWithFileCollection:fileCollection_inst callback:^(NSInteger fileno) {
            //[[self StatusText] setIntegerValue:fileno];
            }];
        }
        else { // Will only add the Root

            [_LeftDataSrc addWithRootPath:[NSURL URLWithString: rootPath]];
        }
        [_LeftDataSrc refreshTrees];
        // This is important so that the Table is correctly refreshed
        [_LeftOutlineView reloadItem:nil reloadChildren:YES];
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
    // gets the selected item
    NSInteger fileSelected = [_LeftOutlineView selectedRow];
    NSInteger level = [_LeftOutlineView levelForRow:fileSelected];
    // then finds the corresponding item
    //id item = [_LeftOutlineView itemAtRow:fileSelected];
     NSLog(@"Item Number %ld Level %ld", fileSelected, level);
    //If it is a root 
    if (level==0) {
        // Will delete the tree Root and sub Directories
        NSLog(@"Super !!!! This is the root class");
        [_LeftDataSrc removeRootWithIndex:fileSelected];
        // Redraws the outline view
        [_LeftOutlineView reloadItem:nil reloadChildren:YES];
        [_toolbarDeleteButton setEnabled:NO];
    }
    else {
        // Will send the corresponding file to recycle bin
        // To be implemented
        
    }
    //NSLog(@"The class is %@", [item classDescription]);
}


- (IBAction)LeftRootBrowse:(id)sender {
    
    //NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG";
    //NSArray *     types = [extensions pathComponents];
    
	// Let the user choose an output file, then start the process of writing samples
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    //[openPanel setAllowedFileTypes:types];
	//[openPanel setCanSelectHiddenExtension:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Add"];

    
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
}


//- (IBAction)ScanStart:(id)sender {
//    NSLog(@"Scan Start was pushed");
//   [_LeftDataSrc refreshTrees];
//}


- (IBAction)FindDuplicates:(id)sender {
    comparison_options_t options;
    FileCollection *duplicates;
    FileCollection *collection = [_LeftDataSrc concatenateAllCollections];
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

    [_LeftDataSrc addWithFileCollection:duplicates callback:^(NSInteger fileno) {
        //[[self StatusText] setIntegerValue:fileno];
    }];


    [_LeftOutlineView setDataSource:_LeftDataSrc];
    [_LeftOutlineView reloadItem:nil reloadChildren:YES];
    [_toolbarDeleteButton setEnabled:NO];
    
    //[_LeftOutlineView setDataSource:_LeftDataSrc];
    //[_LeftOutlineView reloadItem:nil reloadChildren:YES];
}


- (IBAction)TableSelector:(id)sender {
    NSLog(@"Table Selector");
    if (sender==_LeftOutlineView) {
/*        NSInteger fileSelected = [_LeftOutlineView selectedRow];
        NSInteger level = [_LeftOutlineView levelForRow:fileSelected];
        // then finds the corresponding item
        id item = [_LeftOutlineView itemAtRow:fileSelected];
        if ([item isKindOfClass:[TreeBranch class]]==YES) {
            FileCollection *duplicatesForSelected = [(TreeBranch*)item duplicatesInBranch];
            [_RightDataSrc removeRootWithIndex:0];
            [_RightDataSrc addWithFileCollection:duplicatesForSelected callback:^(NSInteger fileno) {
                //[[self StatusText] setIntegerValue:fileno];
            }];
            
            
        }
        else if ([item isKindOfClass:[TreeLeaf class]]==YES){
            FileCollection *duplicatesForSelected = [[FileCollection new] init];
            [duplicatesForSelected addFiles:[[(TreeLeaf*)item getFileInformation] duplicateList]];
            [_RightDataSrc removeRootWithIndex:0];
            [_RightDataSrc addWithFileCollection:duplicatesForSelected callback:^(NSInteger fileno) {
                //[[self StatusText] setIntegerValue:fileno];
            }];
        }
        //[_RightOutlineView reloadItem:nil reloadChildren:YES]; */
        [_LeftTableView reloadData];
        //[_RightTableView reloadData];
    }
    else if(sender == _LeftTableView) {
        NSIndexSet *rowsSelected = [_LeftTableView selectedRowIndexes];
        if ([rowsSelected count]==0) {// No file is selected
            // Update toolbar
            [_toolbarDeleteButton setEnabled:NO];
            [_StatusBar setTitle: @"No File Selected"];
        }
        else {
            NSInteger index = [rowsSelected firstIndex];
            id node = [_LeftDataSrc getFileAtIndex:index];
            if ([rowsSelected count]==1) {
                // Will set a preview, if requested
                if ([node isKindOfClass:[TreeBranch class]]) {
                    // Its a directory
                    
                    [_StatusBar setTitle: @"One Directory"];
                }
                else if ([node isKindOfClass:[TreeLeaf class]]) {
                
                    [_StatusBar setTitle: @"One File"];
                }
            }
            else { // Many Files are selected
                //[_toolbarDeleteButton setEnabled:YES];
                while (index!=NSNotFound) {
                    /* Do something here */
                    NSLog(@"Selected %lu", (unsigned long)index);
                    index = [rowsSelected indexGreaterThanIndex:index];
                }
            }
        }
    }
}


- (IBAction)LeftOutlineCellSelector:(id)sender {
    NSLog(@"Left Outline Cell Selector");

}

/* This action is associated manually with the setDoubleAction */
- (IBAction)TableDoubleClickEvent:(id)sender {
    if(sender == _LeftTableView) {
        NSIndexSet *rowsSelected = [_LeftTableView selectedRowIndexes];
        NSUInteger index = [rowsSelected firstIndex];
        while (index!=NSNotFound) {
            /* Do something here */
            id node =[_LeftDataSrc getFileAtIndex:index];
            if ([node isKindOfClass: [TreeLeaf class]]) { // It is a file : Open the File
                [[node getFileInformation] openFile];
            }
            else if ([node isKindOfClass: [TreeBranch class]]) { // It is a directory
                // Going to open the Select That directory o	n the Outline View
                int retries = 2;
                while (retries) {
                    NSInteger row = [_LeftOutlineView rowForItem:node];
                    if (row!=-1) {
                        [_LeftOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                        retries = 0; // Finished, dont need to retry any more.
                    }
                    else {
                        // The object was not found, will need to force the expand
                        [_LeftOutlineView expandItem:[_LeftOutlineView itemAtRow:[_LeftOutlineView selectedRow]]];
                        [_LeftOutlineView reloadData];
                        retries--;
                    }
                }
                [_LeftTableView reloadData];
            }
            index = [rowsSelected indexGreaterThanIndex:index];
        }
    }
}

@end
