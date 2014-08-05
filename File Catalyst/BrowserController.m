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
#import "LeftDataSource.h"

#define COL_FILENAME @"NameID"
#define COL_DATE     @"ModifiedID"
#define COL_SIZE     @"SizeID"


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




-(BrowserController*) init {
    self = [super init];
    self->_extendToSubdirectories = NO;
    self->tableData = [[NSMutableArray new] init];
    self->_foldersInTable = YES;
    self->_catalystMode = YES;
    self->_filterText = @"";
    return self;
}

- (void)awakeFromNib {
    [_myTableView setTarget:self];
    [_myTableView setDoubleAction:@selector(TableDoubleClickEvent:)];
}

// NSWorkspace Class Reference - (NSImage *)iconForFile:(NSString *)fullPath



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
    if ([ret isBranch] && _catalystMode==NO)
        [ret refreshTreeFromURLs];
    return ret;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[NSMutableArray class]])
        return [item count]>1 ? YES : NO;
    else {
        return ([item isBranch] && [item numberOfBranchesInNode]!=0) ? YES : NO;
    }
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
                                [NSByteCountFormatter stringFromByteCount:[item byteSize] countStyle:NSByteCountFormatterCountStyleFile]];
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

/*
 * Tree Outline View Data Delegate Protocol
 */


/* Called before the outline is selected.
 Workaround to make the path bar always updated.
 Can be used later to block access to private directories */
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    [_myPathBar setURL: [item theURL]];
    _treeNodeSelected = item;
    return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [_myTableView reloadData];
}


/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    [self refreshDataView];
    return [tableData count];
}

- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    TreeItem *theFile = [tableData objectAtIndex:rowIndex];
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [aTableColumn identifier];
    // We pass us as the owner so we can setup target/actions into this main controller object
    NSTableCellView *cellView = [aTableView makeViewWithIdentifier:identifier owner:self];

    if ([identifier isEqualToString:COL_FILENAME]) {
        NSString *path = [theFile path];
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
            cellView.textField.objectValue = [NSByteCountFormatter stringFromByteCount:[theFile byteSize] countStyle:NSByteCountFormatterCountStyleFile];

    } else if ([identifier isEqualToString:COL_DATE]) {
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

/*
 * Table Data Delegate Protocol
 */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if([[aNotification name] isEqual:NSTableViewSelectionDidChangeNotification ]){
        NSLog(@"Table Selection Changed");
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationStatusUpdate object:self userInfo:nil];
    }
}


/* This action is associated manually with the setDoubleAction */
- (IBAction)TableDoubleClickEvent:(id)sender {
    if(sender == self->_myTableView) {
        NSIndexSet *rowsSelected = [_myTableView selectedRowIndexes];
        NSUInteger index = [rowsSelected firstIndex];
        while (index!=NSNotFound) {
            /* Do something here */
            id node =[self getFileAtIndex:index];
            if ([node isKindOfClass: [TreeLeaf class]]) { // It is a file : Open the File
                [[node getFileInformation] openFile];
            }
            else if ([node isKindOfClass: [TreeBranch class]]) { // It is a directory
                // Going to open the Select That directory on the Outline View
                int retries = 2;
                while (retries) {
                    NSInteger row = [_myOutlineView rowForItem:node];
                    if (row!=-1) {
                        [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                        retries = 0; /* Finished, dont need to retry any more. */
                        /* Set the path bar */
                        [_myPathBar setURL: [node theURL]];
                        /* Setting the node for Table Display */
                        self.treeNodeSelected=node;
                    }
                    else {
                        // The object was not found, will need to force the expand
                        [_myOutlineView expandItem:[_myOutlineView itemAtRow:[_myOutlineView selectedRow]]];
                        [_myOutlineView reloadData];
                        retries--;
                    }
                }
                [_myTableView reloadData];
            }
            index = [rowsSelected indexGreaterThanIndex:index];

        }
    }
}

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
    }
    /* if the filter is empty, doesn't filter anything */
    if ([self->_filterText length]==0)
        return;
    /* Create the array of indexes to remove/hide/disable*/
    NSInteger i = 0;
    for (TreeItem *item in tableData){
        NSRange result = [[item name] rangeOfString:_filterText];
        if (NSNotFound==result.location)
            [tohide addIndex:i];
        i++;
    }
    [tableData removeObjectsAtIndexes: tohide];

}

