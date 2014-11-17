//
//  FileExistsChoice.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 16/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileExistsChoice.h"


NSString *notificationClosedFileExistsWindow = @"FileExistsWindowClosed";

#define COL_NAME @"name"
#define COL_SOURCE @"source"
#define COL_DEST @"destination"

@interface FileExistsChoice ()

@end

@implementation FileExistsChoice


- (id)initWithWindowNibName:(NSString *)windowNibName
{
    // Use the identifier @"wndDuplicateFinderSettingsWindow"
    if (windowNibName==nil)
        windowNibName = @"FileExistsChoice";
    self = [super initWithWindowNibName:windowNibName];
    return self;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSLog(@"FileExistsChoice Window didLoad");
}

- (IBAction)pbReplace:(id)sender {
    _answer = FileExistsReplace;
    // Notify AppDelegate that an option was taken
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationClosedFileExistsWindow object:nil userInfo:nil];
    [self close];
}

- (IBAction)pbSkip:(id)sender {
    // Notify AppDelegate that an option was taken
    _answer = FileExistsSkip;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationClosedFileExistsWindow object:nil userInfo:nil];
    _answer = FileExistsSkip;
    [self close];
}
- (IBAction)pbRename:(id)sender {
    // Notify AppDelegate that an option was taken
    _answer = FileExistsRename;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationClosedFileExistsWindow object:nil userInfo:nil];
    [self close];
}

-(BOOL) makeTableWithSource:(TreeItem*)source andDestination:(TreeItem*) dest {
    /* Remove all objects */
    if (attributesTable==nil)
        attributesTable = [[NSMutableArray alloc] init];
    // Empty table
    [attributesTable removeAllObjects];

    // !!! TODO: Fill comparison Table
    if ([source compareTo: dest]==pathIsSame) {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Path",@"name",
                             [source path],@"source",
                             [dest path],@"destination",
                             nil];
        [attributesTable addObject:dic];
        [_pbReplace setHidden:YES];
        [_pbSkip setTitle:@"Skip"];
        NSString *name = [NSString stringWithFormat:@"Copy of %@",[[dest path] lastPathComponent]];
        [[self tfFilename] setStringValue: [source path]];
        [[self tfNewFilename] setStringValue:name];
    }
    [_attributeTableView reloadData];
    return YES;
}

-(NSString*) new_filename {
    return [_tfNewFilename stringValue];
}


#pragma mark - TableView Datasource Protocol

/*
 * Table Data Source Protocol
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [attributesTable count];
}

- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString *identifier = [aTableColumn identifier];
    NSTableCellView *cellView = [aTableView makeViewWithIdentifier:identifier owner:self];
    cellView.textField.stringValue = [[attributesTable objectAtIndex:rowIndex] objectForKey:identifier];
    return cellView;
}

@end
