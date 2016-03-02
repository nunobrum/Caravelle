//
//  BrowserController.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "BrowserController.h"
#import "FileUtils.h"

#import "FolderCellView.h"  // Used for the Duplicate/Catalyst View

#import "TreeManager.h"
#import "fileOperation.h"
#import "TableViewController.h"
#import "IconViewController.h"
#import "FileAttributesController.h"
#import "PasteboardUtils.h"


const NSUInteger maxItemsInBrowserPopMenu = 7;
const NSUInteger item0InBrowserPopMenu    = 0;

NSString *kViewChanged_TreeCollapsed = @"TreeViewCollapsed";
NSString *kViewChanged_FlatView = @"ToggledFlatView";

@interface BrowserController () {
    id _focusedView; // Contains the currently selected view
    id _contextualFocus; // Contains the element used for contextual menus
    NSMutableArray *_observedVisibleItems;
    /* Internal Storage for Drag and Drop Operations */
    NSDragOperation _validatedDropOperation; // Passed from Validate Drop to Accept Drop Method
    TreeBranch * _treeNodeSelected;
    TreeBranch * _rootNodeSelected;
    TreeItem * _validatedDropDestination;
    BOOL _didRegisterDraggedTypes;
    BOOL _awakeFromNibConfigDone;
    BOOL _treeCollapseDetector;
    TreeBranch * _draggedOutlineItem;
    NSMutableArray *_mruLocation;
    NSUInteger _mruPointer;
    NSMutableIndexSet *extendedSelection;
    IconViewController *iconViewController;
    TableViewController *tableViewController;
}

@end

@implementation BrowserController

#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self->BaseDirectories = [[TreeCollection new] initWithURL:nil parent:nil];
    self->extendedSelection = nil; // Used in the extended selection mode
    self->_focusedView = nil;
    self->_viewMode = BViewModeVoid; // This is an invalid view mode. This forces the App to change it.
    self->_viewType = BViewTypeInvalid; // This is an invalid view type. This forces the App to change it.
    self->_viewName = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
    self->_didRegisterDraggedTypes = NO;
    self->_awakeFromNibConfigDone = NO;
    self->_detailedViewController = nil;
    self->tableViewController = nil;
    self->iconViewController = nil;
    _treeNodeSelected = nil;
    _rootNodeSelected = nil;
    _mruLocation = [[NSMutableArray alloc] init];
    self.preferences = [[NSMutableDictionary alloc] initWithCapacity:50];
    _mruPointer = 0;
    return self;
}

-(void) awakeFromNib {
    if (_awakeFromNibConfigDone==NO) {
        if (self.myOutlineView==nil) return;
        if (self.myFilterText.selectedCell==nil) return;

        //[[self myOutlineView] setAutosaveName:[self->_viewName stringByAppendingString:@"Outline"]];
        // The Outline view has no customizable settings
        //[[self myOutlineView] setAutosaveTableColumns:YES];

        NSButtonCell *searchCell = [self.myFilterText.selectedCell searchButtonCell];
        NSImage *filterImage = [NSImage imageNamed:@"FilterIcon16"];
        [searchCell setImage:filterImage];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:USER_DEF_SEE_HIDDEN_FILES
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];

        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:USER_DEF_CALCULATE_SIZES
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:USER_DEF_BROWSE_APPS
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:USER_DEF_HIDE_FOLDERS_WHEN_TREE
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        self->_awakeFromNibConfigDone = YES;
    }
}

-(void)viewDidLoad {
    self->_treeCollapseDetector = [self treeViewCollapsed];
}

- (void)dealloc {
    //  Stop any observations that we may have
    [self unobserveAll];
    //    [super dealloc];
}


/* Method overriding the default for the NSView
 This is done to accelerate the redrawing of the contents */
-(BOOL) isOpaque {
    return YES;
}

// NSWorkspace Class Reference - (NSImage *)iconForFile:(NSString *)fullPath

/* the Most Recent URLs make a List of all most recent locations.
 It protects that two equal URLS are not placed in a sequence.
 When the user navigates backward pointer moves back. When a forward is the requested,
 the pointer is moved forward. */
-(void) mruSet:(NSURL*) url {
    if(_viewMode!=BViewBrowserMode)
        return; // Sanity check. Needed for the Duplicate Mode.
    
    if (url==nil)
        return; // Second sanity check. URL cannot be null
    
    // gets the pointer to the last position
    NSUInteger mruCount = [_mruLocation count];

    // if its the first just adds it
    if (mruCount==0) {
        [_mruLocation addObject:url];
        // Enable the back Button
        [self.mruBackForwardControl setEnabled:YES forSegment:0];
    }
    // Then checking if its changing
    else if (![url isEqual:_mruLocation[_mruPointer]]) { // Don't want two URLS repeated in a sequence
        _mruPointer++;
        if (_mruPointer < mruCount) { // There where back movements before
            if (pathIsSame != url_relation(url, _mruLocation[_mruPointer]) ) { // not just moving forward
                NSRange follwingMRUs;
                follwingMRUs.location = _mruPointer+1;
                follwingMRUs.length = mruCount - _mruPointer - 1;
                _mruLocation[_mruPointer] = url;
                if (follwingMRUs.length!=0) {
                    [_mruLocation removeObjectsInRange:follwingMRUs];
                }
                // Disable the forward button
                [self.mruBackForwardControl setEnabled:NO forSegment:1];
            }
            // There is no else : on else We are just moving forward
        }
        else {
            [_mruLocation addObject:url]; // Adding to the last position
            // Enable the back Button
            [self.mruBackForwardControl setEnabled:YES forSegment:0];
        }
    }
}

#pragma mark - NSSplitViewDelegate methods
#define kMinContrainValue 150.0f

// -------------------------------------------------------------------------------
//	awakeFromNib:
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    BOOL canCollapseSubview = NO;

    NSArray *splitViewSubviews = [splitView subviews];
    //NSUInteger splitViewSubviewCount = [splitViewSubviews count];
    if (subview == [splitViewSubviews objectAtIndex:0] )
    {
        canCollapseSubview = YES;
        //[self->treeEnableSwitch setSelected:NO forSegment:0];
    }
    return canCollapseSubview;
}

// -------------------------------------------------------------------------------
//	shouldCollapseSubview:subView:dividerIndex
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    // yes, if you can collapse you should collapse it
    return YES;
}

// -------------------------------------------------------------------------------
//	constrainMinCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if (index == 0)
    {
        constrainedCoordinate = proposedCoordinate + kMinContrainValue;
    }
    //NSLog(@"View: %@ Index: %ld MinCoordinate: %f",_viewName, (long)index, proposedCoordinate);
    return constrainedCoordinate;
}

// -------------------------------------------------------------------------------
//	constrainMaxCoordinate:proposedCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
#define ICON_WIDTH 130
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if (index == 0 && [self.detailedViewController isKindOfClass:[IconViewController class]]) {
        CGFloat detailedWidth = [[[splitView subviews] objectAtIndex:1] frame].size.width;
        detailedWidth = floorf(detailedWidth / ICON_WIDTH + 0.4999) * ICON_WIDTH;
        NSLayoutConstraint *constraint =[(IconViewController*)self.detailedViewController viewWidthConstraint];
        [constraint setConstant:detailedWidth];
        //NSLog(@"View: %@ Index: %ld MaxCoordinate: %f Constraint: %f",_viewName, (long) index, proposedCoordinate, detailedWidth);
    }
    return constrainedCoordinate;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    // Use this notfication to set the select state of the button
    BOOL treeCollapsed = [self treeViewCollapsed];
    if (treeCollapsed != self->_treeCollapseDetector) {
        [self.viewOptionsSwitches setSelected:!treeCollapsed forSegment:BROWSER_VIEW_OPTION_TREE_ENABLE];
        self->_treeCollapseDetector = treeCollapsed;
        //NSLog(@"View:%@ splitViewDidResizeSubiews; tree collapsed.",_viewName);
        [self.detailedViewController setFoldersDisplayed: self.foldersDisplayedMacro];
        [self.detailedViewController refreshKeepingSelections];
    }
}


