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
#import "FileAttributesController.h"

#define COL_FILENAME @"COL_NAME"
#define COL_TEXT_ONLY @"COL_TEXT"

//#define COL_DATE_MOD @"COL_DATE_MODIFIED"
//#define COL_SIZE     @"COL_SIZE"
//#define COL_PATH     @"COL_PATH"

//#define AVAILABLE_COLUMNS  COL_FILENAME, COL_DATE_MOD, COL_SIZE, COL_PATH
//#define SYSTEM_COLUMNS     COL_FILENAME
//#define DEFAULT_COLUMNS    COL_SIZE, COL_DATE_MOD

const NSUInteger maxItemsInBrowserPopMenu = 7;
const NSUInteger item0InBrowserPopMenu    = 0;


@interface BrowserController () {
    id _focusedView; // Contains the currently selected view
    NSMutableArray *tableData;
    NSSortDescriptor *TableSortDesc;
    NSMutableArray *_observedVisibleItems;
    NSOperationQueue *_browserOperationQueue;
    /* Internal Storage for Drag and Drop Operations */
    NSDragOperation _validatedOperation; // Passed from Validate Drop to Accept Drop Method
    TreeBranch *_treeNodeSelected;
    TreeBranch *_rootNodeSelected;
    TreeItem *_validatedDestinationItem;
    BOOL _didRegisterDraggedTypes;
    NSIndexSet *_draggedItemsIndexSet;
    TreeBranch *_draggedOutlineItem;
    NSMutableArray *_mruLocation;
    NSUInteger _mruPointer;
    NSMutableIndexSet *extendedSelection;
}

@end

@implementation BrowserController

#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self->BaseDirectoriesArray = [[NSMutableArray new] init];
    self->extendedSelection = nil; // Used in the extended selection mode
    self->_focusedView = nil;
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_viewMode = BViewModeVoid; // This is an invalid view mode. This forces the App to change it.
    self->_filterText = @"";
    self->TableSortDesc = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
    self->_didRegisterDraggedTypes = NO;
    _treeNodeSelected = nil;
    _rootNodeSelected = nil;
    _browserOperationQueue = [[NSOperationQueue alloc] init];
    _mruLocation = [[NSMutableArray alloc] init];
    _mruPointer = 0;
    
    // We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
    [_browserOperationQueue setMaxConcurrentOperationCount:2];

    //To Get Notifications from the Table Header
#ifdef COLUMN_NOTIFICATION
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(selectColumnTitles:)
                   name:notificationColumnSelect
                 object:_myTableViewHeader];
#endif
    // Use the myPathPopDownMenu outlet to get the maximum tag number
    // Now its fixed to a 7 as a constant see maxItemsInBrowserPopMenu
    return self;
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
        //NSLog(@"Index: %ld MinCoordinate: %f",(long)index, proposedCoordinate);
    }
    return constrainedCoordinate;
}

// -------------------------------------------------------------------------------
//	constrainMaxCoordinate:proposedCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    //if (index == ([[splitView subviews] count] - 2))
    //{
    //    constrainedCoordinate = proposedCoordinate - kMinContrainValue;
    //}
    //NSLog(@"MaxCoordinate: %f",proposedCoordinate);
    return constrainedCoordinate;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    // Use this notfication to set the select state of the button
    NSView *firstView = [[self->_mySplitView subviews] objectAtIndex:0];
    BOOL collapsed = [self->_mySplitView isSubviewCollapsed:firstView];
    [self->_treeEnableSwitch setSelected:!collapsed forSegment:0];
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
    if ([ret isKindOfClass:[TreeBranch class]]) {
        // Use KVO to observe for changes of its children Array
        [self observeItem:ret];
        if (_viewMode==BViewBrowserMode) {
            if ([(TreeBranch*)ret needsRefresh]) {
                [(TreeBranch*)ret refreshContentsOnQueue:_browserOperationQueue];
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
    else if ([item isKindOfClass:[TreeBranch class]]) {
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
        if ([item isKindOfClass:[TreeLeaf class]]) {//if it is a file
            // This is not needed now since the Tree View is not displaying files in this application
        }
        else if ([item isKindOfClass:[TreeBranch class]]) { // it is a directory
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
//        if ([item isKindOfClass:[TreeLeaf class]]) {//if it is a file
//            // This is not needed now since the Tree View is not displaying files in this application
//        }
//        else if ([item isKindOfClass:[TreeBranch class]] && // it is a directory
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
    if (item!=_treeNodeSelected) { //keep observing the selected folder
        [self unobserveItem:item];
    }
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
            [_myOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:
                                                     //OwnUTITypes
                                                     //(id)kUTTypeFolder,
                                                     NSFilenamesPboardType,
                                                     NSURLPboardType,
                                                     nil]];
            [_myTableView registerForDraggedTypes:[NSArray arrayWithObjects:
                                                   //OwnUTITypes
                                                   //(id)kUTTypeFolder,
                                                   //(id)kUTTypeFileURL,
                                                   NSFilenamesPboardType,
                                                   NSURLPboardType,
                                                   nil]];
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
                [self observeItem:_treeNodeSelected];
                if (_viewMode==BViewBrowserMode) {
                    if ([_treeNodeSelected needsRefresh]) {
                        [self startTableBusyAnimations];
                        [(TreeBranch*)_treeNodeSelected refreshContentsOnQueue:_browserOperationQueue];
                    }
                }
                // No need to keep the selection here since the folder is being changed
                [self refreshTableView];
            }
        }
        else {
            NSLog(@"BrowserController.outlineViewSelectionDidChange - More than one item Selected");
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:[notification userInfo]];
    }
}

