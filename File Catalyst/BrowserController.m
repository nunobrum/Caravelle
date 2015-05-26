//
//  BrowserController.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "BrowserController.h"
#import "FileUtils.h"

// TODO:!! Get rid of this class. Is not being used.
#import "FolderCellView.h"

#import "TreeItem.h"
#import "TreeLeaf.h"
#import "TreeBranch.h"
#import "TreeManager.h"
#import "TreeRoot.h"
#import "filterBranch.h"
#import "FileInformation.h"
#import "fileOperation.h"
#import "TableViewController.h"
#import "IconViewController.h"
#import "FileAttributesController.h"
#import "PasteboardUtils.h"


const NSUInteger maxItemsInBrowserPopMenu = 7;
const NSUInteger item0InBrowserPopMenu    = 0;


@interface BrowserController () {
    id _focusedView; // Contains the currently selected view
    id _contextualFocus; // Contains the element used for contextual menus
    NSMutableArray *_observedVisibleItems;
    /* Internal Storage for Drag and Drop Operations */
    NSDragOperation _validatedOperation; // Passed from Validate Drop to Accept Drop Method
    TreeBranch *_treeNodeSelected;
    TreeBranch *_rootNodeSelected;
    TreeItem *_validatedDestinationItem;
    BOOL _didRegisterDraggedTypes;
    BOOL _awakeFromNibConfigDone;
    TreeBranch *_draggedOutlineItem;
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
    self->BaseDirectoriesArray = [[NSMutableArray new] init];
    self->extendedSelection = nil; // Used in the extended selection mode
    self->_focusedView = nil;
    self->_viewMode = BViewModeVoid; // This is an invalid view mode. This forces the App to change it.
    self->_viewType = BViewTypeInvalid; // This is an invalid view type. This forces the App to change it.
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

        [[self myOutlineView] setAutosaveName:[self->_viewName stringByAppendingString:@"Outline"]];
        // The Outline view has no customizable settings
        [[self myOutlineView] setAutosaveTableColumns:YES];

        NSButtonCell *searchCell = [self.myFilterText.selectedCell searchButtonCell];
        NSImage *filterImage = [NSImage imageNamed:@"FilterIcon16"];
        [searchCell setImage:filterImage];

        self->_awakeFromNibConfigDone = YES;
    }
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
    // gets the pointer to the last position
    NSUInteger mruCount = [_mruLocation count];

    // if its the first just adds it
    if (mruCount==0) {
        [_mruLocation addObject:url];
    }
    // Then checking if its changing
    else if (![url isEqual:_mruLocation[_mruPointer]]) { // Don't want two URLS repeated in a sequence
        _mruPointer++;
        if (_mruPointer < mruCount) { // There where back movements before
            if (![url isEqual:_mruLocation[_mruPointer]]) { // not just moving forward
                NSRange follwingMRUs;
                follwingMRUs.location = _mruPointer+1;
                follwingMRUs.length = mruCount - _mruPointer - 1;
                _mruLocation[_mruPointer] = url;
                if (follwingMRUs.length!=0) {
                    [_mruLocation removeObjectsInRange:follwingMRUs];
                }
            }
            // There is no else : on else We are just moving forward
        }
        else
            [_mruLocation addObject:url]; // Adding to the last position
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
    NSView *firstView = [[self->_mySplitView subviews] objectAtIndex:0];
    BOOL collapsed = [self->_mySplitView isSubviewCollapsed:firstView];
    [self.viewOptionsSwitches setSelected:!collapsed forSegment:0];
    //NSLog(@"View:%@ splitViewDidResizeSubiews",_viewName);
}

#pragma mark - Tree Outline DataSource Protocol

