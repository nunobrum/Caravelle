//
//  TableViewController.m
//  Caravelle
//
//  Created by Nuno Brum on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "TableViewController.h"
#import "CustomTableHeaderView.h"
#import "TreeItem.h"
#import "TreeBranch.h"
#import "TreeLeaf.h"
#import "PasteboardUtils.h"
#import "NodeSortDescriptor.h"
#import "BrowserController.h"
#import "CalcFolderSizes.h"


@interface TableViewController ( ) {
#ifdef UPDATE_TREE
    NSIndexSet *_draggedItemsIndexSet;
#endif
    NSMutableArray *observedTreeItemsForSizeCalculation;
}
@end

@implementation TableViewController {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.myTableView setUsesAlternatingRowBackgroundColors:[[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_TABLE_ALTERNATE_ROW]];
}

- (void)awakeFromNib
{
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:USER_DEF_TABLE_ALTERNATE_ROW options:NSKeyValueObservingOptionNew context:NULL];
    
}

-(void) setViewName:(NSString *)viewName {
    [super setViewName:viewName];
    //[[self myTableView] setAutosaveName:[self.viewName stringByAppendingString:@"Table"]];
    //[[self myTableView] setAutosaveTableColumns:YES];
}

- (void) initController {
    [super initController];
    observedTreeItemsForSizeCalculation = [[NSMutableArray alloc] init];
#ifdef UPDATE_TREE
    self->_draggedItemsIndexSet = nil;
#endif
    self->extendedSelection = nil;
    
    //To Get Notifications from the Table Header
#ifdef COLUMN_NOTIFICATION
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(selectColumnTitles:)
     name:notificationColumnSelect
     object:_myTableViewHeader];
#endif
}

- (NSView*) containerView {
    return self->_myTableView;
}


/*
 -(id) getFileAtIndex:(NSUInteger)index {
 return [tableData objectAtIndex:index];
 }
*/

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
     if ([keyPath isEqualToString:USER_DEF_TABLE_ALTERNATE_ROW]) {
        [self.myTableView setUsesAlternatingRowBackgroundColors:[[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_TABLE_ALTERNATE_ROW]];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - TableView Datasource Protocol

/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self->_displayedItems count];
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    NSTableRowView *rowView = [[NSTableRowView alloc] init];
//    id objectValue = [self->_displayedItems objectAtIndex:row];
//    return rowView;
//}


- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    id objectValue = [self->_displayedItems objectAtIndex:rowIndex];
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    
    
    NSDictionary *colControl = [columnInfo() objectForKey:[aTableColumn identifier]];
    NSString *identifier = [colControl objectForKey:COL_COL_ID_KEY];
    if (identifier==nil) {
        identifier = COL_TEXT_ONLY;
    }
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
            
            // Then setup properties on the cellView based on the column
            [cellView setToolTip:[theFile hint]]; //TODO:!!!! Add tool tips lazyly by using view: stringForToolTip: point: userData:
            
            cellView.imageView.objectValue = [theFile image];
            
            // Setting the color
            if ([theFile hasTags:tagTreeItemDropped+tagTreeItemDirty+tagTreeItemToMove]) {
                [cellView.textField setTextColor:[NSColor lightGrayColor]]; // Sets grey when the file was dropped or dirty
            }
            else {
                // Set color back to normal
                [cellView.textField setTextColor:foreground];
                
            }
        }
    
        else if ([identifier hasPrefix:COL_SIZE]) { // SIZES
            cellView = [aTableView makeViewWithIdentifier:COL_SIZE owner:self];
            [((SizeTableCellView*)cellView)  stopAnimation];
            
        }
        else
            // We pass us as the owner so we can setup target/actions into this main controller object
            cellView = [aTableView makeViewWithIdentifier:COL_TEXT_ONLY owner:self];
        
        if (colControl!=nil) { // The column exists
            NSString *prop_name = colControl[COL_ACCESSOR_KEY];
            id prop = nil;
            @try {
                prop = [objectValue valueForKey:prop_name];
            }
            @catch (NSException *exception) {
                //NSLog(@"BrowserController.tableView:viewForTableColumn:row - Property '%@' not found", prop_name);
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
            else {
                // If its the filesize and it wasn't found, ask for
                // NOTE: isKindOfClass is preferred over itemType. Otherwise the size won't be calculated
                // TODO: Change the code below to use the col_id field instead. This one is working fine. It's just for
                // when another field is added.
                if (([theFile itemType] < ItemTypeDummyBranch) && [identifier hasPrefix:@"COL_SIZE"] && [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_CALCULATE_SIZES]) {
                    
                    [(TreeBranch*)theFile calculateSize]; // only if the calculation was started successfully
                    cellView.textField.objectValue = @"";
                    [((SizeTableCellView*)cellView)  startAnimation];
                    
                    // Adds to the the observed list
                    if ([self->observedTreeItemsForSizeCalculation containsObject:theFile]== NO) {
                        [theFile addObserver:self forKeyPath:kvoTreeBranchPropertySize options:0 context:nil];
                        [self->observedTreeItemsForSizeCalculation addObject:theFile];
                    }
                }
                else
                    cellView.textField.objectValue = @"--";
            }
        }
        else {
            cellView.textField.objectValue = @"Invalid Column";
        }
        
        

    }
    
    
    else if ([objectValue isKindOfClass:[GroupItem class]]) {
        // this is a group Row
        cellView = [aTableView makeViewWithIdentifier:ROW_GROUP owner:self];
        [cellView.textField setStringValue:[objectValue title]];
        [cellView setObjectValue:objectValue];

    }
    // other cases are not considered here. returning Nil
    return cellView;
}