#pragma mark - TableView Datasource Protocol

/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [tableData count];
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    NSTableRowView *rowView = [[NSTableRowView alloc] init];
//    id objectValue = [tableData objectAtIndex:row];
//    if ([objectValue isKindOfClass:[TreeItem class]]) {
//        TreeItem *theFile = objectValue;
//        if ([theFile hasTags:tagTreeItemMarked]) {
//            [rowView setBackgroundColor:[NSColor selectedTextBackgroundColor]];
//        }
//        else {
//            [rowView setBackgroundColor:[NSColor textBackgroundColor]];
//        }
//    }
//    return rowView;
//}

- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    id objectValue = [tableData objectAtIndex:rowIndex];
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [aTableColumn identifier];

    NSTableCellView *cellView = nil;

    if ([objectValue isKindOfClass:[TreeItem class]]) {
        TreeItem *theFile = objectValue;
        NSColor *foreground;
        if ([theFile hasTags:tagTreeItemMarked]) {
            foreground = [NSColor redColor];
        }
        else {
            foreground = [NSColor textColor];
        }

        if ([identifier isEqualToString:COL_FILENAME]) {
            // We pass us as the owner so we can setup target/actions into this main controller object
            cellView = [aTableView makeViewWithIdentifier:COL_FILENAME owner:self];
            [cellView setObjectValue:objectValue];

            // If it's a new file, then assume a default ICON
            if ([theFile hasTags:tagTreeItemNew]) {
                cellView.textField.stringValue = [theFile name];  // Display simply the name of the file;
                if ([theFile isKindOfClass:[TreeBranch class]])
                    cellView.imageView.objectValue = [NSImage imageNamed:@"GenericFolderIcon"];
                else
                    cellView.imageView.objectValue = [NSImage imageNamed:@"GenericDocumentIcon"];
            }

            else  {
                NSString *path = [[theFile url] path];
                if (path) {
                    // Then setup properties on the cellView based on the column
                    cellView.textField.stringValue = [theFile name];  // Display simply the name of the file;
                    cellView.imageView.objectValue = [theFile image];

                    // Setting the color
                    if ([theFile hasTags:tagTreeItemDropped+tagTreeItemDirty]) {
                        [cellView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped or dirty
                    }
                    else {
                        // Set color back to normal
                        [cellView.textField setTextColor:foreground];

                    }
                }
                else {
                    // This is not supposed to happen, just setting an error
                    [cellView.textField setStringValue:@"-- ERROR %% Path is null --"];
                }
            }
        }

        else { // All other cases are handled here

            // We pass us as the owner so we can setup target/actions into this main controller object
            cellView = [aTableView makeViewWithIdentifier:COL_TEXT_ONLY owner:self];

            NSDictionary *colControl = [columnInfo() objectForKey:identifier];
            if (colControl!=nil) { // The column exists
                NSString *prop_name = colControl[COL_ACCESSOR_KEY];
                id prop = nil;
                @try {
                    prop = [objectValue valueForKey:prop_name];
                }
                @catch (NSException *exception) {
                    NSLog(@"BrowserController.tableView:viewForTableColumn:row - Property '%@' not found", prop_name);
                }

                if (prop){
                    if ([prop isKindOfClass:[NSString class]])
                        cellView.textField.objectValue = prop;
                    else { // Need to use one of the NSValueTransformers
                        NSString *trans_name = [colControl objectForKey:COL_TRANS_KEY];
                        if (trans_name) {
                            NSValueTransformer *trans=[NSValueTransformer valueTransformerForName:trans_name];
                            if (trans) {
                                NSString *text = [trans transformedValue:prop];
                                if (text)
                                    cellView.textField.objectValue = text;
                                else
                                    cellView.textField.objectValue = @"error transforming value";
                            }
                            else
                                cellView.textField.objectValue = @"invalid transformer";
                        }
                        else
                            cellView.textField.objectValue = @"no transformer found";
                    }
                }
                else
                    cellView.textField.objectValue = @"--";
            }
            else {
                cellView.textField.objectValue = @"Invalid Column";
            }


        //        if ([identifier isEqualToString:COL_SIZE]) {
        //        if (_viewMode==BViewBrowserMode && [theFile isKindOfClass:[TreeBranch class]]){
        //            //cellView.textField.objectValue = [NSString stringWithFormat:@"%ld Items", [(TreeBranch*)theFile numberOfItemsInNode]];
        //            cellView.textField.objectValue = @"--";
        //        }
        //        else
        //            cellView.textField.objectValue = [NSByteCountFormatter stringFromByteCount:[theFile filesize] countStyle:NSByteCountFormatterCountStyleFile];
        //
        //    } else if ([identifier isEqualToString:COL_DATE_MOD]) {
        //        NSString *result=nil;
        //        DateFormatter([theFile date_modified], &result);
        //        if (result == nil)
        //            cellView.textField.stringValue = NSLocalizedString(@"(Date)", @"Unknown Date");
        //        else
        //            cellView.textField.stringValue = result;
        //    }
        //    else {
        //        /* Debug code for further implementation */
        //        cellView.textField.stringValue = [NSString stringWithFormat:@"%@ %ld", aTableColumn.identifier, rowIndex];
        //    }
        }
        // other cases are not considered here. returning Nil
    }
    return cellView;
}

