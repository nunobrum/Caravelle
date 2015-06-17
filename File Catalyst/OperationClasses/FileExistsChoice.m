//
//  FileExistsChoice.m
//  File Catalyst
//
//  Created by Nuno Brum on 16/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileExistsChoice.h"
#import "FileUtils.h"
#import "myValueTransformers.h"
#import "CustomTableHeaderView.h" // imported to have access to column utility functions
#include "Definitions.h"

NSString *notificationClosedFileExistsWindow = @"FileExistsWindowClosed";
NSString *kFileExistsAnswerKey = @"FileExistsAnswer";
NSString *kFileExistsNewFilenameKey = @"NewFilename";

#define COL_NAME @"name"
#define COL_SOURCE @"source"
#define COL_DEST @"destination"

NSString * const mandatoryFields[] = { @"COL_PATH", @"COL_SIZE", @"COL_DATE_MODIFIED" };

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
    [[self window] setIsVisible:NO];
    _pendingUserDecision = NO;
}

-(void) displayWindow:(id) sender {
    if (_pendingUserDecision==YES) {
        [[self window] setIsVisible:YES];
        [self showWindow:sender];
        [[self window] makeKeyAndOrderFront:sender];
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

//- (IBAction) close:(id)sender {
//    NSLog(@"FileExistsChoice.close: User trying to close");
//}
//
//-(BOOL) windowShouldClose:(id)sender {
//    return NO; // Always block the close button
//}

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
        name = duplicateFileNameProposal([dest path]);
    }
    else {
        name = [source name];
    }
    [[self tfFilename] setStringValue: [source path]];
    [[self tfNewFilename] setStringValue:name];

    for (int i=0; i < sizeof(mandatoryFields)/sizeof(NSString*); i++) {
        NSString *colKey = mandatoryFields[i];
        NSDictionary *dic = compareForField(source, dest, colKey, NO);
        [attributesTable addObject:dic];
    }

    for (NSString *colKey in sortedColumnNames()) {
        int i;
        for (i=0; i < sizeof(mandatoryFields)/sizeof(NSString*); i++) {
            if ([colKey isEqualToString: mandatoryFields[i]])
                break; // It was already displayed in the previous cycle
        }
        if (i == sizeof(mandatoryFields)/sizeof(NSString*)) { // if it wasnt found before
            NSDictionary *dic = compareForField(source, dest, colKey, YES);
            if (dic) {
                [attributesTable addObject:dic];
            }
        }
    }


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
    if (obj)
        [[cellView textField ] setStringValue: obj];
    // TODO:!? use the same value transformers as the defined for the tableView on BrowserController.
    // This in order to have the size displayed in kB,MB,GB

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