-(BOOL) foldersDisplayedMacro {
    BOOL userDefHideFoldersWhenTreeVisible = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_HIDE_FOLDERS_WHEN_TREE];
    BOOL treeIsVisible = ![self treeViewCollapsed];
    return !(userDefHideFoldersWhenTreeVisible == YES && treeIsVisible==YES);
}

#pragma mark - Tree Outline DataSource Protocol

/*
 * Tree Outline View Data Source Protocol
 */


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if(item==nil) {
        return [BaseDirectories numberOfBranchesInNode];
    }
    else {
        // Returns the total number of leafs
        return [item numberOfBranchesInNode];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    TreeItem * ret;
    if (item==nil || [item isKindOfClass:[NSMutableArray class]])
        ret = [BaseDirectories branchAtIndex:index];
    else {
        ret = [item branchAtIndex:index];
    }
    if ([ret isFolder]) {
        // Use KVO to observe for changes of its children Array
        [self observeItem:ret];
        [ret refresh];
    }
    return ret;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL answer=NO;
    if ([item isKindOfClass:[NSMutableArray class]]) /* If it is the BaseArray */
        answer = ([item count] > 1)  ? YES : NO;
    else
        answer = ([(TreeItem*)item isExpandable]);
    return answer;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView=nil;

    if ([[tableColumn identifier] isEqualToString:COL_FILENAME]) {
        if ([item isFolder]) { // it is a directory
            if (_viewMode!=BViewBrowserMode) {
                NSString *subTitle;
                NSString *sizeString;
                long fileCount=0;
                if ([item respondsToSelector:@selector(numberOfLeafsInBranch)]) {
                    fileCount = [item numberOfLeafsInBranch];
                }
                long long sizeOfFilesInBranch = -1;
                if ([item respondsToSelector:@selector(exactSize)]) {
                    sizeOfFilesInBranch = [[item exactSize] longLongValue];
                }
                if (sizeOfFilesInBranch==-1) // Undefined
                    sizeString = @"--";
                else {
                    // !! Beware to change this if ever the transformer changes
                    //NSValueTransformer *trans=[NSValueTransformer valueTransformerForName:@"size"];
                    //sizeString = [trans transformedValue:sizeOfFilesInBranch];
                    sizeString = [NSByteCountFormatter stringFromByteCount:sizeOfFilesInBranch countStyle:NSByteCountFormatterCountStyleFile];
                }
                cellView= [outlineView makeViewWithIdentifier:@"CatalystView" owner:self];
                if (fileCount==0)
                    subTitle = @"No Files";
                else
                    subTitle = [NSString stringWithFormat:@"%ld Files %@", fileCount,sizeString];
                
                [(FolderCellView*)cellView setSubTitle:subTitle];
                [(FolderCellView*)cellView setURL:[item url]];
                [cellView setObjectValue:item];

            }
            else {
                cellView= [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
            }

            // Display the directory name followed by the number of files inside
            NSImage *icon =  [(TreeBranch*)item image];
            [[cellView imageView] setImage:icon];
            [[cellView textField] setStringValue:[item name]];

            if ([item hasTags:tagTreeItemDropped]) {
                [cellView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped
            }
            else {
                [cellView.textField setTextColor:[NSColor textColor]]; // Set color back to normal
            }
        }
        else {
            NSLog(@"BrowserController.outlineView:viewForTableColumn:item - Unknown class %@", [item className]);
        }
    }
    return cellView;
}

//- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//
//}

// This doesn't seem to be used, but it's needed for debug. trapping the KVO setting
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSLog(@"BrowserController.outlineView:setObjectValue:forTableColumn:byItem - Not implemented");
    NSLog(@"setObjectValue Object Class %@ Table Column %@ Item %@",[(NSObject*)object class], tableColumn.identifier, [item name]);
}

#pragma mark - Tree Outline View Delegate Protocol


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    CGFloat answer;
    if (_viewMode!=BViewBrowserMode) {
        answer = [outlineView rowHeight];
    }
    else {
        answer = 17;
    }
    return answer;
}

//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//    if ([[tableColumn identifier] isEqualToString:COL_FILENAME]) {
//        if ([item isLeaf]) {//if it is a file
//            // This is not needed now since the Tree View is not displaying files in this application
//        }
//        else if ([item isFolder] && // it is a directory
//                 [cell isKindOfClass:[FolderCellView class]]) { // It is a Image Preview Class
//            // Display the directory name followed by the number of files inside
//            NSString *path = [(TreeBranch*)item path];
//            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
//            [icon setBackgroundColor:[NSColor whiteColor]];
//            [icon setSize:iconSize];
//
//            NSString *subTitle = [NSString stringWithFormat:@"%ld Files %@", (long)[(TreeBranch*)item numberOfLeafsInBranch], [NSByteCountFormatter stringFromByteCount:[item byteSize] countStyle:NSByteCountFormatterCountStyleFile]];
//            [cell setSubTitle:subTitle];
//            [cell setImage:icon];
//
//        }
//    }
//    else
//        NSLog(@"Cell Class %@ Table Column %@ Item %@",[(NSObject*)cell class], tableColumn.identifier, [item name]);
//}


- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // Stop observing visible things
    TreeItem *item = [[rowView viewAtColumn:0] objectValue];
    [self unobserveItem:item];
}

/*
 * Tree Outline View Data Delegate Protocol
 */


/* Called before the outline is selected.
 Can be used later to block access to private directories
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return YES;
}
 */

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ])  {
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        NSInteger SelectedCount = [rowsSelected count];
        _focusedView = _myOutlineView;
        if (!_didRegisterDraggedTypes) {
            [_myOutlineView registerForDraggedTypes: supportedPasteboardTypes()];
            // TODO: !!! Maybe is because of this that the drag to recycle bin doesn't work
            _didRegisterDraggedTypes = YES;
        }
        if (SelectedCount ==0) {
            //[_myTableView unregisterDraggedTypes];
        } else if (SelectedCount==1) {
            /* Updates the _treeNodeSelected */
            TreeBranch * tb = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            if (tb != _treeNodeSelected) { // !!! WARNING This workaround might raise problems in the future depending on the implementation of the folder change notification. Best is to see why this function is being called twice.
                [self setCurrentNode:tb];

                //[self refreshDataView];
                // Use KVO to observe for changes of its children Array
                if ([_treeNodeSelected needsRefresh]) {
                    [self.detailedViewController startBusyAnimationsDelayed];
                    [_treeNodeSelected refresh];
                    // This will automatically call for a refresh
                }
                else {
                    // No need to keep the selection here since the folder is being changed
                    [self.detailedViewController refresh];
                }
            }
        }
        else {
            NSLog(@"BrowserController.outlineViewSelectionDidChange - More than one item Selected");
            return;
        }
        [self selectionDidChangeOn:self]; // Will Trigger the notification to the status bar
    }
}

#pragma mark - Browser Parent Protocol
-(void) selectionDidChangeOn:(id)object {
    if (object==self.detailedViewController && self.detailedViewController.filesInSubdirsDisplayed) {
        NSArray *itemsSelected = [object getSelectedItems];
        if ([itemsSelected count]==1) {
            // will change the path bar
            [self setPathBarToItem:[(TreeItem*)itemsSelected[0] parent]];
        }
        else {
            // set the PathBar back to the _treeNode
            [self setPathBarToItem:_treeNodeSelected];
        }
    }
    else if (object==self) {
        // Its on the tree
        // Gets the index of the current selected Node
        NSInteger index2select = [self.myOutlineView rowForItem:_treeNodeSelected];
        if (index2select != -1) {
            // It was found
            NSIndexSet *selectedIndexes = [NSIndexSet indexSetWithIndex:index2select];
            [self.myOutlineView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
        }
        else
            NSAssert(NO, @"BrowserController.selectionDidChangeOn: Branch not found in the tree");
        // set the PathBar back to the _treeNode
        [self setPathBarToItem:_treeNodeSelected];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:object userInfo:nil];
}

-(void) upOneLevel {
    // Up one level here
    if (self.treeNodeSelected.parent != nil) {
        if ([self selectFolderByItem:self.treeNodeSelected.parent])
            return;
    }
    // else -> TODO:1.5 Beep something
}


#pragma mark - Service Menu Handling
/* These functions are used for the Services Menu */

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
    if ([sendType isEqual:NSFilenamesPboardType] ||
        [sendType isEqual:NSURLPboardType]) {
        return self;
    }
    //return [super validRequestorForSendType:sendType returnType:returnType];
    return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
    NSArray *selectedFiles = [self getSelectedItemsForContextualMenu1];
    return writeItemsToPasteboard(selectedFiles, pboard, types);
}