// -------------------------------------------------------------------------------
//	sortWithDescriptor:descriptor
// -------------------------------------------------------------------------------
- (void)sortWithDescriptor {
    if (TableSortDesc!=nil) {
        NSMutableArray *sorted = [[NSMutableArray alloc] initWithCapacity:1];
        [sorted addObjectsFromArray:[tableData sortedArrayUsingDescriptors:[NSArray arrayWithObject:TableSortDesc]]];
        [tableData removeAllObjects];
        [tableData addObjectsFromArray:sorted];
        [_myTableView reloadData];
    }
}


#pragma mark - TableView View Delegate Protocol

/*
 * Table Data View Delegate Protocol
 */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {

    if([[aNotification name] isEqual:NSTableViewSelectionDidChangeNotification ]){
        _focusedView = _myTableView;
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:[aNotification userInfo]];
    }
}

// -------------------------------------------------------------------------------
//	didClickTableColumn:tableColumn
// -------------------------------------------------------------------------------
- (void)tableView:(NSTableView *)inTableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    // TODO:!! if Control or Alt is presssed the new column is just added to the sortDescriptor
    // NSUInteger modifierKeys = [NSEvent modifierFlags];
    // test NSControlKeyMask and NSAlternateKeyMask

    NSArray *allColumns=[inTableView tableColumns];
	NSInteger i;
	for (i=0; i<[inTableView numberOfColumns]; i++)
	{
        /* Will delete all indicators from the remaining columns */
		if ([allColumns objectAtIndex:i]!=tableColumn)
		{
			[inTableView setIndicatorImage:nil inTableColumn:[allColumns objectAtIndex:i]];
		}
	}
	[inTableView setHighlightedTableColumn:tableColumn];
    NSString *key;
    if ([[tableColumn identifier] isEqualToString:COL_FILENAME])
        key = @"name";
    else // Else uses the identifier that is linked to the treeItem KVO property
        key = [[columnInfo() objectForKey:[tableColumn identifier]] objectForKey:COL_ACCESSOR_KEY];

	if ([inTableView indicatorImageInTableColumn:tableColumn] != [NSImage imageNamed:@"NSAscendingSortIndicator"])
	{
		[inTableView setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:tableColumn];
		TableSortDesc = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
        [self sortWithDescriptor];
	}
	else
	{
		[inTableView setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:tableColumn];
		TableSortDesc = [[NSSortDescriptor alloc] initWithKey:key ascending:NO];
		[self sortWithDescriptor];
	}
}

#ifdef COLUMN_NOTIFICATION

-(void) selectColumnTitles:(NSNotification *) note {
    // first checks the object sender is ours
    if ([note object]==_myTableViewHeader) {

        // Get the needed informtion from the notification
        NSString *changedColumnID = [[note userInfo] objectForKey:kColumnChanged];
        assert(changedColumnID); // Ooops! Problem in getting information from notification. Abort.
        NSInteger colHeaderClicked = [[[note userInfo] objectForKey:kReferenceViewKey] integerValue];
        NSDictionary *colInfo = [columnInfo() objectForKey:changedColumnID];

        assert (colInfo); // Checking Problem in getting
        // Checks whether to add or to delete a column
        if ([[self myTableView] columnWithIdentifier:changedColumnID]==-1) { // column not existing
            // It was added
            NSTableColumn *columnToAdd= [NSTableColumn alloc];
            columnToAdd = [columnToAdd initWithIdentifier:changedColumnID];
            [[columnToAdd headerCell] setStringValue:colInfo[COL_TITLE_KEY]];
            [[self myTableView] addTableColumn:columnToAdd];
            NSInteger lastColumn = [[self myTableView] numberOfColumns] - 1 ;
            if (colHeaderClicked>=0 && colHeaderClicked<lastColumn-1) { // -1 so to avoid calling a move to the same position
                [[self myTableView] moveColumn:lastColumn toColumn:colHeaderClicked+1]; // Inserts to the right
            }
        }
        else {
            // It was removed
            NSTableColumn *colToDelete = [[self myTableView] tableColumnWithIdentifier:changedColumnID];
            [[self myTableView] removeTableColumn:colToDelete];
        }
    }
}

#endif


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
    NSArray *typesDeclared;

    if ([types containsObject:NSFilenamesPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSFilenamesPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [self getSelectedItemsForContextMenu];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        NSArray *selectedPaths = [selectedURLs valueForKeyPath:@"@unionOfObjects.path"];
        return [pboard writeObjects:selectedPaths];
    }
    else if ([types containsObject:NSURLPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSURLPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedFiles = [self getSelectedItemsForContextMenu];
        NSArray *selectedURLs = [selectedFiles valueForKeyPath:@"@unionOfObjects.url"];
        return [pboard writeObjects:selectedURLs];
    }

    return NO;
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
        if ([item isKindOfClass:[TreeBranch class]]) {
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
    }
}


#pragma mark - Action Selectors

// TODO:!! Put here the code for the after Grouping/search button
- (IBAction)tableSelected:(id)sender {
    _focusedView = sender;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSApp sendAction:@selector(updateSelected:) to:nil from:self]; // to: Nil sends it to the Application Delegate
#pragma clang diagnostic pop

//    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:nil];
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)OutlineDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
    NSUInteger index = [rowsSelected firstIndex];
    if (index!=NSNotFound) {
        id node = [_myOutlineView itemAtRow:index];
        if ([node isKindOfClass: [TreeBranch class]]) { // It is a Folder : Will make it a root
            index = [BaseDirectoriesArray indexOfObject:_rootNodeSelected];
            BaseDirectoriesArray[index] = node;

            /* This is needed to force the update of the path bar on setPathBarToItem.
             other wise the pathupdate will not be done, since the OutlineViewSelectionDidChange, 
             that was called prior to this method will update _treeNodeSelected. */
            _treeNodeSelected = nil;
            [self selectFolderByItem:node];
        }
        else
            NSLog(@"BrowserController.OutlineDoubleClickEvent: - Unknown Class '%@'", [node className]);
    }
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)TableDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    NSUInteger index = [rowsSelected firstIndex];
    while (index!=NSNotFound) {
        /* Do something here */
        id node = [tableData objectAtIndex:index];;
        if ([node isKindOfClass: [TreeLeaf class]]) { // It is a file : Open the File
            [node openFile];
        }
        else if ([node isKindOfClass: [TreeBranch class]]) { // It is a directory
            // Going to open the Select That directory on the Outline View
            /* This also sets the node for Table Display and path bar */
            [self selectFolderByItem:node];

            // Use KVO to observe for changes of its children Array
            [self observeItem:_treeNodeSelected];
            if (_viewMode==BViewBrowserMode) {
                if ([_treeNodeSelected needsRefresh]) {
                    [self startTableBusyAnimations];
                    [_treeNodeSelected refreshContentsOnQueue:_browserOperationQueue];
                }
            }
            else {
                // No need to keep selection, since _treeNodeSelected is being updated
                [self refreshTableView];
            }
            break; /* Only one Folder can be Opened */
        }
        else
            NSLog(@"BrowserController.TableDoubleClickEvent: - Unknown Class '%@'", [node className]);
        index = [rowsSelected indexGreaterThanIndex:index];

    }
}


