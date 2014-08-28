//
//  BrowserController.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCollection.h"
#import "TreeRoot.h"
#import "PathControlManager.h"
#include "Definitions.h"

@interface BrowserController : NSViewController <NSOutlineViewDataSource, NSTableViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate>{
    NSMutableArray *tableData;
    NSSize iconSize;
    NSString *_filterText;
    NSMutableArray *BaseDirectoriesArray;
    NSMutableArray *tableInfo;
    NSSortDescriptor *TableSortDesc;
    NSMutableArray *_observedVisibleItems;
    NSOperationQueue *_sharedOperationQueue;
    BOOL blockTableRefresh; //Used to block the automatic refresh of the Table in the didChangeSelection method on OutlineView

}

@property (strong) IBOutlet NSSearchField *myFilterText;
@property (weak) IBOutlet NSOutlineView *myOutlineView;
@property (weak) IBOutlet NSTableView *myTableView;
@property (weak) IBOutlet NSPathCell *myPathBarCell;
@property (strong) IBOutlet PathControlManager *myPathBarControl;
//@property (weak) (setter = setPathBar:) NSPathCell *PathBar;
@property (strong) IBOutlet NSProgressIndicator *myOutlineProgressIndicator;
@property (strong) IBOutlet NSProgressIndicator *myFileViewProgressIndicator;

@property NSOperationQueue *sharedOperationQueue;

@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;
@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;
@property (getter =  viewMode, setter = setViewMode:) BViewMode viewMode;
@property TreeBranch *treeNodeSelected;

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
- (IBAction)TableDoubleClickEvent:(id)sender;

/*
 * Selectors Binded in XIB
 */
- (IBAction) PathSelect:(id)sender;
- (IBAction) FilterChange:(id)sender;
- (IBAction) ChooseDirectory:(id)sender;

/*
 * Parent access routines
 */

-(NSOutlineView*) treeOutlineView;
-(id) getFileAtIndex:(NSUInteger)index;
-(void) set_filterText:(NSString *) filterText;
-(void) refreshDataView;
-(void) refreshTrees;
-(void) addTreeRoot:(TreeRoot*)theRoot;
-(void) removeRootWithIndex:(NSInteger)index;
//-(void) removeRoot: (TreeRoot*) rootPath;
-(void) removeSelectedDirectory;
-(void) removeAll;
-(NSInteger) canAddRoot: (NSString*) rootPath;
//-(FileCollection *) concatenateAllCollections;
-(TreeBranch*) selectFirstRoot;
-(TreeBranch*) selectFolderByURL:(NSURL*)theURL;
-(void) startBusyAnimations;
-(void) stopBusyAnimations;

@end
