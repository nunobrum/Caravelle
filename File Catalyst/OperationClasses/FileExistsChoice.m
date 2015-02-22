//
//  FileExistsChoice.m
//  File Catalyst
//
//  Created by Nuno Brum on 16/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileExistsChoice.h"
#import "FileUtils.h"


NSString *notificationClosedFileExistsWindow = @"FileExistsWindowClosed";
NSString *kFileExistsAnswerKey = @"FileExistsAnswer";
NSString *kFileExistsNewFilenameKey = @"NewFilename";

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
    _pendingUserDecision = NO;
    return self;
}

-(BOOL) pendingUserDecision {
    return _pendingUserDecision;
}

-(void) closeWindow {
    [[self windowOutlet] setIsVisible:NO];
}

-(void) displayWindow:(id) sender {
    if (_pendingUserDecision==YES) {
        [[self windowOutlet] setIsVisible:YES];
        [self showWindow:sender];
        [[self windowOutlet] makeKeyAndOrderFront:sender];
    }
}

-(void) sendNotification:(NSInteger) answer {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInteger:answer], kFileExistsAnswerKey,
                          [_tfNewFilename stringValue], kFileExistsNewFilenameKey, nil];
    // Notify AppDelegate that an option was taken
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationClosedFileExistsWindow object:self userInfo:info];
    _pendingUserDecision = NO;

}

- (IBAction)actionOverwrite:(id)sender {
    // Notify AppDelegate that an option was taken
    [self sendNotification:FileExistsReplace];
}

- (IBAction)actionSkip:(id)sender {
    // Notify AppDelegate that an option was taken
    [self sendNotification:FileExistsSkip];
}
- (IBAction)actionRename:(id)sender {
    // Notify AppDelegate that an option was taken
    [self sendNotification:FileExistsRename];
}

-(BOOL) makeTableWithSource:(TreeItem*)source andDestination:(TreeItem*) dest {
    NSString *name;
    /* Remove all objects */
    if (attributesTable==nil)
        attributesTable = [[NSMutableArray alloc] init];
    // Empty table
    [attributesTable removeAllObjects];

    // If the paths are the same, i.e. the same file, just offer to rename
    if ([source compareTo: dest]==pathIsSame) {
        [_pbReplace setHidden:YES];
        [_labelKeep setHidden:YES];
        [_labelFilesAreTheSame setHidden:NO];
    }
    // Put as before
    else {
        [_pbReplace setHidden:NO];
        [_labelKeep setHidden:NO];
        [_labelFilesAreTheSame setHidden:YES];

    }

    // If the file names are the same, create a copy name
    if ([[source name] isEqualToString:[dest name]]) {
        // TODO: !!! make rename proposal more inline with the MACOSX standard
        name = [NSString stringWithFormat:@"Copy of %@",[dest name]];
    }
    else {
        name = [source name];
    }
    [[self tfFilename] setStringValue: [source path]];
    [[self tfNewFilename] setStringValue:name];


    // !!! TODO: Fill comparison Table based upon the Plist

    // Path
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"Path",@"name",
                         [source path],@"source",
                         [dest path],@"destination",
                         nil];
    [attributesTable addObject:dic];

    // Size
    dic = [NSDictionary dictionaryWithObjectsAndKeys:
           @"Size",@"name",
           [source fileSize],@"source",
           [dest fileSize],@"destination",
           nil];
    [attributesTable addObject:dic];
    [_attributeTableView reloadData];

    // set focus
    _pendingUserDecision = YES;
    return YES;
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
    id obj = [[attributesTable objectAtIndex:rowIndex] objectForKey:identifier];

    // To avoid assertion faults when passing a nil to the selector setStringValue
    // TODO:? use the same value transformers as the defined for the tableView on BrowserController.
    if (obj)
        [[cellView textField ] setStringValue: obj];
    return cellView;
}

/*
 * NSTextDelegate
 */
#pragma mark - NSControlTextDelegate Protocol


- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    //NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        // In cancel close the dialog
        [self actionSkip:nil];
    }

    return NO;
}


- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self actionRename:nil];
}

@end