/* Called from the pop up button.  */
- (IBAction) ChooseDirectory:(id)sender {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSApp sendAction:@selector(contextualGotoFolder:) to:nil from:self];
#pragma clang diagnostic pop

}

// This selector is invoked when the file was renamed or a New File was created
- (IBAction)filenameDidChange:(id)sender {
    NSInteger row = [_myTableView rowForView:sender];
    if (row != -1) {
        TreeItem *item = [tableData objectAtIndex:row];
        NSString *operation=nil;
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
                              _treeNodeSelected, kDFODestinationKey,
                              self, kSourceViewKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];

    }
}

- (IBAction)treeViewEnable:(id)sender {
    BOOL treeEnable = [self->_treeEnableSwitch isSelectedForSegment:0];
    // TODO:! Animate collapsing and showing of the treeView
    if (treeEnable) {
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

- (IBAction)viewTypeSelection:(id)sender {

}

- (IBAction)mruBackForwardAction:(id)sender {
    NSInteger backOrForward = [(NSSegmentedControl*)sender selectedSegment];
    // TODO:!! Disable Back at the beginning Disable Forward
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
    _filterText = [sender stringValue];
    [self refreshTableViewKeepingSelections];
}


#pragma mark - Drag and Drop Support
/*
 * Drag and Drop Methods
 */

#define USE_TREEITEM_PASTEBOARD_WRITING
#ifdef USE_TREEITEM_PASTEBOARD_WRITING
- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    return (id <NSPasteboardWriting>) [tableData objectAtIndex:row];
}

- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    return (id <NSPasteboardWriting>) item;
}
#else

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObjects:
                             NSURLPboardType,
                             NSFilenamesPboardType,
                             // NSFileContentsPboardType, not passing file contents
                             NSStringPboardType, nil]
                      owner:nil];


    NSArray *items = [tableData objectsAtIndexes:rowIndexes];
    NSArray* urls  = [items valueForKeyPath:@"@unionOfObjects.url"];
    return[ pboard writeObjects:urls];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObjects:
                          NSURLPboardType,
                          NSFilenamesPboardType,
                          // NSFileContentsPboardType, not passing file contents
                          NSStringPboardType, nil]
                   owner:nil];


    NSArray* urls  = [items valueForKeyPath:@"@unionOfObjects.url"];
    return[ pboard writeObjects:urls];
}
#endif


- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
    _draggedItemsIndexSet = rowIndexes; // Save the Indexes for later deleting or moving
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    _draggedOutlineItem = [draggedItems firstObject]; // Only needs to store the one Item
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {

#ifdef UPDATE_TREE
    // This is not needed if the FSEvents is activated and updates the Tables
    NSPasteboard *pboard = [session draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    if (operation == (NSDragOperationMove)) {
        [tableView removeRowsAtIndexes:_draggedItemsIndexSet withAnimation:NSTableViewAnimationEffectFade];
    }
    else if (operation ==  NSDragOperationDelete) {
        // Send to RecycleBin.
        [tableView removeRowsAtIndexes:_draggedItemsIndexSet withAnimation:NSTableViewAnimationEffectFade];
        sendItemsToRecycleBin(files);
    }
#endif
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

- (NSDragOperation) validateDrop:(id < NSDraggingInfo >)info  {

    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSDragOperation  supportedMask = NSDragOperationNone;
    NSArray *ptypes;
    NSUInteger modifiers = [NSEvent modifierFlags];

    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    ptypes =[pboard types];

    /* Limit the options in function of the dropped Element */
    // The sourceDragMask should be an or of all the possiblities, and not the only first one.
    if ( [ptypes containsObject:NSFilenamesPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    if ( [ptypes containsObject:(id)NSURLPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    else if ( [ptypes containsObject:(id)kUTTypeFileURL] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#ifdef USE_UTI
    else if ( [ptypes containsObject:(id)kTreeItemDropUTI] ) {
        suportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#endif

    sourceDragMask &= supportedMask; // The offered types and the supported types.


    /* Limit the Operations depending on the Destination Item Class*/
    if ([_validatedDestinationItem isKindOfClass:[TreeBranch class]]) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    }
    else if ([_validatedDestinationItem isKindOfClass:[TreeLeaf class]]) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        sourceDragMask = NSDragOperationNone;
    }

    /* Use the modifiers keys to select */
    //if (modifiers & NSShiftKeyMask) {
    //}
    //TODO:!! Use Space to cycle through the options
    if (modifiers & NSAlternateKeyMask) {
        if (modifiers & NSCommandKeyMask) {
            if      (sourceDragMask & NSDragOperationLink)
                _validatedOperation=  NSDragOperationLink;
            else if (sourceDragMask & NSDragOperationGeneric)
                _validatedOperation=  NSDragOperationGeneric;
        }
        else {
            if      (sourceDragMask & NSDragOperationCopy)
                _validatedOperation=  NSDragOperationCopy;
            else if (sourceDragMask & NSDragOperationMove)
                _validatedOperation=  NSDragOperationMove;
            else if (sourceDragMask & NSDragOperationGeneric)
                _validatedOperation=  NSDragOperationGeneric;
            else
                _validatedOperation= NSDragOperationNone;
        }
        //if (modifiers & NSControlKeyMask) {
    }
    else {
        if      (sourceDragMask & NSDragOperationMove)
            _validatedOperation=  NSDragOperationMove;
        else if (sourceDragMask & NSDragOperationCopy)
            _validatedOperation=  NSDragOperationCopy;
        else if (sourceDragMask & NSDragOperationLink)
            _validatedOperation=  NSDragOperationLink;
        else if (sourceDragMask & NSDragOperationGeneric)
            _validatedOperation=  NSDragOperationGeneric;
        else
            _validatedOperation= NSDragOperationNone;
    }

    // TODO:!!! Implement the Link Operation
    if (_validatedOperation ==  NSDragOperationLink)
        _validatedOperation=  NSDragOperationNone;
    
    return _validatedOperation;
}


- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    if (operation == NSTableViewDropAbove) { // This is on the folder being displayed
        _validatedDestinationItem = _treeNodeSelected;
    }
    else if (operation == NSTableViewDropOn) {

        @try { // If the row is not valid, it will assume the tree node being displayed.
            _validatedDestinationItem = [tableData objectAtIndex:row];
        }
        @catch (NSException *exception) {
            _validatedDestinationItem = _treeNodeSelected;
        }
        @finally {
            // Go away... nothing to see here
        }
    }

    /* Limit the Operations depending on the Destination Item Class*/
    if ([_validatedDestinationItem isKindOfClass:[TreeBranch class]]) {
        // TODO:!!! Put here a timer for opening the Folder
        // Recording time and first time
        // if not first time and recorded time > 3 seconds => open folder
    }
    return [self validateDrop:info];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (item!=nil) {
        _validatedDestinationItem = item;
        return [self validateDrop:info];
    }
    return NSDragOperationNone;
}

- (BOOL) acceptDrop:(id < NSDraggingInfo >)info  {
    BOOL fireNotfication = NO;
    NSString *operation;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

    if ([_validatedDestinationItem isKindOfClass:[TreeLeaf class]]) {
        // TODO: !! Dropping Application on top of file or File on top of Application
        NSLog(@"BrowserController.acceptDrop: - Not impplemented Drop on Files");
        // TODO:! IDEA Maybe an append/Merge/Compare can be done if overlapping two text files
    }
    else if ([_validatedDestinationItem isKindOfClass:[TreeBranch class]]) {
        if (_validatedOperation == NSDragOperationCopy) {
            operation = opCopyOperation;
            fireNotfication = YES;
        }
        else if (_validatedOperation == NSDragOperationMove) {
            operation = opMoveOperation;
            fireNotfication = YES;

            // Check whether the destination item is equal to the parent of the item do nothing
            for (NSURL* file in files) {
                NSURL *folder = [file URLByDeletingLastPathComponent];
                if ([[_validatedDestinationItem path] isEqualToString:[folder path]]) // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs 
                {
                // If true : abort
                    fireNotfication = NO;
                    return fireNotfication;
                }
            }
        }
        else if (_validatedOperation == NSDragOperationLink) {
            // TODO: !!! Operation Link
        }
        else {
            // Invalid case
            fireNotfication = NO;
        }

    }
    if (fireNotfication==YES) {
        // The copy and move operations are done in the AppDelegate
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kDFOFilesKey,
                              operation, kDFOOperationKey,
                              _validatedDestinationItem, kDFODestinationKey,
                              self, kSourceViewKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)_validatedOperation);
    return fireNotfication;
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperationLocation {
    BOOL opDone = [self acceptDrop:info];

    if (_validatedDestinationItem == _treeNodeSelected && opDone==YES) {
        //Inserts the rows using the specified animation.
        if (_validatedOperation & (NSDragOperationCopy | NSDragOperationMove)) {
            NSPasteboard *pboard = [info draggingPasteboard];
            NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

            int i= 0;
            for (id pastedItem in files) {
                TreeItem *newItem=nil;
                if ([pastedItem isKindOfClass:[NSURL class]]) {
                    //[(TreeBranch*)targetItem addURL:pastedItem]; This will be done on the refresh after copy
                    newItem = [TreeItem treeItemForURL: pastedItem parent:_treeNodeSelected];
                    [newItem setTag:tagTreeItemDropped];
                }
                if (newItem) {
                    [tableData insertObject:newItem atIndex:row+i];
                    [aTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row+i] withAnimation:NSTableViewAnimationSlideDown]; //TODO:Try NSTableViewAnimationEffectGap
                    i++;
                }
            }
        }
    }
    return opDone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    return [self acceptDrop:info];
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
                    NSUInteger idx = [BaseDirectoriesArray indexOfObject:_treeNodeSelected];
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
                    }
                }
            }
        }
        else {
            /*If it is the selected Folder make a refresh*/
            // TODO:! Animate the updates (new files, deleted files)
            [self refreshTableViewKeepingSelections];
        }
    }
    else {
        // Will see if there anything to reload on the table
        NSInteger rowToReload = [tableData indexOfObject:object];
        if (rowToReload >=0  && rowToReload!=NSNotFound) {
            NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:rowToReload];
            NSRange columnsRange = {0, [[_myTableView tableColumns] count] };
            NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndexesInRange:columnsRange];
            [_myTableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
        }
    }
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
    if ([item isKindOfClass:[TreeBranch class]]) {
        if (![_observedVisibleItems containsObject:item]) {
            [item addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
            [_observedVisibleItems addObject:item];
            //NSLog(@"Adding Observer to %@, %lu", [item name], (unsigned long)[_observedVisibleItems count]);
        }
    }
}