#pragma mark - TableView View Delegate Protocol

/*
 * Table Data View Delegate Protocol
 */

// We want to make "group rows" for the folders
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    id objectValue = [self->_displayedItems objectAtIndex:row];
    if ([objectValue isKindOfClass:[TreeItem class]]) {
        return NO;
    } else {
        return YES; // Any other object will be a group
    }
}

// This function makes sure that the group headers are not selected
- (BOOL)tableView:(NSTableView *)aTableView
  shouldSelectRow:(NSInteger)rowIndex {
    if ([[self->_displayedItems objectAtIndex:rowIndex] isKindOfClass:[GroupItem class]])
        return NO;
    else
        return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self.parentController updateFocus:self];
    if([[aNotification name] isEqual:NSTableViewSelectionDidChangeNotification ]){
        [self.parentController selectionDidChangeOn:self]; // Will Trigger the notification to the status bar
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


    for (NSTableColumn *col in [inTableView tableColumns])
    {
        /* Will delete all indicators from the remaining columns */
        if (col!=tableColumn)
        {
            [inTableView setIndicatorImage:nil inTableColumn:col];
        }
    }
    [inTableView setHighlightedTableColumn:tableColumn];
    NodeSortDescriptor *currentDesc = [self sortDescriptorForFieldID:[tableColumn identifier]];

    BOOL ascending;
    if (currentDesc==nil || [currentDesc ascending]==NO)
    {
        [inTableView setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:tableColumn];
        ascending = YES;
    }
    else
    {
        [inTableView setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:tableColumn];
        ascending = NO;
    }
    [self makeSortOnFieldID:[tableColumn identifier] ascending:ascending grouping:[currentDesc isGrouping]];
    [self refreshKeepingSelections];
}

#pragma mark - Column Support

#ifdef COLUMN_NOTIFICATION

