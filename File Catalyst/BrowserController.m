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


@implementation BrowserController

#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self->blockTableRefresh = NO;
    self->BaseDirectoriesArray = [[NSMutableArray new] init];
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_viewMode = BViewBrowserMode;
    self->_filterText = @"";
    self->tableInfo = [NSMutableArray arrayWithObjects: SYSTEM_COLUMNS, nil];
    [self->tableInfo addObjectsFromArray:[NSArray arrayWithObjects: DEFAULT_COLUMNS, nil]];
    self->TableSortDesc = nil;
    self->_observedVisibleItems = [[NSMutableArray new] init];
    _sharedOperationQueue = [[NSOperationQueue alloc] init];
    // We limit the concurrency to see things easier for demo purposes. The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield better results, as it will create more threads, as appropriate for your processor
    [_sharedOperationQueue setMaxConcurrentOperationCount:2];

    return self;
}

//- (void)dealloc {
//    // Stop any observations that we may have
//    for (FolderCellView *imageEntity in _observedVisibleItems) {
//        [imageEntity removeObserver:self forKeyPath:ATEntityPropertyNamedThumbnailImage];
//    }
//    [super dealloc];
//}

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
    if (_viewMode==BViewBrowserMode) {
        // Use KVO to observe for changes of its children Array
        if (![_observedVisibleItems containsObject:ret]) {
            if ([ret isKindOfClass:[TreeBranch class]]) {
                [ret addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
                //NSLog(@"Adding Observer to %@", [ret name]);
                [(TreeBranch*)ret refreshContentsOnQueue:_sharedOperationQueue];
                [_observedVisibleItems addObject:ret];
            }
        }
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
    //NSLog(@"Removing from observed '%@'", [item name]);
    NSInteger index = item ? [_observedVisibleItems indexOfObject:item] : NSNotFound;
    if (index != NSNotFound && item!=_treeNodeSelected) { //keep observing the selected folder
        [item removeObserver:self forKeyPath:kvoTreeBranchPropertyChildren];
        [_observedVisibleItems removeObjectAtIndex:index];
    }
    //else
    //    NSLog(@"Didnt Find it");
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
    if(([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ]) && (!blockTableRefresh)) {
        NSArray *object;
        NSDictionary *answer=nil;
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        NSInteger SelectedCount = [rowsSelected count];
        if (SelectedCount ==0) {
            /* Sends an Empty Array */
            object = [[NSArray new] init];
            answer = [NSDictionary dictionaryWithObject:object forKey:kSelectedFilesKey];
            [_myTableView unregisterDraggedTypes];
        } else if (SelectedCount==1) {
            /* Updates the _treeNodeSelected */
            [_myTableView registerForDraggedTypes:[NSArray arrayWithObjects: (id)kUTTypeFolder, (id)kUTTypeFileURL, NSFilenamesPboardType, nil]];
            _treeNodeSelected = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            [self setPathBarToItem:_treeNodeSelected];
            [self refreshDataView];
            /* Sends an Array with one Object */
            object = [NSArray arrayWithObject:_treeNodeSelected];
            answer = [NSDictionary dictionaryWithObject:object forKey:kSelectedFilesKey];

        }
        else {
            // !!! Houston we have a problem
        }

        if (answer != nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:answer];
        }
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
        //NSLog(@"Table Selection Changed");
        NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
        NSArray *objects = [tableData objectsAtIndexes:rowsSelected];
        NSDictionary *answer = [NSDictionary dictionaryWithObject:objects forKey:kSelectedFilesKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:answer];
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
            [self selectAndExpand:node];
            /* Set the path bar */
            //[_myPathBarControl setURL: [node theURL]];
            /* Setting the node for Table Display */
            self.treeNodeSelected=node;
            [_myTableView reloadData];
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

    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    ptypes =[pboard types];

    if (aTableView!=_myTableView) { /* Protection , just in case */
        NSLog(@"Ooops! This isnt supposed to happen");
        return NSDragOperationNone;
    }
    @try {
        targetItem = [tableData objectAtIndex:row];
    }
    @catch (NSException *exception) {
        targetItem = _treeNodeSelected;
    }
    @finally {
        // Go away... nothing to see here
    }
    //NSLog(@"validate Drop %ld %lX", row, sourceDragMask);

    /* Limit the Operations depending on the Item Class*/
    if ([targetItem isKindOfClass:[TreeBranch class]]) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    }
    else if ([targetItem isKindOfClass:[TreeLeaf class]]) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        return NSDragOperationNone;
    }

    if ( [ptypes containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
        else if (sourceDragMask & NSDragOperationMove) {
            return NSDragOperationMove;
        }
        else if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        }
        else if (sourceDragMask & NSDragOperationGeneric) {
            return NSDragOperationGeneric;
        }
    }
    else if ( [ptypes containsObject:(id)kUTTypeFileURL] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
        else if (sourceDragMask & NSDragOperationMove) {
            return NSDragOperationMove;
        }
        else if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSLog(@"accept row %ld", row);
    BOOL answer = NO;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSDragOperation sourceDragMask = [info draggingSourceOperationMask];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    NSString *opCommand=nil;
    id destination;
    // !!! TODO : Test the row is on the table itself.
    if (operation == NSTableViewDropAbove) {
        //Inserts the rows using the specified animation.
        int i= 0;
        for (NSURL *pastedItem in files) {
            //[(TreeBranch*)targetItem addURL:pastedItem]; This will be done on the refresh after copy
            TreeItem *newItem = [TreeItem treeItemForURL: pastedItem parent:_treeNodeSelected];
            [tableData insertObject:newItem atIndex:row+i];
            [aTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:row+i] withAnimation:NSTableViewAnimationSlideDown];
            //NSLog(@"Copy Item %@", [pastedItem lastPathComponent]);
            i++;
        }
        destination = [_treeNodeSelected url];
        answer= YES;
        opCommand = opCopyOperation;
    }
    else if (operation == NSTableViewDropOn){
        TreeItem *targetItem = [tableData objectAtIndex:row];
        if ([targetItem isKindOfClass:[TreeBranch class]]) {
            if (sourceDragMask & NSDragOperationCopy) {
                opCommand = opCopyOperation;
                destination = [targetItem url];
                answer = YES;
            }
            else if (sourceDragMask & NSDragOperationMove) {
                // TODO !!! Operation Move (Needs to delete the file from the source)
                opCommand = opMoveOperation;
            }
            else if (sourceDragMask & NSDragOperationLink) {
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
    if (answer==YES) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kSelectedFilesKey,
                              self, kSenderKey,  // pass back to check if user cancelled/started a new scan
                              opCommand, kOperationKey,
                              destination, kDestinationKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];

    }
    return answer;
}

//- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
//    return YES;
//} // !!! TODO use the method below for further control
- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSLog(@"write to paste board, passing handle to item at row %ld",row);
    return (id <NSPasteboardWriting>) [tableData objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
    NSLog(@"info: drag session will start %@",rowIndexes);
}

- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id < NSDraggingInfo >)draggingInfo {
    NSLog(@"info : update dragging items");
}
#pragma mark - KVO Methods

- (void)_reloadRowForEntity:(id)object {
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


#pragma mark - Interface Methods


/*
 * Parent access routines
 */

-(void) setViewMode:(BViewMode)viewMode {
    _viewMode = viewMode;
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
        TreeRoot *itemToBeDeleted = [BaseDirectoriesArray objectAtIndex:index];
        [itemToBeDeleted removeBranch];
        [BaseDirectoriesArray removeObjectAtIndex:index];
    }
    //[self refreshTrees];
}

-(void) removeRoot: (TreeRoot*) root {
    [root removeBranch];
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
        [fileOrDirectory sendToRecycleBin];
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
            // The object was not found, will need to force the expand
            [_myOutlineView expandItem:[_myOutlineView itemAtRow:[_myOutlineView selectedRow]]];
            [_myOutlineView reloadData];
            retries--;
        }
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
        [self refreshDataView];
        return root;
    }
    return NULL;
}

-(TreeBranch*) selectFolderByItem:(TreeItem*) treeNode {
    if (BaseDirectoriesArray!=nil && [BaseDirectoriesArray count]>=1) {
        NSArray *treeComps = [treeNode treeComponents];

        for (TreeRoot *root in BaseDirectoriesArray) {
            if (root==treeComps[0]){ // Search for Root Node
                TreeBranch *lastBranch;
                for (TreeItem *node in treeComps) {
                    if ([node isKindOfClass:[TreeBranch class]])
                    {
                        lastBranch = (TreeBranch*)node;
                        [self selectAndExpand:lastBranch];
                    }
                }
                [self setPathBarToItem:lastBranch];
                [self refreshDataView];
                return lastBranch;
            }
        }
    }
    return NULL;
}

-(TreeBranch*) selectFolderByURL:(NSURL*)theURL {
    NSRange result;
    BOOL found = false;
    TreeBranch *cursor = NULL;
    if (theURL==nil)
        return NULL;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        NSString *path = [theURL path];
        result = [path rangeOfString:[root path]];
        if (NSNotFound!=result.location) {
            /* The URL is already contained in this tree */
            /* Start climbing tree */
            //[_myPathBarControl setRootPath:[root theURL] Catalyst:_catalystMode];
            blockTableRefresh = YES; /* this is to avoid that Table is populated each time the cursor change */
            cursor = root;
            do {
                [self selectAndExpand:cursor];
                /* Test if the current directory is already a match */
                NSComparisonResult res = [[cursor path] compare:path];
                if (res==NSOrderedSame) { /* Matches the directory. Maybe there is a more clever way to do this. */
                    found = true;
                    break;
                }
                else {
                    found=FALSE;
                    for (TreeBranch *child in [cursor children]) {
                        result = [path rangeOfString:[child path]];
                        //NSLog(@"Cursor=%@ Child=%@, result=%lu", [cursor path], [child path], (unsigned long)result.location);
                        if (NSNotFound!=result.location) { /* Matches the directory. Maybe there is a more clever way to do this. */
                            cursor = child;
                            found = true;
                            break;
                        }

                    }
                }
            } while (found);
        }
        if (found)
            break;
    }
    blockTableRefresh = NO;
    if (found) {/* Exited by the break */
        /* Update data in the Table */
        [self selectAndExpand:cursor];
        [self setPathBarToItem:cursor];
        [self refreshDataView];
        return cursor;
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
                                    [NSNumber numberWithBool:YES], kModeKey,
                                    nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationCatalystRootUpdate object:self userInfo:answer];
        }
        else {
            [self removeRootWithIndex:0];
            [self addTreeRoot:[TreeRoot treeWithURL:[SelectDirectoryDialog URL]]];
            TreeRoot *node = [BaseDirectoriesArray objectAtIndex:0];
            if (NULL != node){
                [self selectFolderByURL:[node url]];
            }
        }
    }
}

- (IBAction)PathSelect:(id)sender {
    /* Gets the clicked Cell */
    NSPathComponentCell *selectedPath =[_myPathBarControl clickedPathComponentCell];
    NSURL *newURL = [selectedPath URL];
    TreeBranch *node = [self selectFolderByURL: newURL];
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
        [self selectFolderByURL:[node url]];
    }
}

- (IBAction)FilterChange:(id)sender {
    _filterText = [sender stringValue];
    [_myTableView reloadData];
}


@end