//- (void)menuWillOpen:(NSMenu *)menu {
//    This is not needed. Keeping it for memory
//}

#pragma mark - NSMenuDelegate
/*
 These two functions can be used in alternative to the selector below
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
    return [sortedColumnNames() count] + 1; // Adding one for the header
}

- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {

}*/

//- (void)menuWillOpen:(NSMenu *)menu {
//    NSLog(@"AppDelegate.menuWillOpen");
//}
//
//- (void)menuWillClose:(NSMenu *)menu {
//    NSLog(@"AppDelegate.menuWillClose");
//}

-(void) menuNeedsUpdate:(NSMenu *)menu {
    //menu = [[NSMenu alloc] initWithTitle:@"Groupings Menu"];
    // Check if menu was updated
    if ([[menu title] isEqualToString:@"GroupingMenu"]) {
        
        if ([[menu itemArray] count]==1) {
            int tagCount = 0;
            for (NSString *colID in sortedColumnNames() ) {
                NSDictionary *colInfo = [columnInfo() objectForKey:colID];
                
                // Do not display columns that are not to be displayed in this mode.
                NSNumber *app_mode = [colInfo objectForKey:COL_APP_MODE];
                if (app_mode != nil) {
                    if (([app_mode longValue] & applicationMode) == 0)
                        continue; // This blocks Columns that are not to be displayed in the current mode.
                }
                
                // Restrict to fields that have grouping setting
                id grouping = [colInfo objectForKey:COL_GROUPING_KEY];
                if (grouping) {
                    NSString *menuTitle = [colInfo objectForKey:COL_TITLE_KEY];
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:@selector(menuGroupingSelector:) keyEquivalent:@""];
                    [menuItem setEnabled:YES];
                    [menuItem setState:NSOffState];
                    [menuItem setTag:tagCount++];
                    //[menuItem setAction:@selector(menuGroupingSelector:)];
                    [menuItem setTarget:self.detailedViewController];
                    [menu addItem:menuItem];
                }
            }
        }
        // If the menu was already created, then it will just update the groupings
        
        int i = 1; // Starts with the first visible Menu Item
        for (NSString *fieldID in sortedColumnNames() ) {
            NSDictionary *colInfo = [columnInfo() objectForKey:fieldID];
            
            // Do not display columns that are not to be displayed in this mode.
            NSNumber *app_mode = [colInfo objectForKey:COL_APP_MODE];
            if (app_mode != nil) {
                if (([app_mode longValue] & applicationMode) == 0)
                    continue; // This blocks Columns that are not to be displayed in the current mode.
            }
            
            id grouping = [colInfo objectForKey:COL_GROUPING_KEY];
            if (grouping) {
                NSIndexSet *idx = [self.detailedViewController.sortAndGroupDescriptors indexesOfObjectsPassingTest:
                                   ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                                       BOOL OK = [(NodeSortDescriptor*)obj isGrouping] && [[(NodeSortDescriptor*)obj field] isEqualToString:fieldID];
                                       *stop = OK;
                                       return OK;
                                   }];
                if (idx!=nil && [idx count]!=0) {
                    [[menu itemAtIndex:i] setState:NSOnState];
                }
                else {
                    [[menu itemAtIndex:i] setState:NSOffState];
                }
                i+=1;
            }
        }
    }
    else if ([[menu title] isEqualToString:@"ColumnsMenu"]) {  // Columns Menu
        NSArray *columns = [self.detailedViewController columns];
        
        if ([[menu itemArray] count]==1) {
            int tagCount = 0;
            
            for (NSString *fieldID in sortedColumnNames() ) {
                NSDictionary *colInfo = [columnInfo() objectForKey:fieldID];
                
                // Do not display columns that are not to be displayed in this mode.
                NSNumber *app_mode = [colInfo objectForKey:COL_APP_MODE];
                if (app_mode != nil) {
                    if (([app_mode longValue] & applicationMode) == 0)
                        continue; // This blocks Columns that are not to be displayed in the current mode.
                }
                
                // Restrict to fields that have grouping setting
                    NSString *menuTitle = [colInfo objectForKey:COL_TITLE_KEY];
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:@selector(menuColumnSelector:) keyEquivalent:@""];
                    [menuItem setEnabled:YES];
                    [menuItem setState:NSOffState];
                    [menuItem setTag:tagCount++];
                    [menuItem setTarget:self.detailedViewController];
                    [menu addItem:menuItem];
                
            }
        }
        // If the menu was already created, then it will just update the columns
        
        int i = 1; // Starts with the first visible Menu Item
        for (NSString *fieldID in sortedColumnNames() ) {
            NSDictionary *colInfo = [columnInfo() objectForKey:fieldID];
            
            // Do not display columns that are not to be displayed in this mode.
            NSNumber *app_mode = [colInfo objectForKey:COL_APP_MODE];
            if (app_mode != nil) {
                if (([app_mode longValue] & applicationMode) == 0)
                    continue; // This blocks Columns that are not to be displayed in the current mode.
            }
            
            
            NSIndexSet *idx = [columns indexesOfObjectsPassingTest:
                               ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                                   BOOL OK = [obj isEqualToString:fieldID];
                                   *stop = OK;
                                   return OK;
                               }];
            if (idx!=nil && [idx count]!=0) {
                [[menu itemAtIndex:i] setState:NSOnState];
            }
            else {
                [[menu itemAtIndex:i] setState:NSOffState];
            }
            i+=1;
        }
    }
    else if ([[menu title] isEqualToString:@"ContextualMenu"]) {
        [self.detailedViewController menuNeedsUpdate:menu];
    }
    else {
        NSLog(@"BrowserController.menuNeedsUpdate: Unknown Menu");
    }
}

// TODO:? Use this selector for making key bindings.
/*
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu
                    forEvent:(NSEvent *)event
                      target:(id *)target
                      action:(SEL *)action {
    return NO;
}
 */

// TODO:? Use this selector to validate the grouping menus
/*
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    SEL theAction = [anItem action];
    BOOL allow = NO;
    if (theAction == @selector(menuGroupingSelector:))
        allow = YES;
    NSLog(@"BrowserViewController.validateUserInterfaceItem: %s  %hhd", sel_getName(theAction), allow);
    return allow;
    
    return [NSNumber numberWithBool:allow];
}
 */


#pragma mark - Path Bar Handling
-(TreeBranch*) treeNodeSelected {
    return self->_treeNodeSelected;
}

-(void) setCurrentNode:(TreeBranch*) branch {
    if (branch != _treeNodeSelected) {
        if (branch==nil) {
            [self setPathBarToItem:nil];
            return;
        }
        TreeBranch *node;
        if ([branch isFolder]) {
            node = branch;
        }
        else {
            node = [branch parent];
        }
        if ([node respondsToSelector:@selector(url)]) {
            NSURL *url = [node url];
            
            // if the flat view is set, if outside of the current node, launch an expand Tree
            if (self.flatView && [node canAndNeedsFlat]) {
                // Assumes a change is needed
                enumPathCompare comp = pathsHaveNoRelation;
                
                // then checks whether is not needed
                if ([_treeNodeSelected respondsToSelector:@selector(url)]) {
                    comp = url_relation(url, [(id)_treeNodeSelected url]);
                }
                if (comp ==pathIsParent || comp == pathsHaveNoRelation) {
                    // Send notification to request Expansion
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                          opFlatOperation, kDFOOperationKey,
                                          self, kDFOFromViewKey, // The view is sent because the operation can take longer and selected view can change
                                          node, kDFODestinationKey, // This has to be placed in last because it can be nil
                                          nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
                }
            }
            [self setPathBarToItem:node];
            
            [self mruSet:url];
        }
        [self.detailedViewController setCurrentNode:node];
        _treeNodeSelected = node;
    }
}