-(void) refreshTrees {
    if (_catalystMode) {
        for (TreeRoot *tree in BaseDirectoriesArray) {
            [tree refreshTreeFromCollection];
        }
    }
    else {
        for (TreeRoot *tree in BaseDirectoriesArray) {
            [tree refreshTreeFromURLs];
        }
    }
    [self refreshDataView];
}

-(void) addWithFileCollection:(FileCollection *)fileCollection callback:(void (^)(NSInteger fileno))callbackhandler {
    TreeRoot *rootDir = [[TreeRoot new] init];
    NSURL *rootpath = [NSURL URLWithString:[fileCollection rootPath]];

    // assigns the name to the root directory
    [rootDir setTheURL: rootpath];
    [rootDir setFileCollection: fileCollection];
    [rootDir setIsCollectionSet:YES];


    if(BaseDirectoriesArray==nil) {
        BaseDirectoriesArray = [[NSMutableArray new] init];
    }
    [BaseDirectoriesArray addObject: rootDir];
    /* Make the Root as selected */
    [self selectFolderByURL:rootpath];

}
-(void) addWithRootPath:(NSURL*) rootPath {
    TreeRoot *rootDir = [[TreeRoot new] init];
    // assigns the name to the root directory
    [rootDir setTheURL: rootPath];
    [rootDir setFileCollection: NULL];
    [rootDir setIsCollectionSet:NO];
    //[rootDir refreshTreeFromURLs];

    if(BaseDirectoriesArray==nil) {
        BaseDirectoriesArray = [[NSMutableArray new] init];
    }
    [BaseDirectoriesArray addObject: rootDir];
    /* Make the Root as selected */
    [self selectFolderByURL:rootPath];

}

-(void) removeRootWithIndex:(NSInteger)index {
    TreeRoot *itemToBeDeleted = [BaseDirectoriesArray objectAtIndex:index];
    [itemToBeDeleted removeBranch];
    [BaseDirectoriesArray removeObjectAtIndex:index];
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
        [self removeRootWithIndex:fileSelected];
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
    NSInteger answer = rootCanBeInserted;
    NSRange result;
    for(TreeRoot *root in BaseDirectoriesArray) {
        /* Checks if rootPath in root */
        result = [rootPath rangeOfString:[root path]];
        if (NSNotFound!=result.location) {
            // The new root is already contained in the existing trees
            answer = rootAlreadyContained;
            NSLog(@"The added path is contained in existing roots.");

        }
        else {
            /* The new contains exiting */
            result = [[root path] rangeOfString:rootPath];
            if (NSNotFound!=result.location) {
                // Will need to replace current position
                answer = rootContainsExisting;
                NSLog(@"The added path contains already existing roots, please delete them.");
                //[root removeBranch];
                //fileCollection_inst = [root fileCollection];
            }
        }
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
            cursor = root;
            do {
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
        /* Select the node in the outline View */
        NSInteger row = [_myOutlineView rowForItem:cursor];
        if (row!=-1) {
            [_myOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            /* Sets the directory to be Displayed */
            _treeNodeSelected = cursor;
            /* Update data in the Table */
            [self refreshDataView];
        }
        return cursor;
    }
    return NULL;
}

- (IBAction)PathSelect:(id)sender {
    /* Gets the clicked Cell */
    NSPathComponentCell *selectedPath =[_myPathBar clickedPathComponentCell];
    /* Discovers the position of the Cell in the Path */
    NSRange r;
    r.location = 0;
    /* + 2 for counting with root and the index range is to index - 1 */
    r.length = [[_myPathBar pathComponentCells] indexOfObject:selectedPath]+2;
    /* Gets the URL components*/
    NSArray *components = [[_myPathBar URL] pathComponents];
    /* Creates the new Path */
    NSURL *newURL = [NSURL fileURLWithPathComponents: [components subarrayWithRange:r]];
    TreeBranch *node = [self selectFolderByURL: newURL];
    if (node != NULL) {
        /* Set the path bar */
        [_myPathBar setURL: [node theURL]];
        /* Update file table */
        [_myTableView reloadData];
    }
    else { /* The path is not contained existing roots */
        // !!! Todo : send message to AppDelegate
        //[self DirectoryScan:[newURL path]];
    }
}

- (IBAction)FilterChange:(id)sender {
    _filterText = [sender stringValue];
    [_myTableView reloadData];
}


@end
