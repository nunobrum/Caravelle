//
//  BrowserController.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "BrowserController.h"

#import "FolderCellView.h"
#import "TreeItem.h"
#import "TreeLeaf.h"
#import "TreeBranch.h"
#import "TreeRoot.h"
#import "FileInformation.h"
#import "fileOperation.h"

#define COL_FILENAME @"NameID"
#define COL_DATE_MOD @"ModifiedID"
#define COL_SIZE     @"SizeID"
#define COL_PATH     @"Path"

#define AVAILABLE_COLUMNS  COL_FILENAME, COL_DATE_MOD, COL_SIZE, COL_PATH
#define SYSTEM_COLUMNS     COL_FILENAME
#define DEFAULT_COLUMNS    COL_SIZE, COL_DATE_MOD


void DateFormatter(NSDate *date, NSString **output) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];

    //NSLocale *systemLocale = [[NSLocale alloc] init];
    //[dateFormatter setLocale:systemLocale];

    *output = [dateFormatter stringFromDate:date];
    // Output:
    // Date for locale en_US: Jan 2, 2001

}

@interface BrowserController () {
    NSTableView *_focusedView; // Contains the currently selected view
    NSMutableArray *tableData;
    NSMutableArray *tableColumnInfo;
    NSSortDescriptor *TableSortDesc;
    NSMutableArray *_observedVisibleItems;
    /* Internal Storage for Drag and Drop Operations */
    NSDragOperation _validatedOperation; // Passed from Validate Drop to Accept Drop Method
    NSIndexSet *_draggedIndexSet;
}

@end

@implementation BrowserController

#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self->BaseDirectoriesArray = [[NSMutableArray new] init];
    self->_focusedView = nil;
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_viewMode = BViewBrowserMode;
    self->_filterText = @"";
    self->tableColumnInfo = [NSMutableArray arrayWithObjects: SYSTEM_COLUMNS, nil];
    [self->tableColumnInfo addObjectsFromArray:[NSArray arrayWithObjects: DEFAULT_COLUMNS, nil]];
    self->TableSortDesc = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
    _sharedOperationQueue = [[NSOperationQueue alloc] init];
    // We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
    [_sharedOperationQueue setMaxConcurrentOperationCount:2];
    NSLog(@"Init Browser Controller");
    return self;
}

- (void)dealloc {
//    // Stop any observations that we may have
    for (TreeItem *item in _observedVisibleItems) {
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
    }
//    [super dealloc];
}

//- (void)awakeFromNib {
//    NSLog(@"Browser Controller : awakeFromNib");
//}

/* Method overriding the default for the NSView
 This is done to accelerate the redrawing of the contents */
-(BOOL) isOpaque {
    return YES;
}

// NSWorkspace Class Reference - (NSImage *)iconForFile:(NSString *)fullPath


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
    // Use KVO to observe for changes of its children Array
    [self observeItem:ret];
    if (_viewMode==BViewBrowserMode) {
        [(TreeBranch*)ret refreshContentsOnQueue:_sharedOperationQueue];
    }
    else {
        [self refreshDataView];
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
    //NSLog(@"%@ is expandable %hhd", [item name], answer);
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

            }
            else {
                cellView= [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
            }

            // Display the directory name followed by the number of files inside
            NSString *path = [(TreeBranch*)item path];
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];

            [[cellView imageView] setImage:icon];
            [[cellView textField] setStringValue:[item name]];

        }
    }
    return cellView;
}

//- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//
//}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    //if ((tableColumn != nil) || [[tableColumn identifier] isEqualToString:COL_FILENAME]) {
    //       [item setTitle:object];
    //
    //}
    NSLog(@"setObjectValue Object Class %@ Table Column %@ Item %@",[(NSObject*)object class], tableColumn.identifier, [item name]);
}