-(void) setPathBarToItem:(TreeItem*)item {
    if (item==nil) {
        // Going to hide Menus and path bar
        [_myPathPopDownButton setHidden:YES];
        [_myPathBarControl setHidden:YES];
        return;
    }
    else {
        // In case it was formerly hidden.
        [_myPathPopDownButton setHidden:NO];
        [_myPathBarControl setHidden:NO];
    }

    NSMutableArray *pathComponentCells = [NSMutableArray arrayWithArray:
                                          [self.myPathBarControl pathComponentCells]];
    NSUInteger currSize = [pathComponentCells count];

    NSArray *pathComponents = [[item url] pathComponents];
    NSPathComponentCell *cell;
    NSRange rng;
    NSUInteger rootLevel = [[[_rootNodeSelected path] pathComponents] count];
    //piconSize.height =12;
    //piconSize.width = 12;
    rng.location=0;
    rng.length = 0;

    NSString *title;
    NSInteger i = 0;
    NSUInteger j;
    NSArray *menuItems = [_myPathPopDownMenu itemArray];
    NSInteger offset = rootLevel <= maxItemsInBrowserPopMenu ? 0 : (rootLevel-maxItemsInBrowserPopMenu);

    // TODO:!! Move this to a menu delegation object with the menuNeedsUpdate: Selector
    // Going to hide not used Items
    for (j=0; j < maxItemsInBrowserPopMenu ; j++) {
        NSMenuItem *menu = [menuItems objectAtIndex:maxItemsInBrowserPopMenu-j+item0InBrowserPopMenu];
        [menu setHidden:YES];
        [menu setTag:-5]; //  tag < 0 is define as do nothing
    }
    for (NSString *dirname in pathComponents) {
        rng.length++;
        if (rng.length==1) {
            NSURL *rootURL = [NSURL fileURLWithPath:pathComponents[0]];
            NSDictionary *diskInfo = getDiskInformation(rootURL);
            title = diskInfo[@"DAVolumeName"];
        }
        else {
            title = dirname;
        }
        NSURL *newURL = [NSURL fileURLWithPathComponents: [pathComponents subarrayWithRange:rng]];
        NSImage *icon =[[NSWorkspace sharedWorkspace] iconForFile:[newURL path]];

        if (rng.length < rootLevel) {
            // Use the myPathPopDownMenu outlet to get the maximum tag number
            NSInteger n = (maxItemsInBrowserPopMenu-1) - (rng.length - 1) + offset;
            if (n >=0 && n < maxItemsInBrowserPopMenu) {
                NSMenuItem *menu = [menuItems objectAtIndex:n+item0InBrowserPopMenu];
                NSSize piconSize = {16,16};
                [icon setSize:piconSize];
                [menu setImage:icon];
                [menu setTitle:title];
                [menu setHidden:NO];
                [menu setTag:rng.length-1];
            }
        }
        else {
            if (i < currSize) {
                cell = pathComponentCells[i];
                if ([newURL isEqual:[cell URL]]) {
                    i++;
                    continue; // Nothing to change in this case
                }
            }
            else {
                cell = [[NSPathComponentCell new] init];
                [pathComponentCells addObject:cell];
                currSize++;
            }
            NSSize piconSize = {12,12};
            [icon setSize:piconSize];
            [cell setURL:newURL];
            [cell setImage:icon];
            [cell setTitle:title];
            i++;
        }
    }
    //i++; // Increment one more so it is +1 over the last valid position
    // Finally delete the extra cells if exist
    if (i<currSize) {
        rng.location = i;
        rng.length = currSize-i;
        [pathComponentCells removeObjectsInRange:rng];
    }
    [self.myPathBarControl setPathComponentCells:pathComponentCells];

}


#pragma mark - Action Selectors

- (IBAction)tableSelected:(id)sender {
    _focusedView = sender;
    [[self parentController] updateFocus:self];
}

-(void) updateFocus:(id)sender {
    _focusedView = sender;
    [[self parentController] updateFocus:self];
}

-(void) contextualFocus:(id)sender {
    _contextualFocus = sender;
    [[self parentController] contextualFocus:self];
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)OutlineDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
    if (rowsSelected!=nil && [rowsSelected count]>0) {
        NSUInteger index = [rowsSelected firstIndex];
        TreeItem * node = [_myOutlineView itemAtRow:index];
        if ([node isFolder]) { // It is a Folder : Will make it a root
            if ([BaseDirectories replaceItem:_rootNodeSelected with:node]) {
                /* This is needed to force the update of the path bar on setPathBarToItem.
                 other wise the pathupdate will not be done, since the OutlineViewSelectionDidChange,
                 that was called prior to this method will update _treeNodeSelected. */
                _treeNodeSelected = nil;
                [self selectFolderByItem:node];
                [self.detailedViewController refresh];
            }
            else
                NSLog(@"BrowserController.OutlineDoubleClickEvent: - Root not found '%@'",node);
        }
        else // When other types are allowed in the tree view this needs to be completed
            NSLog(@"BrowserController.OutlineDoubleClickEvent: - Unknown Class '%@'", node);
    }
}


/* Called from the pop up button.  */
- (IBAction) ChooseDirectory:(id)sender {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSApp sendAction:@selector(contextualGotoFolder:) to:nil from:self];
#pragma clang diagnostic pop

}

-(void) adjustViewSelectionAfterTreeViewChange {
    BOOL treeColapsed = self.treeViewCollapsed;
    
    if (treeColapsed) {
        //  Moves Selection to Table
        [self focusOnLastView];
        //Updates the status information
        [self selectionDidChangeOn:self.detailedViewController];
    }
    else
    {
        // Moves Selection to Tree
        [self focusOnFirstView];
        // Updates the status information based on the contents of the tree
        [self selectionDidChangeOn:self];
    }
}

-(void) setTreeViewCollapsed:(BOOL) collapsed {
    if (collapsed)
        // TODO:1.4 Save width in preferences @"TreeWidth"
        
        [self->_mySplitView setPosition:0 ofDividerAtIndex:0];
    else {
        // TODO:1.4 Get this from user defaults
        CGFloat width = 200.0;
        NSNumber *prefWidth =[self.preferences objectForKey:@"TreeWidth"];
        if (prefWidth != nil) {
            width = [prefWidth floatValue];
        }
        [self->_mySplitView setPosition:width ofDividerAtIndex:0];
    }
    [self.viewOptionsSwitches setSelected:!collapsed forSegment:BROWSER_VIEW_OPTION_TREE_ENABLE];
}

-(BOOL) treeViewCollapsed {
    NSView *firstView = [[self->_mySplitView subviews] objectAtIndex:0];
    return [self->_mySplitView isSubviewCollapsed:firstView];
}

-(void) setFlatView:(BOOL) flatView {
    BOOL foldersDisplayed;
    if (flatView) {
        foldersDisplayed = NO;
        // In no groupings defined, use COL_LOCATION
        if (NO == [(NodeSortDescriptor*)[self.detailedViewController.sortAndGroupDescriptors firstObject] isGrouping]) {
            [self.detailedViewController makeSortOnFieldID:@"COL_LOCATION" ascending:YES grouping:YES];
        }
    }
    else {
        foldersDisplayed = [self foldersDisplayedMacro];
        
        // if COL_LOCATION grouping, cancel
        [self.detailedViewController removeSortOnField:@"COL_LOCATION"];
    }
    
    [self.detailedViewController setFoldersDisplayed:foldersDisplayed];
    [self.detailedViewController setDisplayFilesInSubdirs:flatView];
    [self.viewOptionsSwitches setSelected:flatView forSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS];
}

-(BOOL) flatView {
    return self.detailedViewController.filesInSubdirsDisplayed;
}

