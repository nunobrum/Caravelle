//
//  BrowserController.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomTableHeaderView.h"
#import "BrowserTableView.h"
#import "BrowserOutlineView.h"
#import "FileCollection.h"
#import "TreeRoot.h"
#include "Definitions.h"

extern NSString *notificationStatusUpdate;


extern NSString *notificationCatalystRootUpdate;


@interface BrowserController : NSViewController <NSOutlineViewDataSource, NSTableViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate, MYViewProtocol>{
    NSSize iconSize;
    NSString *_filterText;
    NSMutableArray *BaseDirectoriesArray;
    BViewMode _viewMode;
}

@property (strong) IBOutlet NSSearchField *myFilterText;
@property (weak) IBOutlet BrowserOutlineView *myOutlineView;
@property (weak) IBOutlet BrowserTableView *myTableView;
@property (strong) IBOutlet CustomTableHeaderView *myTableViewHeader;
@property (weak) IBOutlet NSPathCell *myPathBarCell;
@property (strong) IBOutlet NSPathControl *myPathBarControl;
//@property (weak) (setter = setPathBar:) NSPathCell *PathBar;
@property (strong) IBOutlet NSPopUpButton *myPathPopDownButton;
@property (strong) IBOutlet NSMenu *myPathPopDownMenu;

@property (strong) IBOutlet NSProgressIndicator *myOutlineProgressIndicator;
@property (strong) IBOutlet NSProgressIndicator *myFileViewProgressIndicator;


@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;
@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;


/*
 * Tree Outline View Data Source Protocol
 */
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item ;
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item;
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
/*
 * Tree Outline View Data Delegate Protocol
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

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

/*
 * Selectors Binded in XIB
 */
- (IBAction) PathSelect:(id)sender;
- (IBAction) FilterChange:(id)sender;
- (IBAction) ChooseDirectory:(id)sender;

/*
 * Notifications Received 
 */
#ifdef COLUMN_NOTIFICATION
-(void) selectColumnTitles:(NSNotification *) note ;
#endif
/*
 * Parent access routines
 */

-(void) afterLoadInitialization;

-(void) setViewMode:(BViewMode)viewMode;
-(BViewMode) viewMode;

-(TreeBranch*) treeNodeSelected;


-(id) getFileAtIndex:(NSUInteger)index;
-(void) set_filterText:(NSString *) filterText;

-(void) reloadItem:(id) item;
-(void) refreshTableView;
-(void) refreshTableViewKeepingSelections;
-(void) refreshTrees;
-(void) addTreeRoot:(TreeBranch*)theRoot;
-(void) removeRootWithIndex:(NSInteger)index;
//-(void) removeRoot: (TreeRoot*) rootPath;
//-(void) removeSelectedDirectory;
-(void) removeAll;
-(NSInteger) canAddRoot: (NSString*) rootPath;
//-(FileCollection *) concatenateAllCollections;
-(TreeBranch*) selectFirstRoot;
-(BOOL) selectFolderByItem:(TreeItem*) treeNode;
-(BOOL) selectFolderByURL:(NSURL*)theURL;
-(TreeBranch*) getItemByURL:(NSURL*)theURL;
-(void) startAllBusyAnimations;
-(void) startTableBusyAnimations;
-(void) stopBusyAnimations;
-(NSURL*) getTreeViewSelectedURL;
-(NSArray*) getTableViewSelectedURLs;
-(void) setTableViewSelectedURLs:(NSArray*) urls;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextMenu;
-(void) backSelectedFolder;
-(void) forwardSelectedFolder;



@end