/*
 * Tree Outline View Data Source Protocol
 */


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if(item==nil) {
        return [BaseDirectoriesArray count];
    }
    else {
        // Returns the total number of leafs
        return [item numberOfBranchesInNode];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    id ret;
    if (item==nil || [item isKindOfClass:[NSMutableArray class]])
        ret = [BaseDirectoriesArray objectAtIndex:index];
    else {
        ret = [item branchAtIndex:index];
    }
    if ([ret itemType] == ItemTypeBranch) {
        // Use KVO to observe for changes of its children Array
        [self observeItem:ret];
        if (_viewMode==BViewBrowserMode) {
            if ([(TreeBranch*)ret needsRefresh]) {
                [(TreeBranch*)ret refreshContentsOnQueue:browserQueue];
            }
        }
//        else {
//            [self refreshDataView];
//        }
    }
    return ret;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL answer=NO;
    if ([item isKindOfClass:[NSMutableArray class]]) /* If it is the BaseArray */
        answer = ([item count] > 1)  ? YES : NO;
    else if ([item itemType] == ItemTypeBranch) {
        answer = ([(TreeBranch*)item isExpandable]);
    }
    return answer;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView=nil;

    if ([[tableColumn identifier] isEqualToString:COL_FILENAME]) {
        if ([item itemType] == ItemTypeLeaf) {//if it is a file
            // This is not needed now since the Tree View is not displaying files in this application
        }
        else if ([item itemType] == ItemTypeBranch) { // it is a directory
            if (_viewMode!=BViewBrowserMode) {
                NSString *subTitle;
                cellView= [outlineView makeViewWithIdentifier:@"CatalystView" owner:self];
                subTitle = [NSString stringWithFormat:@"%ld Files %@",
                            (long)[(TreeBranch*)item numberOfLeafsInBranch],
                            [NSByteCountFormatter stringFromByteCount:[item filesize] countStyle:NSByteCountFormatterCountStyleFile]];
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

            if ([item hasTags:tagTreeItemDropped+tagTreeItemDirty]) {
                [cellView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped or dirty
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

// TODO: !! This doesn't seem to be used, but its needed.
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
//        if ([item itemType] == ItemTypeLeaf) {//if it is a file
//            // This is not needed now since the Tree View is not displaying files in this application
//        }
//        else if ([item itemType] == ItemTypeBranch && // it is a directory
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
 Can be used later to block access to private directories */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    // ??? Avoid selecting protected files
    return YES;
}

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
            TreeBranch *tb = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            if (tb != _treeNodeSelected) { // !!! WARNING This workaround might raise problems in the future depending on the implementation of the folder change notification. Best is to see why this function is being called twice.
                [self setPathBarToItem:tb];

                //[self refreshDataView];
                // Use KVO to observe for changes of its children Array
                if (_viewMode==BViewBrowserMode) {
                    if ([_treeNodeSelected needsRefresh]) {
                        [self.detailedViewController startBusyAnimations];
                        [(TreeBranch*)_treeNodeSelected refreshContentsOnQueue:browserQueue];
                        // This will automatically call for a refresh
                    }
                    else {
                        // No need to keep the selection here since the folder is being changed
                        [self.detailedViewController refresh];
                    }
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
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:[notification userInfo]];
    }
}

- (void) updateStatus:(NSDictionary *)status {
    [self.parentController updateStatus:status];
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
    NSArray *selectedFiles = [self getSelectedItemsForContextMenu];
    return writeItemsToPasteboard(selectedFiles, pboard, types);
}

//- (void)menuWillOpen:(NSMenu *)menu {
//    This is not needed. Keeping it for memory
//}


#pragma mark - Path Bar Handling
-(TreeBranch*) treeNodeSelected {
    return _treeNodeSelected;
}

-(void) setPathBarToItem:(TreeItem*)item {
    if (item != _treeNodeSelected) {
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
        NSURL *url;
        TreeBranch *node;
        if ([item itemType] == ItemTypeBranch) {
            node = (TreeBranch*)item;
        }
        else {
            node = (TreeBranch*)[item parent];
        }
        url = [node url];

        NSMutableArray *pathComponentCells = [NSMutableArray arrayWithArray:
                                              [self.myPathBarControl pathComponentCells]];
        NSUInteger currSize = [pathComponentCells count];

        NSArray *pathComponents = [url pathComponents];
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

        [self mruSet:url];
        _treeNodeSelected = node;
        [self.detailedViewController setCurrentNode:node];
    }
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
    NSUInteger index = [rowsSelected firstIndex];
    if (index!=NSNotFound) {
        id node = [_myOutlineView itemAtRow:index];
        if ([node itemType] == ItemTypeBranch) { // It is a Folder : Will make it a root
            index = [BaseDirectoriesArray indexOfObject:_rootNodeSelected];
            BaseDirectoriesArray[index] = node;

            /* This is needed to force the update of the path bar on setPathBarToItem.
             other wise the pathupdate will not be done, since the OutlineViewSelectionDidChange, 
             that was called prior to this method will update _treeNodeSelected. */
            _treeNodeSelected = nil;
            [self selectFolderByItem:node];
            [self.detailedViewController refresh];
        }
        else // TODO:! When other types are allowed in the tree view this needs to be completed
            NSLog(@"BrowserController.OutlineDoubleClickEvent: - Unknown Class '%@'", [node className]);
    }
}


/* Called from the pop up button.  */
- (IBAction) ChooseDirectory:(id)sender {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSApp sendAction:@selector(contextualGotoFolder:) to:nil from:self];
#pragma clang diagnostic pop

}

- (IBAction)optionsSwitchSelect:(id)sender {
    NSInteger selectedSegment = [sender selectedSegment];
    BOOL isSelected = [self.viewOptionsSwitches isSelectedForSegment:selectedSegment];
    if (selectedSegment==BROWSER_VIEW_OPTION_TREE_ENABLE) {
        // TODO:! Animate collapsing and showing of the treeView
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
    }
    else if (selectedSegment==BROWSER_VIEW_OPTION_FLAT_SUBDIRS) {
        [self.detailedViewController setDisplayFilesInSubdirs:isSelected];
        [self.detailedViewController refreshKeepingSelections];
    }
    else
        NSAssert(NO, @"Invalid Segment Number");
}

- (IBAction)viewTypeSelection:(id)sender {
    NSInteger newType = [(NSSegmentedControl*)sender selectedSegment ];
    [self setViewType:newType];
    [self.detailedViewController setDisplayFilesInSubdirs:
     [self.viewOptionsSwitches isSelectedForSegment:BROWSER_VIEW_OPTION_FLAT_SUBDIRS]
     ];
    [self.detailedViewController setCurrentNode:_treeNodeSelected];
    [self.detailedViewController refresh];
}

- (IBAction)mruBackForwardAction:(id)sender {
    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
    // TODO:!!! Disable Back at the beginning Disable Forward
    // Create isABackFlag for the forward highlight and to test the Back
    // isAForward will make sure that the Forward is highlighted
    // otherwise Forward is disabled and Back Enabled
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
                node = [appTreeManager addTreeItemWithURL:newURL];
                if (node) { // sanity check
                    [self removeRootWithIndex:0];
                    [self addTreeRoot:node];
                }
                else { // if it doesn't exist then put it back as it was
                    node = [BaseDirectoriesArray objectAtIndex:0];
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
        _validatedDestinationItem = item;
        _validatedOperation = validateDrop(info, item);
        return _validatedOperation;
    }
    return NSDragOperationNone;
}




- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    return acceptDrop(info, _validatedDestinationItem, _validatedOperation, self);
}

#pragma mark - KVO Methods

- (void) reloadItem:(id)object {
    //NSLog(@"Reloading %@", [object path]);
    NSInteger row = [_myOutlineView rowForItem:object];
    if (row >= 0 && row != NSNotFound) {
        // If it was deleted
        if ([object hasTags:tagTreeItemRelease]) {
            NSUInteger level = [_myOutlineView levelForRow:row];

            if (level==0) { // Its on the root
                [BaseDirectoriesArray removeObject:object];

            }

            // TODO:! Animate updates on the TreeView
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
//                NSInteger index = [parent indexOfChild:object];
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
            assert(nameView!=nil);
            if ([object hasTags:tagTreeItemDirty+tagTreeItemDropped]) {
                [nameView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped or dirty
            }
            else {
                [nameView.textField setTextColor:[NSColor textColor]]; // Set color back to normal
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
                    NSUInteger idx = [BaseDirectoriesArray indexOfObject:_rootNodeSelected];
                    [BaseDirectoriesArray removeObjectAtIndex:idx];
                    if ([BaseDirectoriesArray count]>0) {
                        idx = (idx>0) ? 0 : idx-1;
                        [self selectFolderByItem:[BaseDirectoriesArray objectAtIndex:idx]];
                    }
                    else {
                        // Nothing else to do. Just clear the View
                        // another options would be to revert to Home directory
                        _treeNodeSelected = nil;
                        _rootNodeSelected = nil;
                        // The path bar and pop menu should be updated accordingly.
                        [self setPathBarToItem:nil];
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
        [self performSelectorOnMainThread:@selector(reloadItem:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

-(void) observeItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([item itemType] == ItemTypeBranch) {
        if (![_observedVisibleItems containsObject:item]) {
            [item addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
            [_observedVisibleItems addObject:item];
            //NSLog(@"Adding Observer to %@, %lu", [item name], (unsigned long)[_observedVisibleItems count]);
        }
    }
}

-(void) unobserveItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([item itemType] == ItemTypeBranch) {
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
        NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVOUR] ;

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
            if ((self.focusedView == [self.detailedViewController containerView]) && ([self.viewOptionsSwitches isSelectedForSegment:0])) {
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
// TODO:! This routine should define the Column AutoSave
// (See TableView setAutosaveTableColumns:) maybe this can be set on the NIB editor

/* This routine is serving as after load initialization */

-(void) focusOnFirstView {
    if ([self.viewOptionsSwitches isSelectedForSegment:0]) {
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
    if (sender == _myOutlineView || [self.viewOptionsSwitches isSelectedForSegment:0]==NO) {
        [self.parentController focusOnPreviousView:self];
    }
    else {
        [self focusOnFirstView];
    }
}


-(void) setName:(NSString*)viewName TwinName:(NSString *)twinName {
    self->_twinName = twinName;
    self->_viewName = viewName;
    // Setting the AutoSave Settings

    NSString *viewTypeStr = [viewName stringByAppendingString: @"Preferences"];
    [self.preferences addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:viewTypeStr]];

    if (twinName==nil) { // there is no twin view
        self.contextualToMenusEnabled = [NSNumber numberWithBool:NO];
        self.titleCopyTo = @"Copy to...";
        self.titleMoveTo = @"Move to...";
        // TODO:!!! Make the copy To Dialog such like in Total Commander
    }
    else {
        self.contextualToMenusEnabled = [NSNumber numberWithBool:YES];
        self.titleCopyTo = [NSString stringWithFormat:@"Copy %@", twinName];
        self.titleMoveTo = [NSString stringWithFormat:@"Move %@", twinName];

    }
}

-(NSNumber*) validateContextualCopyTo {
    // I have to write this function because the binding actually overrides the automatic Menu Validation.
    BOOL allow;
    NSArray *itemsSelected = [self getSelectedItemsForContextMenu];
    if ((itemsSelected==nil) || ([itemsSelected count]==0))  // no selection, go for the selected view
        allow = NO;
    else
        allow = YES;

    return [NSNumber numberWithBool:allow];
}
-(NSNumber*) validateContextualMoveTo {
    // I have to write this function because the binding actually overrides the automatic Menu Validation.
    BOOL allow = YES;
    NSArray *itemsSelected = [self getSelectedItemsForContextMenu];
    if (itemsSelected==nil) {
        // If nothing was returned is selected then don't allow anything
        allow = NO;
    }
    else if ([itemsSelected count]==0) { // no selection, go for the selected view
        allow = NO;
    }
    else {
        // The file has to be read/write
        for (TreeItem *item in itemsSelected) {
            if ([item hasTags:tagTreeItemReadOnly]) {
                allow = NO;
                break;
            }
        }
    }
    return [NSNumber numberWithBool:allow];
}

-(void) setViewType:(BViewType)viewType {
    NodeViewController *newController = nil;

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
            }
            newController = tableViewController;
            [self.myGroupingPopDpwnButton setHidden:NO];
            break;
        case BViewTypeBrowser:
            break;
        case BViewTypeIcon:
            if (iconViewController == nil) { // If not Loaded, load it
                iconViewController = [[IconViewController alloc] initWithNibName:@"IconView" bundle:nil];
                [iconViewController initController];
                [iconViewController setParentController:self];
                [iconViewController setName:self.viewName twinName:self->_twinName];
            }
            newController = iconViewController;
            [self.myGroupingPopDpwnButton setHidden:YES];
            break;
        default:
            break;
    }

    if (self.detailedViewController != newController && newController != nil)  {
        [self.detailedViewController unregisterDraggedTypes];

        NSView *newView = [newController view];

        if ([[self.mySplitView subviews] count]==2) { // This is the first time
            NSView *oldView = [[self.mySplitView subviews] objectAtIndex:1];
            [self.mySplitView replaceSubview:oldView with:newView];
        }
        else {
            [self.mySplitView addSubview:newView];
        }
        [self.mySplitView displayIfNeeded];
        
        // Load Preferences
        // TODO: !!!! make the bindings to UserDefaults
        [newController setFoldersDisplayed:YES];

        [newController registerDraggedTypes];
        self.detailedViewController = newController;

        // Changing User Defaults
        self->_viewType = viewType;
        [self.myViewSelectorButton setSelectedSegment:viewType];
        [self.preferences setObject:[NSNumber numberWithInteger:viewType] forKey:USER_DEF_PANEL_VIEW_TYPE];
    }
}

- (BViewType) viewType {
    return self->_viewType;
}

-(void) setViewMode:(BViewMode)viewMode  {
    if (viewMode!=_viewMode) {
        [self removeAll];
        [self refresh];
        [self startAllBusyAnimations];
        _viewMode = viewMode;
    }
}
-(BViewMode) viewMode {
    return self->_viewMode;
}

-(void) set_filterText:(NSString *) filterText {
    self.detailedViewController.filterText = filterText;
}


-(void) refresh {
    if (_viewMode!=BViewBrowserMode) {
        // TODO:! In catalyst Mode, there is no automatic Update
    }
    else {
        // Refresh first the Roots, deletes the ones tagged for deletion
        NSUInteger idx=0;
        while (idx < [BaseDirectoriesArray count]) {
            TreeBranch *tree = [BaseDirectoriesArray objectAtIndex:idx];
            if ([tree hasTags:tagTreeItemRelease]) {  // Deletes the ones tagged for deletion.
                [BaseDirectoriesArray removeObjectAtIndex:idx];
            }
            else { // Refreshes all the others
                [tree setTag:tagTreeItemDirty];
                [tree refreshContentsOnQueue:browserQueue];
                idx++;
            }
        }
        // Then the observed items
        for (TreeBranch *tree in _observedVisibleItems) {
            // But avoiding repeating the refreshes already done
            if ([BaseDirectoriesArray indexOfObject:tree ]==NSNotFound) {
                [tree setTag:tagTreeItemDirty];
                [tree refreshContentsOnQueue:browserQueue];
            }
        }
    }
    if ([BaseDirectoriesArray count]==1) {
        // Expand the Root Node
        [_myOutlineView expandItem:BaseDirectoriesArray[0]];
    }
    [self stopBusyAnimations];
    [_myOutlineView reloadData];
    [self.detailedViewController refreshKeepingSelections];
}

-(void) addTreeRoot:(TreeBranch*)theRoot {
    if (theRoot!=nil) {
        BOOL answer = [self canAddRoot:[theRoot path]];
        if (answer == YES) {
            [BaseDirectoriesArray addObject: theRoot];
        }
        /* Refresh the Trees so that the trees are displayed */
        //[self refreshTrees];
        /* Make the Root as selected */
        //[self selectFolderByURL:[theRoot url]];
    }
}

-(void) removeRootWithIndex:(NSInteger)index {
    if (index < [BaseDirectoriesArray count]) {
        [BaseDirectoriesArray removeObjectAtIndex:index];
    }
    //[self refreshTrees];
}

-(void) removeRoot: (TreeRoot*) root {
    [BaseDirectoriesArray removeObjectIdenticalTo:root];
}

-(void) removeAll {
    if (BaseDirectoriesArray==nil)
        BaseDirectoriesArray = [[NSMutableArray alloc] init]; /* Garbage collection will release everything */
    else {
        [self unobserveAll];
        [BaseDirectoriesArray removeAllObjects];
    }
    if (self.detailedViewController!=nil)
        [self.detailedViewController setCurrentNode:nil]; // This cleans the view
}


// This method checks if a root can be added to existing set.
-(BOOL) canAddRoot: (NSString*) rootPath {
    enumPathCompare answer = pathsHaveNoRelation;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        answer =[root relationToPath: rootPath];
        if (answer!=pathsHaveNoRelation) break;
    }
    return answer==pathsHaveNoRelation;
}

//-(FileCollection *) concatenateAllCollections {
//    FileCollection *collection =[[FileCollection new] init];
//    // Will concatenate all file collections into a single one.
//    for (TreeRoot *theRoot in BaseDirectoriesArray) {
//        [collection concatenateFileCollection: [theRoot fileCollection]];
//    }
//    return collection;
//}

-(NSURL*) getTreeViewSelectedURL {
    NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
    if ([rowsSelected count]==0)
        return nil;
    else {
        // using collection operator to get the array of the URLs from the selected Items
        return [[_myOutlineView itemAtRow:[rowsSelected firstIndex]] url];
    }
}


-(id) focusedView {
    return _focusedView;
}

-(NSArray*) getSelectedItems {
    NSArray* answer = nil;
    if (self.focusedView==_myOutlineView) {
        /* This is done like this so that not more than one folder is selected */
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        if ([rowsSelected count]) {
            answer = [NSArray arrayWithObject:[_myOutlineView itemAtRow:[rowsSelected firstIndex]]];
        }
        else {
            answer = [[NSArray alloc] init]; // will send an empty array
        }
    }
    else
        answer = [self.detailedViewController getSelectedItems];
    return answer;
}

- (NSArray*)getSelectedItemsForContextMenu {
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
        answer = [self.detailedViewController getSelectedItemsForContextMenu];
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
        if (row == -1)
            row = 0;
        [_myOutlineView expandItem:[_myOutlineView itemAtRow:row]];
        [_myOutlineView reloadData];

    }
}


-(TreeBranch*) selectFirstRoot {
    if (BaseDirectoriesArray!=nil && [BaseDirectoriesArray count]>=1) {
        TreeBranch *root = BaseDirectoriesArray[0];
        _rootNodeSelected = root;
        [self setPathBarToItem:root];
        [self outlineSelectExpandNode:root];
        [self.detailedViewController refresh];
        return root;
    }
    return NULL;
}

-(BOOL) selectFolderByItem:(TreeItem*) treeNode {
    if (BaseDirectoriesArray!=nil && [BaseDirectoriesArray count]>=1 && treeNode!=nil) {

        for (TreeRoot *root in BaseDirectoriesArray) {
            if ([root canContainURL:[treeNode url]]){ // Search for Root Node
                _rootNodeSelected = root;
                TreeBranch *lastBranch = nil;
                NSArray *treeComps= [treeNode treeComponentsToParent:root];
                for (TreeItem *node in treeComps) {
                    if ([node itemType] == ItemTypeBranch)
                    {
                        [_myOutlineView expandItem:node];
                        [_myOutlineView reloadData];
                        lastBranch = (TreeBranch*)node;
                    }
                    else
                        lastBranch = nil;
                }
                if (lastBranch) {
                    [self setPathBarToItem:lastBranch];
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
            item = [appTreeManager addTreeItemWithURL:theURL];
            [BaseDirectoriesArray setObject:item atIndexedSubscript:0];
            [item setTag:tagTreeItemDirty];
            [self selectFolderByItem:item];
            return (NULL!=[self selectFirstRoot]);
        }
        else
            return NO;
    }
    else {
        return [self selectFolderByItem:item];
    }
}

-(TreeBranch*) getRootWithURL:(NSURL*)theURL {
    if (theURL==nil)
        return NULL;
    for(TreeRoot *root in BaseDirectoriesArray) {
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
    for(TreeRoot *root in BaseDirectoriesArray) {
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
        // TODO: !!!! when the focused view is the treeOutline
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

#pragma mark - MRU Routines

-(void) backSelectedFolder {
    if (_mruPointer>0) {
        _mruPointer--;
        NSURL *url = _mruLocation[_mruPointer];
        [self selectFolderByURL:url];
    }
}

-(void) forwardSelectedFolder {
    if (_mruPointer < [_mruLocation count]-1) {
        _mruPointer++;
        NSURL *url = _mruLocation[_mruPointer];
        [self selectFolderByURL:url];
    }
}

#pragma mark - MYViewProtocol
-(NSString *) title {
    NSURL *root_url = [_rootNodeSelected url];
    return [root_url lastPathComponent];
}



@end