- (IBAction)optionsSwitchSelect:(id)sender {
    NSInteger selectedSegment = [sender selectedSegment];
    BOOL isSelected = [self.viewOptionsSwitches isSelectedForSegment:selectedSegment];
    if (selectedSegment==BROWSER_VIEW_OPTION_TREE_ENABLE) {
        // TODO:? Animate collapsing and showing of the treeView
        if (isSelected) {
            // Adding the tree view
            [self->_mySplitView setPosition:200 ofDividerAtIndex:0];
            //[self->_myTreeViewEnableButton setSelected:NO forSegment:0];
        }
        else {
            // Collapsing the tree view
            [self->_mySplitView setPosition:0 ofDividerAtIndex:0];
            //[self->_myTreeViewEnableButton setSelected:YES forSegment:0];
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:kViewChanged_TreeCollapsed forKey:kViewChangedWhatKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationViewChanged object:self userInfo: userInfo];
        
        [self adjustViewSelectionAfterTreeViewChange];
    }
    else if (selectedSegment==BROWSER_VIEW_OPTION_FLAT_SUBDIRS) {
        [self setFlatView:isSelected];
        if (isSelected) { // If it is activated, it suffices the order the expansion.
                          // The refresh will be triggered by the KVO reload
            [self.detailedViewController startBusyAnimationsDelayed];
            // Send notification for App Delegate to execute this task
            // For feedback reasons it has to be done in appOperations
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  opFlatOperation, kDFOOperationKey,
                                  self, kDFOFromViewKey, // The view is sent because the operation can take longer and selected view can change
                                  self.detailedViewController.currentNode, kDFODestinationKey, // This has to be placed in last because it can be nil
                                  nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
        }
        else {
            // refreshes the view
            [self.detailedViewController refreshKeepingSelections];
        }
        // Send notificationViewChanged for the FlatView
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:kViewChanged_FlatView forKey:kViewChangedWhatKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationViewChanged object:self userInfo: userInfo];
        
    }
    else
        NSAssert(NO, @"Invalid Segment Number");
}


- (IBAction)mruBackForwardAction:(id)sender {
    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
    if (backOrForward==0) { // Backward
        [self backSelectedFolder];
    }
    else {
        [self forwardSelectedFolder];
    }
}


- (IBAction)PathSelect:(id)sender {
    NSURL *newURL;
    if ([sender isKindOfClass:[NSPopUpButton class]]) {
        NSInteger menutag = [(NSPopUpButton*)sender selectedTag];
        if (menutag>=0) { // if it is less than 0 it doesn't do anything
            NSRange rng = {0, menutag+1};
            NSArray *pathComponents = [[_rootNodeSelected url] pathComponents];
            newURL = [NSURL fileURLWithPathComponents:[pathComponents subarrayWithRange:rng ]];
        }
    }
    else {
        NSPathComponentCell *selectedPath =[_myPathBarControl clickedPathComponentCell];
        newURL = [selectedPath URL];
    }
    /* Gets the clicked Cell */
    if (newURL!=nil) {
        TreeBranch *node = [self getItemByURL: newURL];
        if (NULL == node ) {
            /* The path is not contained existing roots */
            if (_viewMode==BViewBrowserMode) {
                /* Will get a new node from shared tree Manager and add it to the root */
                /* This addTreeBranchWith URL will retrieve from the treeManager if not creates it */
                node = [appTreeManager addTreeItemWithURL:newURL askIfNeeded:YES];
                if (node) { // sanity check
                    [BaseDirectories removeItemAtIndex:0];
                    [self addTreeRoot:node];
                }
                else { // if it doesn't exist then put it back as it was
                    node = [BaseDirectories branchAtIndex:0];
                }
            }
        }
        if (NULL != node){
            [self selectFolderByItem:node];
        }
    }
}

- (IBAction)FilterChange:(id)sender {
    self.detailedViewController.filterText = [sender stringValue];
    [self.detailedViewController refreshKeepingSelections];
}


#pragma mark - Drag and Drop Support
/*
 * Drag and Drop Methods
 */

#ifdef USE_TREEITEM_PASTEBOARD_WRITING
- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    return (id <NSPasteboardWriting>) item;
}
#else
- (BOOL)outlineView:(NSOutlineView *)outlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:supportedPasteboardTypes()
                   owner:nil];


    NSArray* urls  = [items valueForKeyPath:@"@unionOfObjects.url"];
    return[ pboard writeObjects:urls];
}
#endif


- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    _draggedOutlineItem = [draggedItems firstObject]; // Only needs to store the one Item
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
#ifdef UPDATE_TREE
    // This is not needed if the FSEvents is activated and updates the Tables
    NSPasteboard *pboard = [session draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    TreeBranch *parent = [outlineView parentForItem:_draggedOutlineItem];
    NSUInteger idx = [outlineView rowForItem:_draggedOutlineItem] - [outlineView rowForItem:parent];
    _draggedItemsIndexSet = [NSIndexSet indexSetWithIndex:idx];
    if (operation == (NSDragOperationMove)) {
        [outlineView removeItemsAtIndexes:_draggedItemsIndexSet inParent:parent withAnimation:NSTableViewAnimationEffectFade];
    }
    else if (operation ==  NSDragOperationDelete) {
        // Send to RecycleBin.
        [outlineView removeItemsAtIndexes:_draggedItemsIndexSet inParent:parent withAnimation:NSTableViewAnimationEffectFade];
        sendItemsToRecycleBin(files);
    }
#endif
}



- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (item!=nil) {
        _validatedDropDestination = item;
        NSDragOperation dragOperations =[item supportedPasteOperations:info];
        _validatedDropOperation = selectDropOperation(dragOperations);
        return _validatedDropOperation;
    }
    return NSDragOperationNone;
}




- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    
    return (nil != [self->_validatedDropDestination acceptDropped:info operation:self->_validatedDropOperation sender:self]);
}

#pragma mark - KVO Methods

