//
//  BrowserController.h
//  File Catalyst
//
//  Created by Nuno Brum on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NodeViewController.h"
#import "BrowserTableView.h"
#import "BrowserOutlineView.h"
#import "TreeCollection.h"
#include "Definitions.h"


#define DISTANCE_FROM_SPLITVIEW_TO_TOP 62

extern NSString *kViewChanged_TreeCollapsed;
extern NSString *kViewChanged_FlatView;


@interface BrowserController : NSViewController <BrowserParentProtocol, NSOutlineViewDataSource, NSOutlineViewDelegate, MYViewProtocol, NSTextDelegate, NSSplitViewDelegate, NSMenuDelegate> {
    NSSize iconSize;
    //NSString *_filterText;
    //NSMutableArray *BaseDirectoriesArray;
    TreeCollection *_baseDirectories;
    EnumBrowserViewMode _viewMode;
    EnumBrowserViewType _viewType;
    NSString * _twinName;
    NSInteger drillDepth;
}

@property (strong) IBOutlet NSSearchField *myFilterText;
@property (strong) IBOutlet BrowserOutlineView *myOutlineView;
@property (strong) IBOutlet NSPathCell *myPathBarCell;
@property (strong) IBOutlet NSPathControl *myPathBarControl;
//@property (weak) (setter = setPathBar:) NSPathCell *PathBar;
@property (strong) IBOutlet NSPopUpButton *myPathPopDownButton;
@property (strong) IBOutlet NSMenu *myPathPopDownMenu;
@property (strong) IBOutlet NSPopUpButton *myGroupingPopDpwnButton;
@property (strong) IBOutlet NSPopUpButton *myColumnsPopDpwnButton;

@property (strong) IBOutlet NSProgressIndicator *myOutlineProgressIndicator;


@property (strong) IBOutlet NSSplitView *mySplitView;
@property (strong) IBOutlet NSSegmentedControl *viewOptionsSwitches;
@property (strong) IBOutlet NSSegmentedControl *mruBackForwardControl;
@property (strong) IBOutlet NSBox *drillBox;
@property (strong) IBOutlet NSLayoutConstraint *splitViewToTopConstraint;

// This controller is used to select groupings


@property (readwrite, weak) id<ParentProtocol> parentController;
@property (strong) NodeViewController *detailedViewController;


@property NSString *viewName;
@property NSMutableDictionary *preferences;
@property TreeCollection *baseDirectories;

@property NSString *drillLevel;

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
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

/* Binding is done manually in the initialization procedure */
- (IBAction)OutlineDoubleClickEvent:(id)sender;

/*
 * Selectors Binded in XIB
 */
- (IBAction) PathSelect:(id)sender;
- (IBAction) FilterChange:(id)sender;
- (IBAction) ChooseDirectory:(id)sender;

- (IBAction) optionsSwitchSelect:(id)sender;

- (IBAction) mruBackForwardAction:(id)sender;
- (IBAction)filenameDidChange:(id)sender;

- (IBAction)depthChanged:(id)sender;

/*
 * Notifications Received 
 */
#ifdef COLUMN_NOTIFICATION
-(void) selectColumnTitles:(NSNotification *) note ;
#endif


-(IBAction) tableSelected:(id)sender;


/*
 * Parent access routines
 */

-(void) setName:(NSString*)viewName TwinName:(NSString *)twinName;
-(void) setViewType:(EnumBrowserViewType)viewType;
-(EnumBrowserViewType) viewType;

-(void) setViewMode:(EnumBrowserViewMode)viewMode;
-(EnumBrowserViewMode) viewMode;

-(void) loadPreferences;
-(void) savePreferences;

-(void) setTreeViewCollapsed:(BOOL) collapsed;
-(BOOL) treeViewCollapsed;
-(void) setFlatView:(BOOL) flatView;
-(BOOL) flatView;

-(TreeBranch*) treeNodeSelected;
-(void) setCurrentNode:(TreeBranch*) branch;
-(void) setPathBarToItem:(TreeItem*)item;
-(void) selectionDidChangeOn:(id)object;

-(void) set_filterText:(NSString *) filterText;

-(void) reloadItem:(id) item;
-(void) refresh;
-(void) cleanRefresh;
-(void) addTreeRoot:(TreeBranch*)theRoot;
-(void) addFileCollection:(FileCollection*) collection;
-(void) setRoots:(NSArray*) baseDirectories;
-(NSArray*) roots;
//-(void) removeRootWithIndex:(NSInteger)index;
//-(void) removeRoot: (TreeRoot*) rootPath;
//-(void) removeSelectedDirectory;
-(void) removeAll;

-(TreeBranch*) selectFirstRoot;
-(BOOL) selectFolderByItem:(TreeItem*) treeNode;
//-(BOOL) selectFolderByURL:(NSURL*)theURL;
//-(TreeBranch*) getItemByURL:(NSURL*)theURL;
//-(TreeBranch*) getRootWithURL:(NSURL*)theURL;
-(void) startAllBusyAnimations;
-(void) stopBusyAnimations;
//-(NSURL*) getTreeViewSelectedURL;

-(id) focusedView;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextualMenu1; // Can select the current Node
-(NSArray*) getSelectedItemsForContextualMenu2;
-(TreeItem*) getLastClickedItem;

-(BOOL) startEditItemName:(id)item;
-(void) insertItem:(id)item;

-(void) backSelectedFolder;
-(void) forwardSelectedFolder;

-(NSString*) title;
-(NSString*) homePath;

@end
