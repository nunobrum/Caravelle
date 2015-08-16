//
//  NodeViewController.h
//  Caravelle
//
//  Created by Nuno Brum on 04/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Definitions.h"
#import "TreeBranch.h"
#import "NodeSortDescriptor.h"



@protocol NodeViewProtocol <NSObject, MYViewProtocol>

-(void) reloadItem:(id) object;
-(void) refresh;
-(void) refreshKeepingSelections;
-(NSView*) containerView;

- (void) setCurrentNode:(TreeBranch*)branch;
- (TreeBranch*) currentNode;

-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextualMenu1; // Can select the current Node
-(NSArray*) getSelectedItemsForContextualMenu2; // Doesn't select the current Node
-(TreeItem*) getLastClickedItem;

@end

@protocol BrowserParentProtocol <ParentProtocol>
- (void) selectionDidChangeOn:(id)object;
- (void) upOneLevel;
- (EnumBrowserViewMode) viewMode;
- (EnumBrowserViewType) viewType;
@end


@interface NodeViewController : NSViewController <MYViewProtocol, NSMenuDelegate> {
    TreeItem   *_validatedDropDestination;
    NSDragOperation _validatedDropOperation;
    NSMutableIndexSet *extendedSelection;
    NSMutableArray *_displayedItems;
    NSString * _twinName;
}

@property (readwrite, weak) id<BrowserParentProtocol> parentController;
@property (readwrite, strong) NSString *filterText;

@property (getter = filesInSubdirsDisplayed, setter = setDisplayFilesInSubdirs:) BOOL extendToSubdirectories;
@property (getter= foldersDisplayed, setter = setFoldersDisplayed:) BOOL foldersInTable;

@property (readwrite, strong) NSMutableArray *sortAndGroupDescriptors;
@property NSString *viewName;

- (void) initController;
- (void) setCurrentNode:(TreeBranch*)branch;
- (TreeBranch*) currentNode;
- (void) setName:(NSString*)viewName twinName:(NSString*)twinName;
- (NSString*)twinName;

- (void) updateFocus:(id)sender;
- (void) contextualFocus:(id)sender;
- (void)cancelOperation:(id)sender;

- (void) refresh;
- (void) refreshKeepingSelections;

- (BOOL) startEditItemName:(TreeItem*)item;
- (void) insertItem:(id)item;
- (void) orderOperation:(NSString const*)operation onItems:(NSArray*)orderedItems;

- (void) registerDraggedTypes;
- (void) unregisterDraggedTypes;
- (NSView*) containerView;

- (NSMutableArray*) itemsToDisplay;
- (NodeSortDescriptor*) sortDescriptorForFieldID:(NSString*)fieldID;
- (void) makeSortOnFieldID:(NSString*)info ascending:(BOOL)ascending grouping:(BOOL)grouping;
- (void) removeSortOnField:(NSString*)key;
- (void) removeGroupings;

-(NSArray*) getTableViewSelectedURLs;
-(void) setTableViewSelectedURLs:(NSArray*) urls;
-(NSArray*) getSelectedItems;
-(NSArray*) getSelectedItemsForContextualMenu1; // Can select the current Node
-(NSArray*) getSelectedItemsForContextualMenu2; // Doesn't select the current Node
-(TreeItem*) getLastClickedItem;

-(void) startBusyAnimationsDelayed;
-(void) startBusyAnimations;
-(void) stopBusyAnimations;

-(IBAction) menuGroupingSelector:(id) sender;
-(IBAction) menuColumnSelector:(id)sender;

// Support for Table View : Ignored in other views
-(void) setupColumns:(NSArray*) columns;
-(NSArray*) columns;
-(void) addColumn:(NSString*) fieldID;
-(void) removeColumn:(NSString*) fieldID;

-(void) loadPreferencesFrom:(NSDictionary*) preferences;
-(void) savePreferences:(NSMutableDictionary*) preferences;

@end