- (void) reloadItem:(id)object {
    //NSLog(@"Reloading %@", [object path]);
    NSInteger row = [_myOutlineView rowForItem:object];
    if (row >= 0 && row != -1) {
        // If it was deleted
        if ([object hasTags:tagTreeItemRelease]) {
            NSUInteger level = [_myOutlineView levelForRow:row];

            if (level==0) { // Its on the root
                [BaseDirectories removeChild:object];

            }

            // TODO:? Animate updates on the TreeView
            // Idea is have a separate method that replaces reloadData
            // This method will cycle through all the rows and check if they exist on the
            // DataSource. If they don't it will be deleted.
            // On the same method, check whether new items were added to the data.
            // Pondering on the solution of having two tagFlags for Observed on Right/Left

//            This was a nice idea, but at this point the index is not easy to find since the
//            object was already deleted from the array
//            [_myOutlineView beginUpdates];
//            // test if it is on the root
//            if (level==0) { // Its on the root
//                NSInteger index = [BaseDirectoriesArray indexOfObject:object];
//                [_myOutlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]
//                                            inParent:nil
//                                       withAnimation:NSTableViewAnimationEffectFade];
//            }
//            else {
//                // Calculate index
//                TreeBranch *parent = [_myOutlineView parentForItem:object];
//                NSInteger index = [parent indexOfItem:object];
//                [_myOutlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]
//                                            inParent:parent
//                                       withAnimation:NSTableViewAnimationEffectFade];
//            }
//            [_myOutlineView endUpdates];

            // forces the refresh of
            [_myOutlineView reloadData];
        }
        else {
            NSTableCellView *nameView = [_myOutlineView viewAtColumn:0 row:row makeIfNecessary:YES];
            if (nameView!=nil)  {
                if ([object hasTags:tagTreeItemDirty]) {
                    [nameView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped
                }
                else {
                    [nameView.textField setTextColor:[NSColor textColor]]; // Set color back to normal
                }
            }
            else {
                NSLog(@"BrowserController.reloadItem: ERROR! View Not Found");
            }
            [_myOutlineView reloadItem:object reloadChildren:YES];

        }
    }
    if (object == _treeNodeSelected) {
        // test if the object was released
        if ([object hasTags:tagTreeItemRelease]) {
            //NSLog(@"Reloading Released %@", [object path]);

            // Tries to jump into a valid parent
            TreeItem *parent = [(TreeItem*)object parent];
            while (parent !=nil && [parent hasTags:tagTreeItemRelease]){
                parent = [parent parent];
            }
            if (parent) {
                // found a parent, try to select it
                BOOL OK = [self selectFolderByItem:parent];
                if (!OK) {
                    [self addTreeRoot:(TreeBranch*)parent];
                    [self selectFolderByItem:parent];
                }
            }
            else {
                // parent not found. Detect if the root has disappeard
                if ([_rootNodeSelected hasTags:tagTreeItemRelease]) {
                    NSUInteger idx = [BaseDirectories indexOfItem:_rootNodeSelected];
                    [BaseDirectories removeItemAtIndex:idx];
                    if ([BaseDirectories numberOfItemsInNode]>0) {
                        if (idx>0)
                            idx--;
                        else
                            idx=0;
                        [self selectFolderByItem:[BaseDirectories itemAtIndex:idx]];
                    }
                    else {
                        // Nothing else to do. Just clear the View
                        // another options would be to revert to Home directory
                        _treeNodeSelected = nil;
                        _rootNodeSelected = nil;
                        // The path bar and pop menu should be updated accordingly.
                        [self setCurrentNode:nil];
                        [self.detailedViewController refresh];
                        [self.myOutlineView reloadData];

                    }
                }
            }
        }
        //else {
        //    /*If it is the selected Folder make a refresh*/
        //    [self.detailedViewController refreshKeepingSelections];
        //}
    }
    //else { The detail view maintains its own observer and will reload the object
    //    // Will see if there anything to reload on the detailed view
    //    [self.detailedViewController reloadItem:object];
    //}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kvoTreeBranchPropertyChildren]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(reloadItem:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
    else if ([keyPath isEqualToString:USER_DEF_SEE_HIDDEN_FILES] ||
             [keyPath isEqualToString:USER_DEF_BROWSE_APPS] ||
             [keyPath isEqualToString:USER_DEF_CALCULATE_SIZES]) {
        //NSLog(@"BrowserController.observeValueForKeyPath: %@", keyPath);
        [self startAllBusyAnimations];
        [self.treeNodeSelected refresh];
        [self refresh];
    }
    else if ([keyPath isEqualToString:USER_DEF_HIDE_FOLDERS_WHEN_TREE]) {
        [self.detailedViewController setFoldersDisplayed: self.foldersDisplayedMacro];
        [self.detailedViewController refreshKeepingSelections];
    }
}

-(void) observeItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([item isFolder]) {
        if (![_observedVisibleItems containsObject:item]) {
            [item addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
            [_observedVisibleItems addObject:item];
            //NSLog(@"Adding Observer to %@, %lu", [item name], (unsigned long)[_observedVisibleItems count]);
        }
    }
}

-(void) unobserveItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([item isFolder]) {
        if ([_observedVisibleItems containsObject:item]) {
            [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
            [_observedVisibleItems removeObject:item];
            //NSLog(@"Remove Observer to %@, %lu", [item name], (unsigned long)[_observedVisibleItems count]);
        }
    }
}

-(void) unobserveAll {
    for (TreeBranch* item in _observedVisibleItems) {
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
    }
    [_observedVisibleItems removeAllObjects];
}

#pragma mark - NSControlTextDelegate Protocol

- (void)keyDown:(NSEvent *)theEvent {
    // Get the origin
    id sentView = [self.view.window firstResponder];
    NSString *key = [theEvent characters];
    NSString *keyWM = [theEvent charactersIgnoringModifiers];

    if (sentView == _myOutlineView) {
        NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVIOUR] ;

        if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
            ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
        {
            [self OutlineDoubleClickEvent:theEvent];
        }

        else if ([keyWM isEqualToString:@"\t"]) {
            // the tab key will switch Panes
            if (self.focusedView == [self.detailedViewController containerView]) {
                [[self parentController] focusOnNextView:self];
            }
            else {
                [self focusOnLastView];
            }
        }
        else if ([key isEqualToString:@"\x19"]) {
            if ((self.focusedView == [self.detailedViewController containerView]) && ([self.viewOptionsSwitches isSelectedForSegment:BROWSER_VIEW_OPTION_TREE_ENABLE])) {
                [self focusOnFirstView];
            }
            else {
                [[self parentController] focusOnPreviousView:self];
            }
        }
    }
}

- (void)cancelOperation:(id)sender {
    [_myFilterText setStringValue:@""];
    self.detailedViewController.filterText = @"";
    [self.detailedViewController refreshKeepingSelections];
}

#pragma mark - Interface Methods


/*
 * Parent access routines
 */

/* This routine is serving as after load initialization */