-(void) selectColumnTitles:(NSNotification *) note {
    // first checks the object sender is ours
    if ([note object]==_myTableViewHeader) {
        NSInteger colHeaderClicked = [[[note userInfo] objectForKey:kReferenceViewKey] integerValue];
        NSString *changedColumnID = [[note userInfo] objectForKey:kColumnChanged];

        // column select procedure
        if (changedColumnID!=nil) {
            // Get the needed informtion from the notification
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
        else {
            // Get the column
            NSTableColumn *colToGroup = [[[self myTableView] tableColumns] objectAtIndex:colHeaderClicked];
            // Remove it from Columns : [[self myTableView] removeTableColumn:colToGroup];
            [self makeSortOnFieldID:[colToGroup identifier] ascending:YES grouping:YES];
        }
        [self refreshKeepingSelections];
    }
}

#endif

-(void) setupColumns:(NSArray*) columns {

    // Removing all columns
    while ([self.myTableView.tableColumns count]) {
        NSTableColumn *col = self.myTableView.tableColumns[0];
        [self.myTableView removeTableColumn:col];
    }

    // Cycling throgh the columns to set
    for (NSString *colID in columns) {
        // Needs to insert this new column
        NSTableColumn *columnToAdd= [[NSTableColumn alloc] initWithIdentifier:colID];
        [[columnToAdd headerCell] setStringValue:columnInfo()[colID][COL_TITLE_KEY]];
        [[self myTableView] addTableColumn:columnToAdd];
    }
}

-(NSArray*) columns {
    // Gets the array with all the column identifiers
    NSArray *columns = [[self.myTableView tableColumns] valueForKeyPath:@"@unionOfObjects.identifier"];
    return columns;
}

-(void) loadPreferencesFrom:(NSDictionary*) preferences {
    [super loadPreferencesFrom:preferences];
    NSArray *columns = [preferences objectForKey:USER_DEF_TABLE_VIEW_COLUMNS];
    if (columns) {
        [self setupColumns:columns];
    }
    //[self.myTableView setUsesAlternatingRowBackgroundColors:[[NSUserDefaults standardUserDefaults] boolForKey:USER_DEF_TABLE_ALTERNATE_ROW]];
}

-(void) addColumn:(NSString*) fieldID {
    NSDictionary *colInfo = [columnInfo() objectForKey:fieldID];
    assert (colInfo); // Checking Problem in getting
    // Checks whether to add or to delete a column
    if ([[self myTableView] columnWithIdentifier:fieldID]==-1) { // column not existing
        // It was added
        NSTableColumn *columnToAdd= [NSTableColumn alloc];
        columnToAdd = [columnToAdd initWithIdentifier:fieldID];
        [[columnToAdd headerCell] setStringValue:colInfo[COL_TITLE_KEY]];
        [[self myTableView] addTableColumn:columnToAdd];
    }
    else {
        // It was removed
        [self removeColumn:fieldID];
    }

}

-(void) removeColumn:(NSString*) fieldID {
    NSTableColumn *colToDelete = [[self myTableView] tableColumnWithIdentifier:fieldID];
    [[self myTableView] removeTableColumn:colToDelete];
}

-(void) savePreferences:(NSMutableDictionary*) preferences {
    [super savePreferences:preferences];
    NSArray *colIDs = [self columns];
    if (colIDs) {
        [preferences setObject:colIDs forKey:USER_DEF_TABLE_VIEW_COLUMNS];
    }
}


// This action is called from the BrowserTableView when the contextual menu for groupings is called.
-(IBAction)groupContextSelect:(id)sender {
    NSInteger tag = [(NSMenuItem *)sender tag];
    NSInteger row = [[self myTableView] rightClickedRow];
    GroupItem *group = _displayedItems[row];
    if (tag == GROUP_SORT_ASCENDING || tag == GROUP_SORT_DESCENDING ) {
        // Changing the ascending key. Since that property is read-only, the descriptor needs to be initialized
        // Retrieving position of descriptor
        NSInteger i = [self.sortAndGroupDescriptors indexOfObject:group.descriptor];
        // Creating a new Descriptor from the old one
        NSSortDescriptor *oldDesc = group.descriptor;
        NodeSortDescriptor *updateDesc = [[NodeSortDescriptor alloc] initWithKey:oldDesc.key ascending:(tag==GROUP_SORT_ASCENDING)];
        // Needs to be a Grouping Descriptor
        [updateDesc copyGroupObject: oldDesc];
        // Updates the sort Array
        [self.sortAndGroupDescriptors setObject:updateDesc atIndexedSubscript:i];
    }
    else if (tag == GROUP_SORT_REMOVE ) {
        // removes the descriptor
        [self.sortAndGroupDescriptors removeObject:group.descriptor];
    }
    else {
        NSAssert(NO, @"Invalid tag received from group contextual Menu");
    }
    [self refreshKeepingSelections];
}

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)TableDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    NSArray *itemsSelected = [self->_displayedItems objectsAtIndexes:rowsSelected];
    [self orderOperation:opOpenOperation onItems:itemsSelected];
}