-(void) unobserveItem:(TreeItem*)item {
    // Use KVO to observe for changes of its children Array
    if ([item isKindOfClass:[TreeBranch class]]) {
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

    if (sentView == _myTableView || sentView == _myOutlineView) {
        NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVOUR] ;

        if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
            ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
        {
            // The Return key will open the file
            if (self.focusedView == _myTableView) {
                [self TableDoubleClickEvent:theEvent];
            }
            else if (self.focusedView == _myOutlineView) {
                [self OutlineDoubleClickEvent:theEvent];
            }
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        else if ([keyWM isEqualToString:@"\t"]) {
            // the tab key will switch Panes
            if (self.focusedView == _myTableView) {
                [NSApp sendAction:@selector(gotoNextValidKeyView:) to:nil from:self];
            }
            else {
                [self.view.window makeFirstResponder:[self lastFocusView]];
            }
        }
        else if ([key isEqualToString:@"\x19"]) {
            if ((self.focusedView == _myTableView) && ([self.treeEnableSwitch isSelectedForSegment:0])) {
                [self.view.window makeFirstResponder:[self firstFocusView]];
            }
            else {
                [NSApp sendAction:@selector(gotoPreviousValidKeyView:) to:nil from:self];
            }

        }
#pragma clang diagnostic pop
        else if ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_MULTIPLATFORM ) {
            // the Space Key will mark the file
            // only works the TableView
            if (self.focusedView == _myTableView) {
                if (self->extendedSelection==nil) {
                    self->extendedSelection = [NSMutableIndexSet indexSet];
                }
                NSIndexSet *indexset = [_myTableView selectedRowIndexes];
                [indexset enumerateIndexesUsingBlock:^(NSUInteger index, BOOL * stop) {
                    id item = [self->tableData objectAtIndex:index];
                    if ([item isKindOfClass:[TreeItem class]]) {
                        [(TreeItem*)item toggleTag:tagTreeItemMarked];
                    }
                    if ([self->extendedSelection containsIndex:index])
                        [self->extendedSelection removeIndex:index];
                    else
                        [self->extendedSelection addIndex:index];
                }];

                // TODO:!!!! Check what is the preferred method
#ifdef REFRESH_ONLY_FILENAME
                // Only update the FileName Column
                NSIndexSet *colIndex = [NSIndexSet indexSetWithIndex:
                                        [self->_myTableView columnWithIdentifier:COL_FILENAME]];
#else
                NSRange columns = {0, [self->_myTableView numberOfColumns]};
                NSIndexSet *colIndex = [NSIndexSet indexSetWithIndexesInRange:columns];
#endif
                [self->_myTableView reloadDataForRowIndexes:indexset
                                              columnIndexes: colIndex];

            }
        }
    }
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    NSInteger row = [_myTableView rowForView:fieldEditor];
    if (row!=-1) {
        id item = [tableData objectAtIndex:row];

        // In order to allow the creation of new files
        if ([item hasTags:tagTreeItemNew])
            return YES;
        return [item hasTags:tagTreeItemReadOnly]==NO;
    }
    else
        return YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    //NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        // In cancel will check if it was a new File and if so, remove it
        NSInteger row =[_myTableView rowForView:fieldEditor];
        if (row!=-1) {
            id item = [tableData objectAtIndex:row];
            if ([item isKindOfClass:[TreeItem class]]) {
                if ([(TreeItem*)item hasTags:tagTreeItemNew]) {
                    NSIndexSet *rows2delete = [NSIndexSet indexSetWithIndex:row];
                    [_myTableView removeRowsAtIndexes:rows2delete
                                        withAnimation:NSTableViewAnimationEffectFade];
                }
            }
        }
    }

    return NO;
}
- (void)cancelOperation:(id)sender {
    [_myFilterText setStringValue:@""];
    _filterText = @"";
    [self refreshTableViewKeepingSelections];
}
#pragma mark - Interface Methods


/*
 * Parent access routines
 */
// TODO:! This routine should define the Column AutoSave
// (See TableView setAutosaveTableColumns:) maybe this can be set on the NIB editor

/* This routine is serving as after load initialization */

-(void) initBrowserView:(BViewMode)viewMode twin:(NSString*)twinName {
    [self setTwinName:twinName];
    viewMode = BViewModeVoid; // Forces the viewMode Update;
    [self setViewMode:viewMode];
}

