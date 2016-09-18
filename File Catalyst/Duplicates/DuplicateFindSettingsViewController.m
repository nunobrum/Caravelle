//
//  DuplicateFindSettingsViewController.m
//  File Catalyst
//
//  Created by Nuno Brum on 25/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "AppOperation.h"
#import "TreeManager.h"
#import "TreeCollection.h"
#import "DuplicateFindOperation.h"

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

@interface DuplicateFindSettingsViewController ()  {
    TreeCollection *CPaths;
}


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
        self->CPaths = [[TreeCollection alloc] init];
        
    }
    return self;
}

-(void) windowDidLoad {
    [super windowDidLoad];
    // Initializing Date Pickers
    [self.dpEndDateFilter setDateValue: [NSDate date]];
    [self.dpStartDateFilter setDateValue: [self.dpStartDateFilter minDate]];
    
    // Size Selector
    [self.cbMinimumFileSizeUnit selectItemAtIndex:0];
    
}

- (IBAction)addRemoveFolderButton:(id)sender {
    // Determine if + or -
    NSInteger PlusOrMinus = [(NSSegmentedControl*)sender selectedSegment];
    if (PlusOrMinus==0) {/* This is an Add */
        NSURL *rootURL = [appTreeManager powerboxOpenFolderWithTitle:@"Select a new Directory"];
        if (rootURL) {
            NSString *errorMessage = nil;
            NSString *path2Add = rootURL.path;
            for (NSDictionary *item in self.pathContents.arrangedObjects) {
                NSString *path = item[@"path"];
                enumPathCompare res = path_relation(path, path2Add);
                switch (res) {
                    case pathIsParent:
                        // Update 
                        errorMessage = [NSString stringWithFormat:@"Please, first remove the folder %@", path];
                        break;
                    case pathIsChild:
                        errorMessage = [NSString stringWithFormat:@"Folder already contained in %@",path];
                        break;
                    case pathIsSame:
                        errorMessage = [NSString stringWithFormat:@"Folder already selected"];
                        break;
                    default:
                        break;
                }
            }
            if (errorMessage) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Can't add the indicated folder"];
                [alert setAlertStyle:NSInformationalAlertStyle];
                [alert setInformativeText:errorMessage];
                [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                    //TODO:1.4 complete with the list of options:
                    // If parent: Replace the parent
                }];
            }
            else {
                NSDictionary *newItem = [NSDictionary dictionaryWithObject:path2Add forKey:@"path"];
                [self.pathContents addObject:newItem];
                [self.pathContents commitEditing];
            }
        }
    }
    else { /* This is a subtract */
        //NSDictionary *dict = [_objectController content];
        //NSIndexSet *selected = [dict objectForKey:@"selectedPaths"];
        //NSArray *selectedObjs = [self.pathContents selectedObjects];
        NSIndexSet *selected = [self.pathContents selectionIndexes];
        [self.pathContents removeObjectsAtArrangedObjectIndexes:selected];
        [self.pathContents commitEditing];
    }
}

- (IBAction)pbOKAction:(id)sender {
    EnumDuplicateOptions options = DupCompareNone;
    options |= ([_cbFileName state]) ? DupCompareName : 0;
    options |= ([_cbFileSize state]) ? DupCompareSize : 0;
    if ([_cbFileDate state]) {
        NSString *title = [[_rbGroupDates selectedCell] title];
        if ([title isEqualToString:@"Modified"])
            options |= DupCompareDateModified;
        else if ([title isEqualToString:@"Accessed"])
            options |= DupCompareDateAccessed;
        else if ([title isEqualToString:@"Created"])
            options |= DupCompareDateCreated;
    }
    if ([_cbFileContents state]) {
        options |= DupCompareSize; // If it compares the content, its faster if the size is also compared.
        NSString *title = [[_rbGroupContents selectedCell] title];
        if ([title isEqualToString:@"MD5"])
            options |= DupCompareContentsMD5;
        else if ([title isEqualToString:@"Full"])
            options |= DupCompareContentsFull;

    }
    NSNumber *Options = [NSNumber numberWithInteger:options];
    NSString *filenameFilter = [self.ebFilenameFilter stringValue];
    NSInteger fileSizeFilter = [self.ebMinimumFileSize integerValue];
    NSInteger pow1000 = [self.cbMinimumFileSizeUnit indexOfSelectedItem];
    for (int i=0; i < pow1000; i++) {
        fileSizeFilter *= 1000;
    }
    NSDate * startDateFilter = [self.dpStartDateFilter dateValue];
    NSDate * endDateFilter   = [self.dpEndDateFilter  dateValue];
    
    NSMutableArray *pathList = [[NSMutableArray alloc] init];
    for (NSDictionary *objdict in [self.pathContents content]) {
        [pathList addObject: [objdict objectForKey:@"path"]];
    }
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          Options, kOptionsKey,
                          pathList, kRootPathKey,
                          opDuplicateFind, kDFOOperationKey,
                          filenameFilter, kFilenameFilter,
                          [NSNumber numberWithInteger:fileSizeFilter], kMinSizeFilter,
                          startDateFilter, kStartDateFilter,
                          endDateFilter, kEndDateFilter,
                          nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStartDuplicateFind object:nil userInfo:info];
    [self close];
}

- (IBAction)pbCancelAction:(id)sender {
    // Sends an empty dictionary to cancel the operation
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationStartDuplicateFind object:nil userInfo:nil];
    [self close];
}

-(void) setPaths:(NSArray *)paths {
    // Remove All objects
    [self.pathContents removeObjects: [self.pathContents arrangedObjects]];
    for (NSString* path in paths) {
        NSDictionary *newItem = [NSDictionary dictionaryWithObject:path forKey:@"path"];
        [self.pathContents addObject:newItem];
    }
    [self.pathContents commitEditing];
}
@end