// This selector is invoked when the file was renamed or a New File was created
- (IBAction)filenameDidChange:(id)sender {
    NSInteger row = [_myTableView rowForView:sender];
    NSInteger column = [_myTableView columnForView:sender];
    
    if (column != [self.myTableView columnWithIdentifier:COL_FILENAME])
        // This was not supposed to happen. Best to undo any changes.
        [self.myTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                    columnIndexes:[NSIndexSet indexSetWithIndex:column]];
        return;

    if (row != -1) {
        TreeItem *item = [self->_displayedItems objectAtIndex:row];
        NSString const *operation=nil;
        if ([item hasTags:tagTreeItemNew]) {
            operation = opNewFolder;
        }
        else {
            // If the name did change. Do rename.
            if (![[sender stringValue] isEqualToString:[item name]]) {
                [item setName: [sender stringValue]];
            }
        }
    }
}

#pragma mark - Selection Support Functions

-(NSArray*) getSelectedItems {
    NSArray* answer = nil;
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    answer = [self->_displayedItems objectsAtIndexes:rowsSelected];
    return answer;
}

// Can select the current Node
- (NSArray*)getSelectedItemsForContextualMenu1 {
    static NSArray* answer = nil; // This will send the last answer when further requests are done

    // if the click was outside the items displayed
    if ([_myTableView clickedRow] == -1 ) {
        // it returns nothing
        answer = [NSArray arrayWithObject:self.currentNode]; // It will return the current node.
    }
    else {
        NSIndexSet *selectedIndexes = [_myTableView selectedRowIndexes];
        // If the clicked row was in the selectedIndexes, then we process all selectedIndexes. Otherwise, we process just the clickedRow
        if(![selectedIndexes containsIndex:[_myTableView clickedRow]]) {
            selectedIndexes = [NSIndexSet indexSetWithIndex:[_myTableView clickedRow]];
        }
        answer = [self->_displayedItems objectsAtIndexes:selectedIndexes];
    }

    return answer;
}

// Doesn't select the current Node
-(NSArray*) getSelectedItemsForContextualMenu2 {
    static NSArray* answer = nil; // This will send the last answer when further requests are done
    
    // if the click was in one of the items displayed
    if ([_myTableView clickedRow] != -1 ) {
        NSIndexSet *selectedIndexes = [_myTableView selectedRowIndexes];
        // If the clicked row was in the selectedIndexes, then we process all selectedIndexes. Otherwise, we process just the clickedRow
        if(![selectedIndexes containsIndex:[_myTableView clickedRow]]) {
            selectedIndexes = [NSIndexSet indexSetWithIndex:[_myTableView clickedRow]];
        }
        answer = [self->_displayedItems objectsAtIndexes:selectedIndexes];
    }
    
    return answer;
}

-(TreeItem*) getLastClickedItem {
    NSInteger row = [_myTableView clickedRow];
    if (row >=0 && row < [self->_displayedItems count]) {
        // Returns the current selected item
        return [self->_displayedItems objectAtIndex:row];
    }
    else {
        // Returns the displayed folder
        return self.currentNode;

    }
}

