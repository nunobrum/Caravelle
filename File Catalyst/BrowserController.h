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
#import "FileCollection.h"
#import "TreeRoot.h"
#include "Definitions.h"




extern NSString *notificationCatalystRootUpdate;


@interface BrowserController : NSViewController <ParentProtocol, NSOutlineViewDataSource, NSOutlineViewDelegate, MYViewProtocol, NSTextDelegate, NSSplitViewDelegate> {
    NSSize iconSize;
    //NSString *_filterText;
    NSMutableArray *BaseDirectoriesArray;
    BViewMode _viewMode;
    BViewType _viewType;
    NSString * _twinName;
}

@property (strong) IBOutlet NSSearchField *myFilterText;
@property (strong) IBOutlet BrowserOutlineView *myOutlineView;
@property (strong) IBOutlet NSPathCell *myPathBarCell;
@property (strong) IBOutlet NSPathControl *myPathBarControl;
//@property (weak) (setter = setPathBar:) NSPathCell *PathBar;
@property (strong) IBOutlet NSPopUpButton *myPathPopDownButton;
@property (strong) IBOutlet NSMenu *myPathPopDownMenu;

@property (strong) IBOutlet NSProgressIndicator *myOutlineProgressIndicator;

@property (strong) IBOutlet NSSegmentedControl *myViewSelectorButton;

@property (strong) IBOutlet NSSplitView *mySplitView;
@property (strong) IBOutlet NSSegmentedControl *treeEnableSwitch;

@property (strong) IBOutlet NSMenu *contextualMenu;


@property (readwrite, weak) id<ParentProtocol> parentController;
@property (strong) NodeViewController *detailedViewController;


@property NSString *titleCopyTo;
@property NSString *titleMoveTo;
@property NSNumber *contextualToMenusEnabled;
@property NSString *viewName;
@property NSMutableDictionary *preferences;

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

/* Binding is done manually in the initialization procedure */
- (IBAction)OutlineDoubleClickEvent:(id)sender;

/*
 * Selectors Binded in XIB
 */
- (IBAction) PathSelect:(id)sender;
- (IBAction) FilterChange:(id)sender;
- (IBAction) ChooseDirectory:(id)sender;
//- (IBAction) filenameDidChange:(id)sender;
- (IBAction) treeViewEnable:(id)sender;
- (IBAction) viewTypeSelection:(id)sender;
- (IBAction) mruBackForwardAction:(id)sender;

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
-(void) setViewType:(BViewType)viewType;
-(BViewType) viewType;

-(void) setViewMode:(BViewMode)viewMode;
-(BViewMode) viewMode;

-(TreeBranch*) treeNodeSelected;

-(void) set_filterText:(NSString *) filterText;

-(void) reloadItem:(id) item;
-(void) refresh;
-(void) addTreeRoot:(TreeBranch*)theRoot;
-(void) removeRootWithIndex:(NSInteger)index;
//-(void) removeRoot: (TreeRoot*) rootPath;
//-(void) removeSelectedDirectory;
-(void) removeAll;
//-(BOOL) canAddRoot: (NSString*) rootPath;
//-(FileCollection *) concatenateAllCollections;
-(TreeBranch*) selectFirstRoot;
-(BOOL) selectFolderByItem:(TreeItem*) treeNode;
-(BOOL) selectFolderByURL:(NSURL*)theURL;
-(TreeBranch*) getItemByURL:(NSURL*)theURL;
-(void) startAllBusyAnimations;
-(void) stopBusyAnimations;
-(NSURL*) getTreeViewSelectedURL;

-(id) focusedView;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextMenu;
-(TreeItem*) getLastClickedItem;

-(BOOL) startEditItemName:(id)item;
-(void) insertItem:(id)item;

-(void) backSelectedFolder;
-(void) forwardSelectedFolder;

-(NSNumber*) validateContextualCopyTo;
-(NSNumber*) validateContextualMoveTo;

@end