-(NSView*) firstFocusView {
    if ([_treeEnableSwitch isSelectedForSegment:0]) {
        // The Tree Outline View is selected
        if ([[_myOutlineView selectedRowIndexes] count]==0) {
            [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        return self.myOutlineView;
    }
    else {
        if ([[_myTableView selectedRowIndexes] count]==0) {
            [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        return self.myTableView;
    }
}

- (NSView*) lastFocusView {
    if ([[_myTableView selectedRowIndexes] count]==0) {
        [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    return self.myTableView;
}

-(void) setTwinName:(NSString *)twinName {
    self->_twinName = twinName;
    if (twinName==nil) { // there is no twin view
        self.contextualToMenusEnabled = [NSNumber numberWithBool:NO];
        [[self myTableView] setAutosaveName:@"SingleTable"];
        self.titleCopyTo = @"Copy to ...";
        self.titleMoveTo = @"Move to ...";
    }
    else {
        self.titleCopyTo = [NSString stringWithFormat:@"Copy %@", twinName];
        self.titleMoveTo = [NSString stringWithFormat:@"Move %@", twinName];
        self.contextualToMenusEnabled = [NSNumber numberWithBool:YES];

        // Setting the AutoSave Settings
        [[self myTableView] setAutosaveName:[twinName stringByAppendingString:@"Table"]];
        [[self myTableView] setAutosaveTableColumns:YES];
        // The Outline view has no customizable settings
        //[[self myOutlineView] setAutosaveName:[twinName stringByAppendingString:@"Outline"]];
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


-(void) setViewMode:(BViewMode)viewMode {
    if (viewMode!=_viewMode) {
        [self removeAll];
        [self refresh];
        tableData = nil;
        [_myTableView reloadData];
        [self startAllBusyAnimations];
        _viewMode = viewMode;
    }
}
-(BViewMode) viewMode {
    return _viewMode;
}

-(id) getFileAtIndex:(NSUInteger)index {
    return [tableData objectAtIndex:index];
}

-(void) set_filterText:(NSString *) filterText {
    self->_filterText = filterText;
}


-(void) refreshTableView {
    NSMutableIndexSet *tohide = [[NSMutableIndexSet new] init];
    /* Always uses the _treeNodeSelected property to manage the Table View */
    if ([_treeNodeSelected isKindOfClass:[TreeBranch class]]){
        if (self->_extendToSubdirectories==YES && self->_foldersInTable==YES) {
            tableData = [(TreeBranch*)_treeNodeSelected itemsInBranch];
        }
        else if (self->_extendToSubdirectories==YES && self->_foldersInTable==NO) {
            tableData = [(TreeBranch*)_treeNodeSelected leafsInBranch];
        }
        else if (self->_extendToSubdirectories==NO && self->_foldersInTable==YES) {
            tableData = [(TreeBranch*)_treeNodeSelected itemsInNode];
        }
        else if (self->_extendToSubdirectories==NO && self->_foldersInTable==NO) {
            tableData = [(TreeBranch*)_treeNodeSelected leafsInNode];
        }

        /* if the filter is empty, doesn't filter anything */
        if ([self->_filterText length]!=0) {
            /* Create the array of indexes to remove/hide/disable*/
            NSInteger i = 0;
            for (TreeItem *item in tableData){
                NSRange result = [[item name] rangeOfString:_filterText];
                if (NSNotFound==result.location)
                    [tohide addIndex:i];
                i++;
            }
        }
        [tableData removeObjectsAtIndexes: tohide];
        [self sortWithDescriptor];
    }
    [self stopBusyAnimations];
    [_myTableView reloadData];
}

-(void) refreshTableViewKeepingSelections {
    // Storing Selected URLs
    NSArray *selectedURLs = [self getTableViewSelectedURLs];
    // Refreshing the View
    [self refreshTableView];
    // Reselect stored selections
    [self setTableViewSelectedURLs:selectedURLs];
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
                [tree refreshContentsOnQueue:_browserOperationQueue];
                idx++;
            }
        }
        // Then the observed items
        for (TreeBranch *tree in _observedVisibleItems) {
            // But avoiding repeating the refreshes already done
            if ([BaseDirectoriesArray indexOfObject:tree ]==NSNotFound) {
                [tree setTag:tagTreeItemDirty];
                [tree refreshContentsOnQueue:_browserOperationQueue];
            }
        }
    }
    if ([BaseDirectoriesArray count]==1) {
        // Expand the Root Node
        [_myOutlineView expandItem:BaseDirectoriesArray[0]];
    }

    [_myOutlineView reloadData];
    [self refreshTableViewKeepingSelections];
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
        [self unobserveItem:[BaseDirectoriesArray objectAtIndex:index]];
        [BaseDirectoriesArray removeObjectAtIndex:index];
    }
    //[self refreshTrees];
}

-(void) removeRoot: (TreeRoot*) root {
    [self unobserveItem:root];
    [BaseDirectoriesArray removeObjectIdenticalTo:root];
}

-(void) removeAll {
    if (BaseDirectoriesArray==nil)
        BaseDirectoriesArray = [[NSMutableArray alloc] init]; /* Garbage collection will release everything */
    else {
        [self unobserveAll];
        [BaseDirectoriesArray removeAllObjects];
    }
    tableData = nil;
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

-(NSArray*) getTableViewSelectedURLs {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    if ([rowsSelected count]==0)
        return nil;
    else {
        // using collection operator to get the array of the URLs from the selected Items
        NSArray *selectedItems = [tableData objectsAtIndexes:rowsSelected];
        if (selectedItems!=nil && [selectedItems count]>0) {
            return [selectedItems valueForKeyPath:@"@unionOfObjects.url"];
        }
        else {
            return nil;
        }
    }
}

-(void) setTableViewSelectedURLs:(NSArray*) urls {
    if (urls!=nil && [urls count]>0) {
        NSIndexSet *select = [tableData indexesOfObjectsPassingTest:^(id item, NSUInteger index, BOOL *stop){
            //NSLog(@"setTableViewSelectedURLs %@ %lu", [item path], index);
            if ([urls indexOfObject:[item url]]!=NSNotFound)
                return YES;
            else
                return NO;
        }];
        [_myTableView selectRowIndexes:select byExtendingSelection:NO];
    }
}

-(id) focusedView {
    // Get the first responder view
    id responderView = [self.view.window firstResponder];

    // Check whether is one of the accepted views
    if (responderView==_myOutlineView) {
        _focusedView = _myOutlineView;
    }
    else if (responderView == _myTableView) {
        _focusedView = _myTableView;
    }
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
    else if (self.focusedView == _myTableView) {
        NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
        answer = [tableData objectsAtIndexes:rowsSelected];
    }
    return answer;
}

- (NSArray*)getSelectedItemsForContextMenu {
    static NSArray* answer = nil; // This will send the last answer when further requests are done

    /*NSInteger outlineClickedRow =[_myOutlineView clickedRow];
    NSInteger tableClickedRow =[_myTableView clickedRow];
    NSInteger outlineRightClickedRow = [_myOutlineView rightMouseLocation];
    NSInteger tableRightClickedRow = [_myTableView rightMouseLocation];
    NSLog(@"Clicked Row (%ld)-(%ld)\nRightClick (%ld)-(%ld)", outlineClickedRow, tableClickedRow, outlineRightClickedRow, tableRightClickedRow);*/

    // The condition below is used to detect which table view is selected. 
    if (self.focusedView == _myOutlineView) {
        if ([_myOutlineView clickedRow]==-1)
            answer = nil; // Not going to process this case
        else{
            answer = [NSArray arrayWithObject:[_myOutlineView itemAtRow:[_myOutlineView clickedRow]]];
        }

    }
    else if (self.focusedView == _myTableView) {
        // if the click was outside the items displayed
        if ([_myTableView clickedRow] == -1 ) {
            // it returns nothing
            answer = [NSArray array]; // It will return an empty selection
        }
        else {
            NSIndexSet *selectedIndexes = [_myTableView selectedRowIndexes];
            // If the clicked row was in the selectedIndexes, then we process all selectedIndexes. Otherwise, we process just the clickedRow
            if(![selectedIndexes containsIndex:[_myTableView clickedRow]]) {
                selectedIndexes = [NSIndexSet indexSetWithIndex:[_myTableView clickedRow]];
            }
            answer = [tableData objectsAtIndexes:selectedIndexes];
        }

    }
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
        NSInteger row = [_myTableView clickedRow];
        if (row >=0 && row < [tableData count]) {
            // Returns the current selected item
            return [tableData objectAtIndex:row];
        }
        else {
            // Returns the displayed folder
            return _treeNodeSelected;

        }
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
                    if ([node isKindOfClass:[TreeBranch class]] ||
                        [node isKindOfClass:[TreeRoot   class]])
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
                    [self refreshTableView];
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
    [_myFileViewProgressIndicator setHidden:YES];
	[_myOutlineProgressIndicator stopAnimation:self];
    [_myFileViewProgressIndicator stopAnimation:self];
}

-(void) startAllBusyAnimations {
    [_myOutlineProgressIndicator setHidden:NO];
    [_myFileViewProgressIndicator setHidden:NO];
	[_myOutlineProgressIndicator startAnimation:self];
    [_myFileViewProgressIndicator startAnimation:self];
}

-(void) startTableBusyAnimations {
    [_myFileViewProgressIndicator setHidden:NO];
    [_myFileViewProgressIndicator startAnimation:self];
}

-(BOOL) startEditItemName:(TreeItem*)item  {
    // TODO: when the focused view is the treeOutline
    if (self.focusedView==_myTableView) {
        NSUInteger row = [tableData indexOfObject:item];
        if (row!=NSNotFound) {
            NSUInteger column = [_myTableView columnWithIdentifier:COL_FILENAME];
            [_myTableView editColumn:column row:row withEvent:nil select:YES];
            // Obtain the NSTextField from the view
            NSTextField *textField = [[_myTableView viewAtColumn:column row:row makeIfNecessary:NO] textField];
            assert(textField!=nil);
            // Recuperate the old filename
            NSString *oldFilename = [textField stringValue];
            // Select the part up to the extension
            NSUInteger head_size = [[oldFilename stringByDeletingPathExtension] length];
            NSRange selectRange = {0, head_size};
            [[textField currentEditor] setSelectedRange:selectRange];
            return YES;
        }
    }
    return NO;
}
-(void) insertItem:(id)item  {
    NSInteger row = [tableData count];
    if (self.focusedView == _myOutlineView) {
        // Will change to the table view and make the edit there.
        _focusedView = _myTableView;
    }
    if (self.focusedView==_myTableView) {
        NSIndexSet *selection = [_myTableView selectedRowIndexes];
        if ([selection count]>0) {
            // Will insert a row on the bottom of the selection.
            row = [selection lastIndex] + 1;
        }
        else {
            row = [tableData count];
        }
    }
    // Making the new inserted line as selected
    [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];

    if (row < [tableData count]) {
        [tableData insertObject:item atIndex:row];
    }
    else {
        [tableData addObject:item];
    }
    [_myTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation: NSTableViewAnimationEffectNone]; //NSTableViewAnimationSlideDown, NSTableViewAnimationEffectGap
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