-(NSArray*) getTableViewSelectedURLs {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    if ([rowsSelected count]==0)
        return nil;
    else {
        // using collection operator to get the array of the URLs from the selected Items
        NSArray *selectedItems = [self->_displayedItems objectsAtIndexes:rowsSelected];
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
        NSIndexSet *select = [self->_displayedItems indexesOfObjectsPassingTest:^(id item, NSUInteger index, BOOL *stop){
            //NSLog(@"setTableViewSelectedURLs %@ %lu", [item path], index);
            if ([item isKindOfClass:[TreeItem class]] && [urls containsObject:[item url]])
                return YES;
            else
                return NO;
        }];
        [_myTableView selectRowIndexes:select byExtendingSelection:NO];
    }
}

-(void) startBusyAnimations {
    [super startBusyAnimations];
    [self.myProgressIndicator setHidden:NO];
    [self.myProgressIndicator startAnimation:self];

}
-(void) stopBusyAnimations {
    [super stopBusyAnimations];
    [self.myProgressIndicator setHidden:YES];
    [self.myProgressIndicator stopAnimation:self];
}

-(void) refresh {
    [self startBusyAnimationsDelayed];
    [self itemsToDisplay];
    [self stopBusyAnimations];
    [_myTableView reloadData];
}

-(void) refreshKeepingSelections {
    // TODO:? Animate the updates (new files, deleted files)
    // Storing Selected URLs
    NSArray *selectedURLs = [self getTableViewSelectedURLs];
    // Refreshing the View
    [self refresh];
    // Reselect stored selections
    [self setTableViewSelectedURLs:selectedURLs];
}


-(void) reloadItem:(id) object {
    if (object == self.currentNode) {
        [self refresh];
    }
    else { // if its not the node, then it could be a table element
        NSInteger rowToReload = [self->_displayedItems indexOfObject:object];
        if (rowToReload >=0  && rowToReload!=NSNotFound) {
            NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:rowToReload];
            NSRange columnsRange = {0, [[_myTableView tableColumns] count] };
            NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndexesInRange:columnsRange];
            [_myTableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
        }
    }
}

-(void) reloadSize:(id) object {
    NSInteger rowToReload = [self->_displayedItems indexOfObject:object];
    if (rowToReload >=0  && rowToReload!=NSNotFound) {
        NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:rowToReload];
        
        NSMutableIndexSet *columnIndexes = [[NSMutableIndexSet alloc] init];
        int index=0;
        for (NSTableColumn * colID in [self.myTableView tableColumns]) {
            if ([[colID identifier] hasPrefix:@"COL_SIZE"]) {
                [columnIndexes addIndex:index];
            }
            index++;
        }
        [_myTableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];

        // Now the observe can be removed
        if ([self->observedTreeItemsForSizeCalculation containsObject:object]) {
            [object removeObserver:self forKeyPath:kvoTreeBranchPropertySize];
            [self->observedTreeItemsForSizeCalculation removeObject:object];
        }
    }
}

- (void) setCurrentNode:(TreeBranch*)branch {
    //Unobserve Tree Items that were set for size calculation
    for (TreeItem *item in self->observedTreeItemsForSizeCalculation) {
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertySize];
    }
    if ([self->observedTreeItemsForSizeCalculation count]!=0) {
        // Cancelling all pending
        //NSLog(@"Canceling all size operations");
        NSArray *operations = [lowPriorityQueue operations];
        for (NSOperation *op in operations) {
            if ([op isKindOfClass:[CalcFolderSizes class]]) {
                TreeBranch *tb = [(CalcFolderSizes*)op item];
                if (![tb containedInURL:branch.url]) {
                    [op cancel];
                    [tb sizeCalculationCancelled];
                }
                
            }
        }
    }
    [self->observedTreeItemsForSizeCalculation removeAllObjects];
    
    
    [super setCurrentNode:branch];
    if (branch==nil) {
        // Removing everything
        self->_displayedItems = nil;
    }
    else {
    }
}