-(void) focusOnFirstView {
    if (self.treeViewCollapsed==NO) {
        // The Tree Outline View is selected
        if ([[_myOutlineView selectedRowIndexes] count]==0) {
            [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        [self.view.window makeFirstResponder:self.myOutlineView];
    }
    else {
        [self.detailedViewController focusOnFirstView];
    }
}

- (void) focusOnLastView {
    [self.detailedViewController focusOnLastView];
}

- (void) focusOnNextView:(id)sender {
    if (sender == _myOutlineView) {
        [self.view.window makeFirstResponder:self.detailedViewController.containerView];
    }
    else  {
        [self.parentController focusOnNextView:self];
    }
}

-(void) focusOnPreviousView:(id)sender {
    if (sender == _myOutlineView || [self.viewOptionsSwitches isSelectedForSegment:BROWSER_VIEW_OPTION_TREE_ENABLE]==NO) {
        [self.parentController focusOnPreviousView:self];
    }
    else {
        [self focusOnFirstView];
    }
}


-(void) setName:(NSString*)viewName TwinName:(NSString *)twinName {
    if (![self->_viewName isEqualToString:viewName]) {
        
        if (self->_viewName != nil) // Storing previous settings if the view Name is changed.
            [self savePreferences];
        
        self->_viewName = viewName;
        [self.detailedViewController setName:viewName twinName:twinName];
        // Setting the AutoSave Settings
        
        NSString *viewTypeStr = [viewName stringByAppendingString: @"Preferences"];
        [self.preferences removeAllObjects]; // This can pose problems if ever bindings are used.
        [self.preferences addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:viewTypeStr]];
        [self loadPreferences];
    }
    
    self->_twinName = twinName;
    
}

-(void) setViewType:(EnumBrowserViewType)viewType {
    NodeViewController *newController = nil;
    BOOL didLoadPreferences = YES;
    
    if (viewType==BViewTypeVoid) {
        viewType = [[self.preferences objectForKey:USER_DEF_PANEL_VIEW_TYPE] integerValue];
    }
    switch (viewType) {
        case BViewTypeVoid:
        case BViewTypeInvalid:
            viewType = BViewTypeTable; // This is the default
        case BViewTypeTable:
            if (tableViewController==nil) {
                tableViewController = [[TableViewController alloc] initWithNibName:@"TableViewController" bundle:nil];
                [tableViewController initController];
                [tableViewController setParentController:self];
                [tableViewController setName:self.viewName twinName:self->_twinName];
                didLoadPreferences = NO;
            }
            newController = tableViewController;
            [self.myGroupingPopDpwnButton setHidden:NO];
            [self.myColumnsPopDpwnButton  setHidden:NO];
            [self.viewOptionsSwitches setEnabled:YES forSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS];
            break;
        case BViewTypeBrowser:
            break;
        case BViewTypeIcon:
            if (iconViewController == nil) { // If not Loaded, load it
                iconViewController = [[IconViewController alloc] initWithNibName:@"IconView" bundle:nil];
                [iconViewController initController];
                [iconViewController setParentController:self];
                [iconViewController setName:self.viewName twinName:self->_twinName];
                didLoadPreferences = NO;
            }
            newController = iconViewController;
            [self.myGroupingPopDpwnButton setHidden:YES];
            [self.myColumnsPopDpwnButton  setHidden:YES];
            // Block Flat view and remove groupings
            [self.viewOptionsSwitches setEnabled:NO forSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS];
            [self.viewOptionsSwitches setSelected:NO forSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS];
            [newController setDisplayFilesInSubdirs:NO];
            [newController removeGroupings];
            break;
        default:
            break;
    }

    if (self.detailedViewController != newController && newController != nil)  {
        if (self.detailedViewController != nil) {
            // Saving the treeCollapsed, so that it can be recovered when the new view is loaded
            BOOL treeVisble = ![self treeViewCollapsed];
            [self.preferences setObject:[NSNumber numberWithBool:treeVisble] forKey: USER_DEF_TREE_VISIBLE ];
        }
        [self.detailedViewController unregisterDraggedTypes];
        
        NSView *newView = [newController view];

        if ([[self.mySplitView subviews] count]==2) { // Two views already being displayed
            NSView *oldView = [[self.mySplitView subviews] objectAtIndex:1];
            [self.mySplitView replaceSubview:oldView with:newView];
        }
        else {
            [self.mySplitView addSubview:newView];
        }
        [self.mySplitView displayIfNeeded];
        
        didLoadPreferences = NO;
        [newController registerDraggedTypes];
        self.detailedViewController = newController;
        [self.detailedViewController setFoldersDisplayed: self.foldersDisplayedMacro];
    }

    // Changing User Defaults
    self->_viewType = viewType;
    
    // Load Preferences
    if (didLoadPreferences==NO) {
        [self loadPreferences];
    }
    // Update Current View Type Preference
    [self.preferences setObject:[NSNumber numberWithInteger:viewType] forKey:USER_DEF_PANEL_VIEW_TYPE];
    [self.detailedViewController setDisplayFilesInSubdirs:
     [self.viewOptionsSwitches isSelectedForSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS]
     ];
    [self.detailedViewController setCurrentNode:_treeNodeSelected];
    [self.detailedViewController refresh];
    
}

- (EnumBrowserViewType) viewType {
    return self->_viewType;
}

-(void) setViewMode:(EnumBrowserViewMode)viewMode  {
    if (viewMode!=_viewMode) {
        [self removeAll];
        [self refresh];
        [self startAllBusyAnimations];
        _viewMode = viewMode;
    }
}
-(EnumBrowserViewMode) viewMode {
    return self->_viewMode;
}

-(void) savePreferences {
    //NSLog(@"BrowserController.savePreferences %@", self->_viewName);
    
    if (self->_viewName == nil) // Sanity Check
        return;
    
    if (self->iconViewController) {
         [self->iconViewController savePreferences: self.preferences];
    }
    if (self->tableViewController) {
        [self->tableViewController savePreferences:self.preferences];
    }
    
    [self.preferences setObject:[NSNumber numberWithBool:self.treeViewCollapsed==NO] forKey:USER_DEF_TREE_VISIBLE];
    
    NSString *prefKey = [self.viewName stringByAppendingString:@"Preferences"];
    [[NSUserDefaults standardUserDefaults] setObject:self.preferences forKey:prefKey];
}

-(void) loadPreferences {
    //NSLog(@"BrowserController.loadPreferences %@", self->_viewName);
    if (self->_viewName == nil) // Sanity Check
        return;
    
    [self.detailedViewController loadPreferencesFrom:self.preferences ];
    [self setTreeViewCollapsed: NO==[[self.preferences objectForKey: USER_DEF_TREE_VISIBLE ] boolValue]];
}

-(void) set_filterText:(NSString *) filterText {
    self.detailedViewController.filterText = filterText;
}


-(void) refresh {
    // Refresh first the Roots, deletes the ones tagged for deletion
    NSUInteger idx=0;
    while (idx < [BaseDirectories numberOfBranchesInNode]) {
        // Ideally this should pass to the TreeClasses. Keeping it here for the time being.
        TreeBranch *tree = [BaseDirectories branchAtIndex:idx];
        if ([tree hasTags:tagTreeItemRelease]) {  // Deletes the ones tagged for deletion.
            [BaseDirectories removeItemAtIndex:idx];
        }
        else { // Refreshes all the others
            // [tree setTag:tagTreeItemDirty];  // Only treeManager and operations should make items dirty
            [tree refresh];
            idx++;
        }
    }
    // Then the observed items
    for (TreeBranch *tree in _observedVisibleItems) {
        // But avoiding repeating the refreshes already done
        if ([BaseDirectories indexOfItem:tree ]==NSNotFound) {
            // [tree setTag:tagTreeItemDirty]; // Only treeManager and operations should make items dirty
            [tree refresh];
        }
    }

    if ([BaseDirectories numberOfBranchesInNode]==1) {
        // Expand the Root Node
        id itemToExpand = [BaseDirectories branchAtIndex:0];
        if (itemToExpand)
            [_myOutlineView expandItem:itemToExpand];
        else
            NSLog(@"BrowserController.refresh: ERROR! Item not found.");
    }
    [self stopBusyAnimations];
    [_myOutlineView reloadData];
    [self.detailedViewController refreshKeepingSelections];
}

-(void) cleanRefresh {
    [self.treeNodeSelected forceRefreshOnBranch];

}

-(void) addTreeRoot:(TreeBranch*)theRoot {
    if (theRoot!=nil) {
        [BaseDirectories addTreeItem: theRoot];
        
        /* Refresh the Trees so that the trees are displayed */
        //[self refreshTrees];
        /* Make the Root as selected */
        //[self selectFolderByURL:[theRoot url]];
    }
}

-(void) addFileCollection:(FileCollection*) collection {
    [BaseDirectories addFileCollection:collection];
}

-(void) setRoots:(NSArray*) rootDirectories {
    [BaseDirectories releaseChildren];
    for (TreeItem* root in rootDirectories) {
        [BaseDirectories addTreeItem:root];
    }
}

-(NSArray*) roots {
    return [BaseDirectories branchesInNode];
}

//-(void) removeRootWithIndex:(NSInteger)index {
//    [BaseDirectories removeItemAtIndex:index];
//}

-(void) removeRoot: (TreeBranch*) root {
    [BaseDirectories removeChild:root];
}

-(void) removeAll {
    if (BaseDirectories==nil)
        BaseDirectories = [[TreeCollection alloc] initWithURL:nil parent:nil];
    else {
        [self unobserveAll];
        [BaseDirectories releaseChildren];
    }
    if (self.detailedViewController!=nil)
        [self.detailedViewController setCurrentNode:nil]; // This cleans the view
    self->_treeNodeSelected = nil;
}




//-(NSURL*) getTreeViewSelectedURL {
//    NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
//    if ([rowsSelected count]==0)
//        return nil;
//    else {
//        // using collection operator to get the array of the URLs from the selected Items
//        return [[_myOutlineView itemAtRow:[rowsSelected firstIndex]] url];
//    }
//}


-(id) focusedView {
    return _focusedView;
}

-(NSArray*) getSelectedItems {
    NSArray* answer = nil;
    if (self.focusedView==_myOutlineView) {
        /* This is done like this so that not more than one folder is selected */
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        if (rowsSelected != nil && [rowsSelected count]!=0) {
            // TODO:? When more than one folder can be selected on the Tree, this code must be changed.
            id firstObject = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            NSAssert(firstObject!=nil, @"BrowserController.getSelectedItems. Received NIL object");
            answer = [NSArray arrayWithObject:firstObject];
        }
        else {
            answer = [[NSArray alloc] init]; // will send an empty array
        }
    }
    else
        answer = [self.detailedViewController getSelectedItems];
    return answer;
}

// Can select the current Node
- (NSArray*)getSelectedItemsForContextualMenu1 {
    NSArray* answer = nil; // This will send the last answer when further requests are done
    // The condition below is used to detect which table view is selected. 
    if (self->_contextualFocus == _myOutlineView) {
        if ([_myOutlineView clickedRow]==-1)
            answer = nil; // Not going to process this case
        else{
            answer = [NSArray arrayWithObject:[_myOutlineView itemAtRow:[_myOutlineView clickedRow]]];
        }

    }
    else
        answer = [self.detailedViewController getSelectedItemsForContextualMenu1];
    return answer;
}

// doesn't select the current Node
- (NSArray*)getSelectedItemsForContextualMenu2 {
    static NSArray* answer = nil; // This will send the last answer when further requests are done
    // The condition below is used to detect which table view is selected.
    if (self->_contextualFocus == _myOutlineView) {
        if ([_myOutlineView clickedRow]==-1)
            answer = nil; // Not going to process this case
        else{
            answer = [NSArray arrayWithObject:[_myOutlineView itemAtRow:[_myOutlineView clickedRow]]];
        }
        
    }
    else
        answer = [self.detailedViewController getSelectedItemsForContextualMenu2];
    return answer;
}

-(TreeItem*) getLastClickedItem {
    if (self.focusedView==_myOutlineView) {
        NSInteger row = [_myOutlineView clickedRow];
        if (row >=0) {
            // Returns the current selected item
            return [_myOutlineView itemAtRow:row];
        }
        else {
            // returns the root of the path
            return _rootNodeSelected;
        }
    }
    else {
        return [self.detailedViewController getLastClickedItem];
    }
}

-(void) outlineSelectExpandNode:(TreeBranch*) cursor {
    // Execute only if tree is shown
    if (![self treeViewCollapsed]) {
        int retries = 2;
        while (retries) {
            NSInteger row = [_myOutlineView rowForItem:cursor];
            if (row != -1) {
                [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                retries = 0; /* Finished, dont need to retry any more. */
            }
            else {
                retries--;
            }
            // The object was not found, will need to force the expand
            row = [_myOutlineView selectedRow];
            if (row == -1) {
                row = 0;
            }
            [_myOutlineView expandItem:[_myOutlineView itemAtRow:row]];
            [_myOutlineView reloadData];
        }
    }
}


-(TreeBranch*) selectFirstRoot {
    if (BaseDirectories!=nil && [BaseDirectories numberOfBranchesInNode]>=1) {
        TreeBranch *root = [BaseDirectories branchAtIndex:0];
        _rootNodeSelected = root;
        [self selectFolderByItem:root];
        [self stopBusyAnimations];
        [self outlineSelectExpandNode:root];
        return root;
    }
    return NULL;
}

-(BOOL) selectFolderByItem:(TreeItem*) treeNode {
    if (BaseDirectories!=nil && [BaseDirectories numberOfItemsInNode]>=1 && treeNode!=nil) {
        NSEnumerator *enumerator = [BaseDirectories itemsInNodeEnumerator];
        TreeBranch* root;
        while (root = [enumerator nextObject]) {
            if ([root canContainURL:[treeNode url]]){ // Search for Root Node
                _rootNodeSelected = root;
                TreeBranch *lastBranch = nil;
                NSArray *treeComps= [treeNode treeComponentsToParent:root];
                for (TreeItem *node in treeComps) {
                    if ([node isFolder])
                    {
                        [_myOutlineView expandItem:node];
                        [_myOutlineView reloadData];
                        lastBranch = (TreeBranch*)node;
                    }
                    else
                        lastBranch = nil;
                }
                if (lastBranch) {
                    [self setCurrentNode:lastBranch];
                    [self outlineSelectExpandNode:lastBranch];
                    [self.detailedViewController refresh];
                    return YES;
                }
            }
        }
    }
    return NO;
}

-(BOOL) selectFolderByURL:(NSURL*)theURL {
    TreeItem *item = [self getItemByURL:theURL];
    if (item==nil) {
        if (_viewMode == BViewBrowserMode) {
            // Replaces current root
            item = [appTreeManager addTreeItemWithURL:theURL askIfNeeded:YES];
            if (item != nil) {
                [BaseDirectories addTreeItem:item];
                return [self selectFolderByItem:item];
            }
        }
    }
    else {
        return [self selectFolderByItem:item];
    }
    return NO;
}

-(TreeBranch*) getRootWithURL:(NSURL*)theURL {
    if (theURL==nil)
        return NULL;
    
    NSEnumerator *enumerator = [BaseDirectories itemsInNodeEnumerator];
    TreeBranch* root;
    while (root = [enumerator nextObject]) {
        /* Checks if rootPath in root */
        if ([root canContainURL:theURL]) {
            /* The URL is already contained in this tree */
            return root;
        }
    }
    return NULL;
    
}

-(TreeItem*) getItemByURL:(NSURL*)theURL {
    if (theURL==nil)
        return NULL;
    NSEnumerator *enumerator = [BaseDirectories itemsInNodeEnumerator];
    TreeBranch* root;
    while (root = [enumerator nextObject]) {
        /* Checks if rootPath in root */
        if ([root canContainURL:theURL]) {
            /* The URL is already contained in this tree */
            return [root getNodeWithURL:theURL];
        }
    }
    return NULL;
}

-(void) stopBusyAnimations {
    [_myOutlineProgressIndicator setHidden:YES];
    [_myOutlineProgressIndicator stopAnimation:self];
    [self.detailedViewController stopBusyAnimations];
}

-(void) startAllBusyAnimations {
    [_myOutlineProgressIndicator setHidden:NO];
    [_myOutlineProgressIndicator startAnimation:self];
    [self.detailedViewController startBusyAnimations];
}

-(BOOL) startEditItemName:(TreeItem*)item  {
    if (_focusedView==self.detailedViewController) {
        return [self.detailedViewController startEditItemName:item];
    }
    else {
        NSInteger row = [self->_myOutlineView rowForItem:item];
        NSInteger column = [self->_myOutlineView columnWithIdentifier:COL_FILENAME];
        if (row >= 0) {
            [self->_myOutlineView editColumn:column row:row withEvent:nil select:YES];
            // Obtain the NSTextField from the view
            NSTextField *textField = [[self->_myOutlineView viewAtColumn:column row:row makeIfNecessary:NO] textField];
            assert(textField!=nil);
            // Recuperate the old filename
            NSString *oldFilename = [textField stringValue];
            // Select the part up to the extension
            NSUInteger head_size = [[oldFilename stringByDeletingPathExtension] length];
            NSRange selectRange = {0, head_size};
            [[textField currentEditor] setSelectedRange:selectRange];
            return YES;
        }
        return NO;
    }
}
-(void) insertItem:(id)item  {
    if (self.focusedView == _myOutlineView) {
        // Will change to the table view and make the edit there.
        [self focusOnLastView]; // Change to the Detailed View
        [self.detailedViewController insertItem:item];
    }
    else if (_focusedView==self.detailedViewController) {
        [self.detailedViewController insertItem:item];
    }
}

// This selector is invoked when the file was renamed or a New File was created
- (IBAction)filenameDidChange:(id)sender {
    NSInteger row = [self->_myOutlineView rowForView:sender];
    if (row != -1) {
        TreeItem *item = [self->_myOutlineView itemAtRow:row];
        NSString const *operation=nil;
        if ([item hasTags:tagTreeItemNew]) {
            operation = opNewFolder;
        }
        else {
            // If the name didn't change. Do Nothing
            if ([[sender stringValue] isEqualToString:[item name]]) {
                return;
            }
            operation = opRename;
        }
        NSArray *items = [NSArray arrayWithObject:item];

        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              items, kDFOFilesKey,
                              operation, kDFOOperationKey,
                              [sender stringValue], kDFORenameFileKey,
                              [item parent], kDFODestinationKey, // This has to be placed in last because it can be nil
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];

    }
}


#pragma mark - MRU Routines

-(void) backSelectedFolder {
    if (_mruPointer>0) {
        _mruPointer--;
        NSURL *url = _mruLocation[_mruPointer];
        [self selectFolderByURL:url];
        // Enable the forward Button
        [self.mruBackForwardControl setEnabled:YES forSegment:1];
    }
    if (self->_mruPointer==0) {
        // Disable the BackButton
        [self.mruBackForwardControl setEnabled:NO forSegment:0];
    }
}

-(void) forwardSelectedFolder {
    if (_mruPointer < [_mruLocation count]-1) {
        _mruPointer++;
        NSURL *url = _mruLocation[_mruPointer];
        [self selectFolderByURL:url];
        // Enable the Back Button
        [self.mruBackForwardControl setEnabled:YES forSegment:0];
    }
    if (self->_mruPointer == [_mruLocation count]-1) {
        // Disable the forward button
        [self.mruBackForwardControl setEnabled:NO forSegment:1];
    }
}

#pragma mark - MYViewProtocol
-(NSString *) title {
    TreeItem * selected;
    if ([self treeViewCollapsed]) {
        selected = self->_treeNodeSelected;
    }
    else {
        selected = self->_rootNodeSelected;
    }
    
    if ([selected respondsToSelector:@selector(url)]) {
        NSURL *url = [selected url];
        if ([[url pathComponents] count]==1)
            return pathFriendly(url);
        return [url lastPathComponent];
    }
    // When all else fails
    return [selected name];
}


-(NSString*) homePath {
    TreeItem * selected;
    if ([self treeViewCollapsed]) {
        selected = self->_treeNodeSelected;
    }
    else {
        selected = self->_rootNodeSelected;
    }
    
    if ([selected respondsToSelector:@selector(url)]) {
        return [[selected url] path];
    }
    // When all else fails
    return nil;
}

-(NSString*) debugDescription {
    return [NSString stringWithFormat:@"Browser Controller(%@) root:%@ selected:%@", self->_viewName, self->BaseDirectories, self->_treeNodeSelected ];
}

@end
