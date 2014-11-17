//
//  DuplicateFindSettingsViewController.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 25/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "AppOperation.h"

NSString *notificationStartDuplicateFind = @"StartDuplicateFind";

@interface ValueToBoolean : NSValueTransformer

@end

@implementation ValueToBoolean

+ (Class)transformedValueClass
{
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation
{
    return NO;
}
- (id)transformedValue:(id)value
{
    NSNumber *output;
    if (value == nil) return nil;

    // Attempt to get a reasonable value from the
    // value object.
    if ([value respondsToSelector: @selector(intValue)]) {
        // handles NSString and NSNumber
        int test = [value intValue];
        output = [NSNumber numberWithBool:(test!=0)];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -intValue.",
         [value class]];
    }

    return output;
}

@end

#import "DuplicateFindSettingsViewController.h"

@interface DuplicateFindSettingsViewController ()

@end

@implementation DuplicateFindSettingsViewController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    // Use the identifier @"wndDuplicateFinderSettingsWindow"
    if (windowNibName==nil)
        windowNibName = @"DuplicatesFindSettings";
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
        ValueToBoolean *fToCTransformer;

        // create an autoreleased instance of our value transformer
        fToCTransformer = [[ValueToBoolean alloc] init];

        // register it with the name that we refer to it with
        [NSValueTransformer setValueTransformer:fToCTransformer
                                        forName:@"ValueToBoolean"];
    }
    return self;
}

- (IBAction)addRemoveFolderButton:(id)sender {
    // Determine if + or -
    NSInteger PlusOrMinus = [(NSSegmentedControl*)sender selectedSegment];
    if (PlusOrMinus==0) {/* This is an Add */
        NSOpenPanel *SelectDirectoryDialog = [NSOpenPanel openPanel];
        [SelectDirectoryDialog setTitle:@"Select a new Directory"];
        [SelectDirectoryDialog setCanChooseFiles:NO];
        [SelectDirectoryDialog setCanChooseDirectories:YES];
        NSInteger returnOption =[SelectDirectoryDialog runModal];
        if (returnOption == NSFileHandlingPanelOKButton) {
            NSURL *rootURL = [SelectDirectoryDialog URL];
            NSDictionary *newItem = [NSDictionary dictionaryWithObject:rootURL forKey:@"path"];
            [_pathContents addObject:newItem];
            [_pathContents commitEditing];
        }
    }
    else { /* This is a subtract */
        //NSDictionary *dict = [_objectController content];
        //NSIndexSet *selected = [dict objectForKey:@"selectedPaths"];
        //NSArray *selectedObjs = [_pathContents selectedObjects];
        NSIndexSet *selected = [_pathContents selectionIndexes];
        [_pathContents removeObjectsAtArrangedObjectIndexes:selected];
        [_pathContents commitEditing];
    }
}

- (IBAction)pbOKAction:(id)sender {
    DuplicateOptions options = DupCompareNone;
    options |= ([_cbFileName state]) ? DupCompareName : 0;
    options |= ([_cbFileSize state]) ? DupCompareSize : 0;
    if ([_cbFileDate state]) {
        NSString *title = [[_rbGroupDates selectedCell] title];
        if ([title isEqualToString:@"Modified"])
            options |= DupCompareDateModified;
        else if ([title isEqualToString:@"Added"])
            options |= DupCompareDateAdded;
        else if ([title isEqualToString:@"Created"])
            options |= DupCompareDateCreated;
    }
    if ([_cbFileContents state]) {
        NSString *title = [[_rbGroupContents selectedCell] title];
        if ([title isEqualToString:@"MD5"])
            options |= DupCompareContentsMD5;
        else if ([title isEqualToString:@"Full"])
            options |= DupCompareContentsFull;

    }
    NSNumber *Options = [NSNumber numberWithInteger:options];
    NSMutableArray *pathList = [[NSMutableArray alloc] init];
    for (NSDictionary *objdict in [_pathContents content]) {
        [pathList addObject: [objdict objectForKey:@"path"]];
    }
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          Options, kOptionsKey,
                          pathList, kRootPathKey,
                          nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStartDuplicateFind object:nil userInfo:info];
    [self close];
}

- (IBAction)pbCancelAction:(id)sender {
    [self close];
}
@end