#pragma mark - Drag and Drop Support


#ifdef USE_TREEITEM_PASTEBOARD_WRITING
- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    return (id <NSPasteboardWriting>) [self->_displayedItems objectAtIndex:row];
}

#else

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    return writeItemsToPasteBoard(items, pboard, supportedPasteboardTypes());
}
#endif


- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
#ifdef UPDATE_TREE
    _draggedItemsIndexSet = rowIndexes; // Save the Indexes for later deleting or moving
#endif
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

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    self->_validatedDropDestination = nil;
    if (operation == NSTableViewDropAbove) { // This is on the folder being displayed
        self->_validatedDropDestination = self.currentNode;
    }
    else if (operation == NSTableViewDropOn) {

        @try { // If the row is not valid, it will assume the tree node being displayed.
            self->_validatedDropDestination = [self->_displayedItems objectAtIndex:row];
        }
        @catch (NSException *exception) {
            self->_validatedDropDestination = self.currentNode;
        }
        @finally {
            // Go away... nothing to see here
        }
    }

    /* Limit the Operations depending on the Destination Item Class*/
    if ([self->_validatedDropDestination isFolder]) {
        // TODO:!!! Put here a timer for opening the Folder
        // Recording time and first time
        // if not first time and recorded time > 3 seconds => open folder
    }
    self->_validatedDropOperation = validateDrop(info, self->_validatedDropDestination);
    return self->_validatedDropOperation;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {

    BOOL opDone = acceptDrop(info, self->_validatedDropDestination, self->_validatedDropOperation, self);

    if (self->_validatedDropDestination == self.currentNode && opDone==YES) {
        //Inserts the rows using the specified animation.
        if (self->_validatedDropOperation & (NSDragOperationCopy | NSDragOperationMove)) {
            NSPasteboard *pboard = [info draggingPasteboard];
            NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

            int i= 0;
            for (id pastedItem in files) {
                TreeItem *newItem=nil;
                if ([pastedItem isKindOfClass:[NSURL class]]) {
                    //[(TreeBranch*)targetItem addURL:pastedItem]; This will be done on the refresh after copy
                    newItem = [TreeItem treeItemForURL: pastedItem parent:self.currentNode];
                    [newItem setTag:tagTreeItemDropped];
                }
                if (newItem) {
                    [self->_displayedItems insertObject:newItem atIndex:row+i];
                    [aTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row+i] withAnimation:NSTableViewAnimationSlideDown]; //TODO:Try NSTableViewAnimationEffectGap
                    i++;
                }
            }
        }
    }
    return opDone;
}

// This selector is implemented in the super class
//-(void) menuNeedsUpdate:(NSMenu*) menu {
//    [super menu:menu updateItem:item atIndex:index shouldCancel:shouldCancel];
//}

#pragma mark - NSControlTextDelegate Protocol

