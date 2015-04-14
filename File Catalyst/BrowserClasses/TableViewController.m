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

#define COL_FILENAME @"COL_NAME"
#define COL_TEXT_ONLY @"COL_TEXT"

//#define COL_DATE_MOD @"COL_DATE_MODIFIED"
//#define COL_SIZE     @"COL_SIZE"
//#define COL_PATH     @"COL_PATH"

//#define AVAILABLE_COLUMNS  COL_FILENAME, COL_DATE_MOD, COL_SIZE, COL_PATH
//#define SYSTEM_COLUMNS     COL_FILENAME
//#define DEFAULT_COLUMNS    COL_SIZE, COL_DATE_MOD



@interface TableViewController ( ) {
    NSMutableArray *tableData;
    NSSortDescriptor *TableSortDesc;
    NSIndexSet *_draggedItemsIndexSet;
    TreeItem   *_validatedDropDestination;
    NSDragOperation _validatedDropOperation;
    NSMutableIndexSet *extendedSelection;
}
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

}

- (void)awakeFromNib
{
    
}
- (void) initController {
    [super initController];
    self->TableSortDesc = nil;
    self->_draggedItemsIndexSet = nil;
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

- (void) setSaveName:(NSString *)saveName {
    if (saveName) {
        [[self myTableView] setAutosaveName:saveName];
        [[self myTableView] setAutosaveTableColumns:YES];
    }
}

/*
 -(id) getFileAtIndex:(NSUInteger)index {
 return [tableData objectAtIndex:index];
 }
*/

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
                if ([theFile itemType] == ItemTypeBranch)
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
                    if ([theFile hasTags:tagTreeItemDropped+tagTreeItemDirty+tagTreeItemToMove]) {
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
            //        if (_viewMode==BViewBrowserMode && [theFile itemType] == ItemTypeBranch){
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
    [self.parentController updateFocus:self];
    if([[aNotification name] isEqual:NSTableViewSelectionDidChangeNotification ]){
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

/* This action is associated manually with the doubleClickTarget in Bindings */
- (IBAction)TableDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    NSArray *itemsSelected = [tableData objectsAtIndexes:rowsSelected];
    [self orderOperation:opOpenOperation onItems:itemsSelected];
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
                              self.currentNode, kDFODestinationKey,
                              //self, kFromObjectKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];

    }
}

-(NSArray*) getSelectedItems {
    NSArray* answer = nil;
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    answer = [tableData objectsAtIndexes:rowsSelected];
    return answer;
}

- (NSArray*)getSelectedItemsForContextMenu {
    static NSArray* answer = nil; // This will send the last answer when further requests are done

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

    return answer;
}

-(TreeItem*) getLastClickedItem {
    NSInteger row = [_myTableView clickedRow];
    if (row >=0 && row < [tableData count]) {
        // Returns the current selected item
        return [tableData objectAtIndex:row];
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

-(void) startBusyAnimations {
    [_myProgressIndicator setHidden:NO];
    [_myProgressIndicator startAnimation:self];

}
-(void) stopBusyAnimations {
    [_myProgressIndicator setHidden:YES];
    [_myProgressIndicator stopAnimation:self];
}

-(void) refresh {
    //[self startBusyAnimations];
    tableData = [self itemsToDisplay];
    [self sortWithDescriptor];
    [self stopBusyAnimations];
    [_myTableView reloadData];
}

-(void) refreshKeepingSelections {
    // TODO:! Animate the updates (new files, deleted files)
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
        NSInteger rowToReload = [tableData indexOfObject:object];
        if (rowToReload >=0  && rowToReload!=NSNotFound) {
            NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:rowToReload];
            NSRange columnsRange = {0, [[_myTableView tableColumns] count] };
            NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndexesInRange:columnsRange];
            [_myTableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
        }
    }
}

- (void) setCurrentNode:(TreeBranch*)branch {
    [super setCurrentNode:branch];
    if (branch==nil) {
        // Removing everything
        tableData = nil;
    }
    else {
    }
}


#pragma mark - Drag and Drop Support


#ifdef USE_TREEITEM_PASTEBOARD_WRITING
- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    return (id <NSPasteboardWriting>) [tableData objectAtIndex:row];
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
#endif


- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
    _draggedItemsIndexSet = rowIndexes; // Save the Indexes for later deleting or moving
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
            self->_validatedDropDestination = [tableData objectAtIndex:row];
        }
        @catch (NSException *exception) {
            self->_validatedDropDestination = self.currentNode;
        }
        @finally {
            // Go away... nothing to see here
        }
    }

    /* Limit the Operations depending on the Destination Item Class*/
    if ([self->_validatedDropDestination itemType] == ItemTypeBranch) {
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
                    [tableData insertObject:newItem atIndex:row+i];
                    [aTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row+i] withAnimation:NSTableViewAnimationSlideDown]; //TODO:Try NSTableViewAnimationEffectGap
                    i++;
                }
            }
        }
    }
    return opDone;
}

#pragma mark - NSControlTextDelegate Protocol

- (void)keyDown:(NSEvent *)theEvent {
    // Get the origin
    NSString *key = [theEvent characters];
    NSString *keyWM = [theEvent charactersIgnoringModifiers];

    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVOUR] ;

    if (([key isEqualToString:@"\r"] && behave == APP_BEHAVIOUR_MULTIPLATFORM) ||
        ([key isEqualToString:@" "] && behave == APP_BEHAVIOUR_NATIVE))
    {
        // The Return key will open the file
        [self TableDoubleClickEvent:theEvent];
    }
    else if ([keyWM isEqualToString:@"\t"]) {
        // the tab key will switch Panes
        [[self parentController] focusOnNextView:self];
    }
    else if ([key isEqualToString:@"\x19"]) {
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

// NSControlTextEditingDelegate
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
    //TODO:!!!! Forward to parent
}

-(BOOL) startEditItemName:(TreeItem*)item  {
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
    return NO;
}

-(void) insertItem:(id)item  {
    NSInteger row = [tableData count];
    NSIndexSet *selection = [_myTableView selectedRowIndexes];
    if ([selection count]>0) {
        // Will insert a row on the bottom of the selection.
        row = [selection lastIndex] + 1;
    }
    else {
        row = [tableData count];
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



-(void) focusOnFirstView {
    if ([[_myTableView selectedRowIndexes] count]==0) {
        [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    [self.myTableView.window makeFirstResponder:self.myTableView];

}
-(void) focusOnLastView {
    if ([[_myTableView selectedRowIndexes] count]==0) {
        [_myTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    [self.myTableView.window makeFirstResponder:self.myTableView];
}

@end
