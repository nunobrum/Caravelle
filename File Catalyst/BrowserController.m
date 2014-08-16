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
    self->BaseDirectoriesArray = [[NSMutableArray new] init];
    self->_extendToSubdirectories = NO;
    self->_foldersInTable = YES;
    self->_catalystMode = YES;
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
    // Use KVO to observe for changes of its children Array
    if (![_observedVisibleItems containsObject:ret]) {
        if ([ret isKindOfClass:[TreeBranch class]]) {
            [ret addObserver:self forKeyPath:kvoTreeBranchPropertyChildren options:0 context:NULL];
            //NSLog(@"Adding Observer to %@", [ret name]);
            [(TreeBranch*)ret refreshContentsOnQueue:_sharedOperationQueue];
            [_observedVisibleItems addObject:ret];
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
    NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    if ([result isKindOfClass:[FolderCellView class]]) {
        FolderCellView *cellView = (FolderCellView *)result;

        if ([[tableColumn identifier] isEqualToString:COL_FILENAME]) {
            if ([item isKindOfClass:[TreeLeaf class]]) {//if it is a file
                // This is not needed now since the Tree View is not displaying files in this application
            }
            else if ([item isKindOfClass:[TreeBranch class]]) { // it is a directory
                // Display the directory name followed by the number of files inside
                NSString *path = [(TreeBranch*)item path];
                NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];

                NSString *subTitle;
                if (self->_catalystMode==YES) {
                    subTitle = [NSString stringWithFormat:@"%ld Files %@",
                                (long)[(TreeBranch*)item numberOfLeafsInBranch],
                                [NSByteCountFormatter stringFromByteCount:[item filesize] countStyle:NSByteCountFormatterCountStyleFile]];
                }
                else {
                    subTitle = @""; //[NSString stringWithFormat:@"%ld Files here",
                    //(long)[(TreeBranch*)item numberOfLeafsInBranch]];
                }
                [cellView setSubTitle:subTitle];
                [[cellView imageView] setImage:icon];
                [cellView setTitle:[item name]];
            }
        }
    }
    return result;
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
    return [outlineView rowHeight];
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
    if (index != NSNotFound) {
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
    if([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ]){
        NSArray *object;
        NSDictionary *answer=nil;
        NSIndexSet *rowsSelected = [_myOutlineView selectedRowIndexes];
        NSInteger SelectedCount = [rowsSelected count];
        if (SelectedCount ==0) {
            /* Sends an Empty Array */
            object = [[NSArray new] init];
            answer = [NSDictionary dictionaryWithObject:object forKey:selectedFilesNotificationObject];
        } else if (SelectedCount==1) {
            /* Updates the _treeNodeSelected */
            _treeNodeSelected = [_myOutlineView itemAtRow:[rowsSelected firstIndex]];
            [_myPathBarControl setRootPath:[[_treeNodeSelected root] url] Catalyst:_catalystMode];
            [_myPathBarControl setURL: [_treeNodeSelected url]];
            [self refreshDataView];
            /* Sends an Array with one Object */
            object = [NSArray arrayWithObject:_treeNodeSelected];
            answer = [NSDictionary dictionaryWithObject:object forKey:selectedFilesNotificationObject];

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
    //[self refreshDataView];
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
        }
    }
    else if ([identifier isEqualToString:COL_SIZE]) {
        if (_catalystMode==NO && [theFile isKindOfClass:[TreeBranch class]]){
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
        NSDictionary *answer = [NSDictionary dictionaryWithObject:objects forKey:selectedFilesNotificationObject];
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
        NSDictionary *nodeInfo = [self getFileAtIndex:index];
        id node = [nodeInfo objectForKey:COL_FILENAME];
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

#pragma mark - KVO Methods

- (void)_reloadRowForEntity:(id)object {
    NSInteger row = [_myOutlineView rowForItem:object];
    if (row != NSNotFound) {
        [_myOutlineView reloadItem:object reloadChildren:YES];
        NSLog(@"Reloading %@", [object name]);
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
        [self stopBusyAnimations];
        [_myTableView reloadData];
    }
}

-(void) refreshTrees {
    if (_catalystMode) {
        //for (TreeRoot *tree in BaseDirectoriesArray)
        {
            NSLog(@"!!! Solve this");
            //[tree refreshTreeFromCollection:{}];
        }
    }
    else {
        for (TreeRoot *tree in BaseDirectoriesArray) {
            [tree refreshTreeFromURLs];
        }
    }
    // !!! Todo Add condition : if number of roots = 1 then
    // Expand the Root Node
    [_myOutlineView reloadData];
    [self refreshDataView];
}

-(void) addTreeRoot:(TreeRoot*)theRoot {
    NSInteger answer = [self canAddRoot:[theRoot rootPath]];
    if (answer == pathsHaveNoRelation) {

        [BaseDirectoriesArray addObject: theRoot];
    }
    /* Refresh the Trees so that the trees are displayed */
    [self refreshTrees];
    /* Make the Root as selected */
    [self selectFolderByURL:[theRoot url]];

}

-(void) removeRootWithIndex:(NSInteger)index {
    if (index < [BaseDirectoriesArray count]) {
        TreeRoot *itemToBeDeleted = [BaseDirectoriesArray objectAtIndex:index];
        [itemToBeDeleted removeBranch];
        [BaseDirectoriesArray removeObjectAtIndex:index];
    }
    [self refreshTrees];
}

-(void) removeRoot: (TreeRoot*) root {
    [root removeBranch];
    [BaseDirectoriesArray removeObjectIdenticalTo:root];
    [self refreshDataView];
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

-(FileCollection *) concatenateAllCollections {
    FileCollection *collection =[[FileCollection new] init];
    // Will concatenate all file collections into a single one.
    for (TreeRoot *theRoot in BaseDirectoriesArray) {
        [collection concatenateFileCollection: [theRoot fileCollection]];
    }
    return collection;
}

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

-(TreeBranch*) selectFolderByURL:(NSURL*)theURL {
    NSRange result;
    BOOL found = false;
    TreeBranch *cursor = NULL;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        NSString *path = [theURL path];
        result = [path rangeOfString:[root path]];
        if (NSNotFound!=result.location) {
            /* The URL is already contained in this tree */
            /* Start climbing tree */
            //[_myPathBarControl setRootPath:[root theURL] Catalyst:_catalystMode];
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
    if (found) {/* Exited by the break */
        /* Update data in the Table */
        [self selectAndExpand:cursor];
        //[_myPathBarControl setURL:[cursor theURL]];
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
        if (_catalystMode){
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
        if (_catalystMode==NO) {
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