#pragma mark - Tree Outline View Delegate Protocol


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    //    if ([item isKindOfClass:[TreeBranch class]]) {
    //        TreeItem *treeItem = item;
    //        if (treeItem  != nil) {
    //            // We could dynamically change the thumbnail size, if desired
    //            return IMAGE_SIZE + PADDING_AROUND_INFO_IMAGE; // The extra space is padding around the cell
    //        }
    //    }
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
    // !!! TOCONSIDER : Avoid selecting protected files
    return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ])  {
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        NSInteger SelectedCount = [rowsSelected count];
        _focusedView = _myOutlineView;
        if (SelectedCount ==0) {
            [_myTableView unregisterDraggedTypes];
        } else if (SelectedCount==1) {
            /* Updates the _treeNodeSelected */
            [_myTableView registerForDraggedTypes:[NSArray arrayWithObjects: OwnUTITypes (id)kUTTypeFolder, (id)kUTTypeFileURL, NSFilenamesPboardType, nil]];
            _treeNodeSelected = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            [self setPathBarToItem:_treeNodeSelected];
            //[self refreshDataView];
            // Use KVO to observe for changes of its children Array
            [self observeItem:_treeNodeSelected];
            if (_viewMode==BViewBrowserMode) {
                [(TreeBranch*)_treeNodeSelected refreshContentsOnQueue:_sharedOperationQueue];
            }
            else {
                [self refreshDataView];
            }
       }
        else {
            NSLog(@"Houston we have a problem");
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

- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    TreeItem *theFile = [tableData objectAtIndex:rowIndex];
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [aTableColumn identifier];
    // We pass us as the owner so we can setup target/actions into this main controller object
    NSTableCellView *cellView = [aTableView makeViewWithIdentifier:identifier owner:self];

    if ([identifier isEqualToString:COL_FILENAME]) {
        NSString *path = [[theFile url] path];
        if (path) {
            // Then setup properties on the cellView based on the column
            cellView.textField.stringValue = [theFile name];  // Display simply the name of the file;
            cellView.imageView.objectValue = [[NSWorkspace sharedWorkspace] iconForFile:path];
            //[cellView registerForDraggedTypes:[NSArray arrayWithObjects: (id)kUTTypeFileURL, nil]];
        }
    }
    else if ([identifier isEqualToString:COL_SIZE]) {
        if (_viewMode==BViewBrowserMode && [theFile isKindOfClass:[TreeBranch class]]){
            //cellView.textField.objectValue = [NSString stringWithFormat:@"%ld Items", [(TreeBranch*)theFile numberOfItemsInNode]];
            cellView.textField.objectValue = @"--";
        }
        else
            cellView.textField.objectValue = [NSByteCountFormatter stringFromByteCount:[theFile filesize] countStyle:NSByteCountFormatterCountStyleFile];

    } else if ([identifier isEqualToString:COL_DATE_MOD]) {
        NSString *result=nil;
        DateFormatter([theFile dateModified], &result);
        if (result == nil)
            cellView.textField.stringValue = NSLocalizedString(@"(Date)", @"Unknown Date");
        else
            cellView.textField.stringValue = result;
    }
    else {
        /* Debug code for further implementation */
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@ %ld", aTableColumn.identifier, rowIndex];
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
    else if ([[tableColumn identifier] isEqualToString:COL_SIZE])
        key = @"filesize";
    else if ([[tableColumn identifier] isEqualToString:COL_DATE_MOD])
        key = @"name";

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

#pragma mark Action Selectors

- (IBAction)tableSelected:(id)sender {
    _focusedView = _myTableView;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:nil];
}

/* This action is associated manually with the setDoubleAction */
- (IBAction)TableDoubleClickEvent:(id)sender {
    NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
    NSUInteger index = [rowsSelected firstIndex];
    while (index!=NSNotFound) {
        /* Do something here */
        id node = [self getFileAtIndex:index];
        if ([node isKindOfClass: [TreeLeaf class]]) { // It is a file : Open the File
            [[node getFileInformation] openFile];
        }
        else if ([node isKindOfClass: [TreeBranch class]]) { // It is a directory
            // Going to open the Select That directory on the Outline View
            [self selectFolderByItem:node];
            /* Set the path bar */
            //[_myPathBarControl setURL: [node theURL]];
            /* Setting the node for Table Display */
            self.treeNodeSelected=node;

            // Use KVO to observe for changes of its children Array
            [self observeItem:_treeNodeSelected];
            if (_viewMode==BViewBrowserMode) {
                [(TreeBranch*)_treeNodeSelected refreshContentsOnQueue:_sharedOperationQueue];
            }
            else {
                [self refreshDataView];
            }
            break; /* Only one Folder can be Opened */
        }
        else
            NSLog(@"Can't open this");
        index = [rowsSelected indexGreaterThanIndex:index];

    }
}

#pragma mark - Drag and Drop Support
/*
 * Drag and Drop Methods 
 */

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *ptypes;
    TreeItem *targetItem;
    NSUInteger modifiers = [NSEvent modifierFlags];

    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    ptypes =[pboard types];

    if (aTableView!=_myTableView) { /* Protection , just in case */
        NSLog(@"Ooops! This isnt supposed to happen");
        return NSDragOperationNone;
    }
    @try { // If the row is not valid, it will assume the tree node being displayed.
        targetItem = [tableData objectAtIndex:row];
    }
    @catch (NSException *exception) {
        targetItem = _treeNodeSelected;
    }
    @finally {
        // Go away... nothing to see here
    }
    /* Limit the options in function of the dropped Element */
    if ( [ptypes containsObject:NSFilenamesPboardType] ) {
        sourceDragMask &= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    else if ( [ptypes containsObject:(id)kUTTypeFileURL] ) {
        sourceDragMask &= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#ifdef USE_UTI
    else if ( [ptypes containsObject:(id)kTreeItemDropUTI] ) {
        sourceDragMask &= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#endif
    else {
        sourceDragMask = NSDragOperationNone;
    }

    /* Limit the Operations depending on the Destination Item Class*/
    if ([targetItem isKindOfClass:[TreeBranch class]]) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
        // !!! TODO : Put here a timer for opening the Folder
    }
    else if ([targetItem isKindOfClass:[TreeLeaf class]]) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        sourceDragMask = NSDragOperationNone;
    }
    /* Use the modifiers keys to select */
    //if (modifiers & NSShiftKeyMask) {
    //}
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
    return _validatedOperation;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperationLocation {
    NSLog(@"accept row %ld", row);
    BOOL fireNotfication = NO;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

    if (aTableView!=_myTableView) {
        // For the moment only accept drops into the table View.
        fireNotfication =  NO; // This instruction is useless. The answer is by default NO.
        // Only to make the code more clear.
    }
    else if (dropOperationLocation == NSTableViewDropAbove) {
        //Inserts the rows using the specified animation.
        if (_validatedOperation & (NSDragOperationCopy | NSDragOperationMove)) {
            int i= 0;
            for (id pastedItem in files) {
                TreeItem *newItem=nil;
                if ([pastedItem isKindOfClass:[NSURL class]]) {
                //[(TreeBranch*)targetItem addURL:pastedItem]; This will be done on the refresh after copy
                    newItem = [TreeItem treeItemForURL: pastedItem parent:_treeNodeSelected];
                    [newItem setTag:tagTreeItemDropped];
                }
                else if ([pastedItem isKindOfClass:[TreeItem class]]){
                    newItem = pastedItem;
                }
                if (newItem) {
                    [tableData insertObject:newItem atIndex:row+i];
                    [aTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row+i] withAnimation:NSTableViewAnimationSlideDown];
                    //NSLog(@"Copy Item %@", [pastedItem lastPathComponent]);
                    i++;
                }
            }
            if (_validatedOperation==NSDragOperationCopy)
                copyItemsToBranch(files, _treeNodeSelected);
            else if (_validatedOperation==NSDragOperationMove)
                moveItemsToBranch(files, _treeNodeSelected);
            
            fireNotfication= YES;
        }
    }
    else if (dropOperationLocation == NSTableViewDropOn){
        TreeItem *targetItem = [tableData objectAtIndex:row];
        if ([targetItem isKindOfClass:[TreeBranch class]]) {
            if (_validatedOperation == NSDragOperationCopy) {
                copyItemsToBranch(files, (TreeBranch*)targetItem);
                fireNotfication = YES;
            }
            else if (_validatedOperation == NSDragOperationMove) {
                moveItemsToBranch(files, (TreeBranch*)targetItem);
                fireNotfication = YES;            }
            else if (_validatedOperation == NSDragOperationLink) {
                // TODO !!! Operation Link
            }
            else {
                // Unsupported !!!
            }

        }
        else if ([targetItem isKindOfClass:[TreeLeaf class]]) {
            // !!! TODO Dropping Application on top of file or File on top of Application
            NSLog(@"Not impplemented open the file with the application");
            // !!! IDEA Maybe an append/Merge/Compare can be done if overlapping two text files
        }
    }
    if (fireNotfication==YES) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:nil];
    }
    else
        NSLog(@"Unsupported Operation %lu", (unsigned long)_validatedOperation);
    return fireNotfication;
}

//- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
//    return YES;
//}

- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSLog(@"write to paste board, passing handle to item at row %ld",row);
    return (id <NSPasteboardWriting>) [tableData objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
    _draggedIndexSet = rowIndexes; // Save the Indexes for later deleting or moving
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    NSPasteboard *pboard = [session draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    if (operation == (NSDragOperationMove)) {
        [tableView removeRowsAtIndexes:_draggedIndexSet withAnimation:NSTableViewAnimationEffectFade];
    }
    else if (operation ==  NSDragOperationDelete) {
        // Send to RecycleBin.
        [tableView removeRowsAtIndexes:_draggedIndexSet withAnimation:NSTableViewAnimationEffectFade];
        sendItemsToRecycleBin(files); // TODO !!! Check whether the recycle bin deletes the
    }
}

- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id < NSDraggingInfo >)draggingInfo {
    NSLog(@"info : update dragging items");
}
#pragma mark - KVO Methods

- (void)_reloadRowForEntity:(id)object {
    //NSLog(@"Reloading %@", [object name]);
    NSInteger row = [_myOutlineView rowForItem:object];
    if (object == _treeNodeSelected) {
        /*If it is the selected Folder make a refresh*/
        [self refreshDataView];
    }
    if (row != NSNotFound) {
        [_myOutlineView reloadItem:object reloadChildren:YES];
        //NSLog(@"Reloading %@", [object name]);
//        if (0) { // This is a very nice effect to consider later !!! TO CONSIDER
//            FolderCellView *cellView = [_myOutlineView viewAtColumn:0 row:row makeIfNecessary:NO];
//            if (cellView) {
//                // Fade the imageView in, and fade the progress indicator out
//                [NSAnimationContext beginGrouping];
//                [[NSAnimationContext currentContext] setDuration:0.8];
//                [cellView.imageView setAlphaValue:0];
//                //cellView.imageView.image = entity.thumbnailImage;
//                [cellView.imageView setHidden:NO];
//                [[cellView.imageView animator] setAlphaValue:1.0];
//                //[cellView.progessIndicator setHidden:YES];
//                [NSAnimationContext endGrouping];
//            }
//        }
    }
//    if ([_sharedOperationQueue operationCount]==0) {
//        NSLog(@"Finished all operations launched. Reloading data");
//        [_myOutlineView reloadData];
//    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kvoTreeBranchPropertyChildren]) {
        // Find the row and reload it.
        // Note that KVO notifications may be sent from a background thread (in this case, we know they will be)
        // We should only update the UI on the main thread, and in addition, we use NSRunLoopCommonModes to make sure the UI updates when a modal window is up.
        [self performSelectorOnMainThread:@selector(_reloadRowForEntity:) withObject:object waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
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


#pragma mark - Interface Methods


/*
 * Parent access routines
 */

-(void) setViewMode:(BViewMode)viewMode {
    if (viewMode!=_viewMode) {
        [self removeAll];
        [self refreshTrees];
        tableData = nil;
        [_myTableView reloadData];
        [self startBusyAnimations];
    _viewMode = viewMode;
    }
}
-(BViewMode) viewMode {
    return _viewMode;
}


-(NSOutlineView*) treeOutlineView {
    return _myOutlineView;
}

-(id) getFileAtIndex:(NSUInteger)index {
    return [tableData objectAtIndex:index];
}

-(void) set_filterText:(NSString *) filterText {
    self->_filterText = filterText;
}

-(void) refreshDataView {
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

-(void) refreshTrees {
    if (_viewMode!=BViewBrowserMode) {
       // In catalyst Mode, there is no automatic Update
    }
    else {
        for (TreeRoot *tree in BaseDirectoriesArray) {
            [tree refreshContentsOnQueue:_sharedOperationQueue];
        }
    }
    // !!! Todo Add condition : if number of roots = 1 then
    // Expand the Root Node
    [_myOutlineView reloadData];
    [self refreshDataView];
}

-(void) addTreeRoot:(TreeRoot*)theRoot {
    if (theRoot!=nil) {
        NSInteger answer = [self canAddRoot:[theRoot rootPath]];
        if (answer == pathsHaveNoRelation) {
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
    BaseDirectoriesArray = [[NSMutableArray alloc] init]; /* Garbage collection will release everything */
}

- (void) removeSelectedDirectory {
    /* gets the selected item */
    NSInteger fileSelected = [_myOutlineView selectedRow];
    NSInteger level = [_myOutlineView levelForRow:fileSelected];
    /* then finds the corresponding item */

    if (level==0) {
        /*If it is a root
         Will delete the tree Root and sub Directories */
        [self removeRoot: [_myOutlineView itemAtRow:fileSelected]];
        // Redraws the outline view
    }
    else {
        // Will send the corresponding file to recycle bin
        // !!! TODO
        TreeItem *fileOrDirectory = [_myOutlineView itemAtRow: fileSelected];
        [fileOrDirectory removeItem];
    }
    [_myOutlineView reloadItem:nil reloadChildren:YES];

}


// This method checks if a root can be added to existing set.
-(NSInteger) canAddRoot: (NSString*) rootPath {
    NSInteger answer = pathsHaveNoRelation;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        answer =[root relationTo: rootPath];
        if (answer!=pathsHaveNoRelation) break;
    }
    return answer;
}

//-(FileCollection *) concatenateAllCollections {
//    FileCollection *collection =[[FileCollection new] init];
//    // Will concatenate all file collections into a single one.
//    for (TreeRoot *theRoot in BaseDirectoriesArray) {
//        [collection concatenateFileCollection: [theRoot fileCollection]];
//    }
//    return collection;
//}

-(void) selectAndExpand:(TreeBranch*) cursor {
    int retries = 2;
    while (retries) {
        NSInteger row = [_myOutlineView rowForItem:cursor];
        if (row!=-1) {
            [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            retries = 0; /* Finished, dont need to retry any more. */
        }
        else {
            retries--;
        }
        // The object was not found, will need to force the expand
        [_myOutlineView expandItem:[_myOutlineView itemAtRow:[_myOutlineView selectedRow]]];
        [_myOutlineView reloadData];

    }
    /* Sets the directory to be Displayed */
    _treeNodeSelected = cursor;

}

-(void) setPathBarToItem:(TreeItem*)item {
    if (_viewMode==BViewBrowserMode)
        [_myPathBarControl setRootPath:nil];
    else
        [_myPathBarControl setRootPath:[[item root] url]];
    if ([item isKindOfClass:[TreeBranch class]]) {
        [_myPathBarControl setURL: [item url]];
    }
    else {
        [_myPathBarControl setURL: [[item parent] url]];
    }
}

-(TreeBranch*) selectFirstRoot {
    if (BaseDirectoriesArray!=nil && [BaseDirectoriesArray count]>=1) {
        TreeRoot *root = BaseDirectoriesArray[0];
        [self selectAndExpand:root];
        [self setPathBarToItem:root];
        return root;
    }
    return NULL;
}

-(BOOL) selectFolderByItem:(TreeItem*) treeNode {
    if (BaseDirectoriesArray!=nil && [BaseDirectoriesArray count]>=1) {
        NSArray *treeComps = [treeNode treeComponents];

        for (TreeRoot *root in BaseDirectoriesArray) {
            if (root==treeComps[0]){ // Search for Root Node
                TreeBranch *lastBranch;
                for (TreeItem *node in treeComps) {
                    if ([node isKindOfClass:[TreeBranch class]] ||
                        [node isKindOfClass:[TreeRoot   class]])
                    {
                        [_myOutlineView expandItem:node];
                        [_myOutlineView reloadData];
                        lastBranch = (TreeBranch*)node;
                    }
                }
                [self setPathBarToItem:lastBranch];
                [self selectAndExpand:lastBranch];
                return YES;
            }
        }
    }
    return NO;
}

-(TreeBranch*) getItemByURL:(NSURL*)theURL {
    if (theURL==nil)
        return NULL;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        if ([root containsURL:theURL]) {
            /* The URL is already contained in this tree */
            /* Start climbing tree */
            NSArray *pcomps = [theURL pathComponents]; // Get the component Names
            NSUInteger level = [[[root url] pathComponents] count]; // Get the current level
            NSUInteger top_level = [pcomps count];
            TreeBranch *cursor = root;
            while (level < top_level) {
                TreeItem *child = [cursor itemWithName:pcomps[level] class:[TreeBranch class]];
                if ((child!=nil) && ([child isKindOfClass:[TreeBranch class]])) {
                    cursor = (TreeBranch*)child;
                    level++;
                }
                else
                    break;
            }
            if ([theURL isEqual:[cursor url]]) // This doesnt Work with TreeRoots:-( !!!
                return cursor;
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

-(void) startBusyAnimations {
    [_myOutlineProgressIndicator setHidden:NO];
    [_myFileViewProgressIndicator setHidden:NO];
	[_myOutlineProgressIndicator startAnimation:self];
    [_myFileViewProgressIndicator startAnimation:self];

}

#pragma mark - Action Outlets


- (IBAction) ChooseDirectory:(id)sender {
    NSOpenPanel *SelectDirectoryDialog = [NSOpenPanel openPanel];
    [SelectDirectoryDialog setTitle:@"Select a new Directory"];
    [SelectDirectoryDialog setCanChooseFiles:NO];
    [SelectDirectoryDialog setCanChooseDirectories:YES];
    NSInteger returnOption =[SelectDirectoryDialog runModal];
    if (returnOption == NSFileHandlingPanelOKButton) {
        if (_viewMode==BViewCatalystMode){
            NSString *rootPath = [[SelectDirectoryDialog URL] path];
            NSDictionary *answer = [NSDictionary dictionaryWithObjectsAndKeys:
                                    rootPath,kRootPathKey,
                                    self, kSenderKey,
                                    [NSNumber numberWithInteger:_viewMode], kModeKey,
                                    nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationCatalystRootUpdate object:self userInfo:answer];
        }
        else {
            [self removeRootWithIndex:0];
            [self addTreeRoot:[TreeRoot treeWithURL:[SelectDirectoryDialog URL]]];
            TreeRoot *node = [BaseDirectoriesArray objectAtIndex:0];
            if (NULL != node){
                [self selectFolderByItem:node];
            }
        }
    }
}

- (IBAction)PathSelect:(id)sender {
    /* Gets the clicked Cell */
    NSPathComponentCell *selectedPath =[_myPathBarControl clickedPathComponentCell];
    NSURL *newURL = [selectedPath URL];
    TreeBranch *node = [self getItemByURL: newURL];
    if (NULL == node ) {
        /* The path is not contained existing roots */
        if (_viewMode==BViewBrowserMode) {
            /* Instead of making a clever update of the tree
             Just remove the existing one and creates one from scratch */
            [self removeRootWithIndex:0];
            [self addTreeRoot:[TreeRoot treeWithURL:newURL]];
            node = [BaseDirectoriesArray objectAtIndex:0];
        }
    }
    if (NULL != node){
        [self selectFolderByItem:node];
    }
}

- (IBAction)FilterChange:(id)sender {
    _filterText = [sender stringValue];
    [self refreshDataView];
}

-(NSArray*) getSelectedItems {
    NSArray* answer = nil;
    if (_focusedView==_myOutlineView) {
        /* This is done like this so that not more than one folder is selected */
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        if ([rowsSelected count]) {
            answer = [NSArray arrayWithObject:[_myOutlineView itemAtRow:[rowsSelected firstIndex]]];
        }
        else {
            answer = [[NSArray alloc] init]; // will send an empty array
        }
    }
    else if (_focusedView == _myTableView) {
        NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
        answer = [tableData objectsAtIndexes:rowsSelected];
    }
    return answer;
}

@end