- (void)keyDown:(NSEvent *)theEvent {
    // Get the origin
    NSString *key = [theEvent characters];
    unichar keyCode = [key characterAtIndex:0];
    NSString *keyWM = [theEvent charactersIgnoringModifiers];
    //NSLog(@"KD: code:%@ - %@, [%d,%d]",key, keyWM, keyCode, [keyWM characterAtIndex:0]);
    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVIOUR] ;

    if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if (keyCode == KeyCodeDown) {    // will open the subject
            [self TableDoubleClickEvent:theEvent];
        }
        else if (keyCode == KeyCodeUp) {  // the CMD Up will up one directory level
            [[self parentController] upOneLevel];
        }
    }
    else if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
        ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
    {
        // The Return key will open the file
        [self TableDoubleClickEvent:theEvent];
    }
    else if ([keyWM isEqualToString:@"\t"]) { // the tab key will switch Panes
        [[self parentController] focusOnNextView:self];
    }
    else if ([key isEqualToString:@"\x19"]) { // the Shift tab key will switch Panes
        [[self parentController] focusOnPreviousView:self];
    }
    else if ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_MULTIPLATFORM ) {
        // the Space Key will mark the file
        // only works the TableView
            if (self->extendedSelection==nil) {
                self->extendedSelection = [NSMutableIndexSet indexSet];
            }
            NSIndexSet *indexset = [_myTableView selectedRowIndexes];
            [indexset enumerateIndexesUsingBlock:^(NSUInteger index, BOOL * stop) {
                id item = [self->_displayedItems objectAtIndex:index];
                if ([item isKindOfClass:[TreeItem class]]) {
                    [(TreeItem*)item toggleTag:tagTreeItemMarked];
                }
                if ([self->extendedSelection containsIndex:index])
                    [self->extendedSelection removeIndex:index];
                else
                    [self->extendedSelection addIndex:index];
            }];

            // Check what is the preferred method
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
    else {
        [super keyDown:theEvent]; // Just passing it to the super class
    }
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    NSInteger row = [_myTableView rowForView:fieldEditor];
    if (row!=-1) {
        id item = [self->_displayedItems objectAtIndex:row];

        // In order to allow the creation of new files
        if ([item hasTags:tagTreeItemNew])
            return YES;
        return [item hasTags:tagTreeItemReadOnly]==NO;
    }
    else
        return YES;
}

// NSControlTextEditingDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    //NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        
        // In cancel will check if it was a new File and if so, remove it
        NSInteger row =[_myTableView rowForView:fieldEditor];
        if (row!=-1) {
            id item = [self->_displayedItems objectAtIndex:row];
            if ([item isKindOfClass:[TreeItem class]]) {
                if ([(TreeItem*)item hasTags:tagTreeItemNew]) {
                    NSIndexSet *rows2delete = [NSIndexSet indexSetWithIndex:row];
                    [_myTableView removeRowsAtIndexes:rows2delete
                                        withAnimation:NSTableViewAnimationEffectFade];
                }
                else {
                    // Reposition the old text
                    [control setStringValue:[item name]];
                }
            }
        }
        //[fieldEditor resignFirstResponder];
        //[self focusOnLastView];
        //return YES;  // avoids that the cancelOperation from controller is called.
    }

    return NO;
}



-(BOOL) startEditItemName:(TreeItem*)item  {
    NSUInteger row = [self->_displayedItems indexOfObject:item];
    if (row!=NSNotFound) {
        NSInteger column = [_myTableView columnWithIdentifier:COL_FILENAME];
        if (column != -1 ) {
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
    NSInteger row;
    NSIndexSet *selection = [_myTableView selectedRowIndexes];
    if ([selection count]>0) {
        // Will insert a row on the bottom of the selection.
        row = [selection lastIndex] + 1;
        [self->_displayedItems insertObject:item atIndex:row];
    }
    else {
        row = [self->_displayedItems count];
        [self->_displayedItems addObject:item];
    }
    [_myTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation: NSTableViewAnimationEffectNone]; //NSTableViewAnimationSlideDown, NSTableViewAnimationEffectGap

    // Making the new inserted line as selected
    [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

// First Selectable row
-(NSInteger) firstSelectableRow {
    NSInteger row=0;
    while (row < [self->_displayedItems count]) {
        if ([[self->_displayedItems objectAtIndex:row] isKindOfClass:[TreeItem class]])
            return row;
        row++;
    }
    return -1;
}

-(void) focusOnFirstView {
    if ([[_myTableView selectedRowIndexes] count]==0) {
        NSInteger first = [self firstSelectableRow];
        if (first != -1) {
            [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:first] byExtendingSelection:NO];
        }
    }
    [self.myTableView.window makeFirstResponder:self.myTableView];

}
-(void) focusOnLastView {
    if ([[_myTableView selectedRowIndexes] count]==0) {
        NSInteger first = [self firstSelectableRow];
        if (first != -1) {
            [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:first] byExtendingSelection:NO];
        }
    }
    [self.myTableView.window makeFirstResponder:self.myTableView];
}

@end
