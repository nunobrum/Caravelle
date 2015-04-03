//
//  TableViewController.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 03/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
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



@end
