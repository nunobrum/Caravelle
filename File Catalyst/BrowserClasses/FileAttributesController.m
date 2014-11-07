//
//  FileAttributesController.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 01/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileAttributesController.h"

@interface FileAttributesController ()

@end

@implementation FileAttributesController

//- (void)viewDidLoad {
//    [super viewDidLoad];
    // Do view setup here.
//}


+ (FileAttributesController *)sharedFileAttributeController {
    static FileAttributesController *gSharedColorTableController = nil;
    if (gSharedColorTableController == nil) {
        gSharedColorTableController = [[[self class] alloc] initWithNibName:@"FileAttributeController" bundle:[NSBundle bundleForClass:[self class]]];
    }
    return gSharedColorTableController;
}

@synthesize delegate = _delegate;
@dynamic selectedAttributes;

//- (void)dealloc {
//    [_colorList release];
//    [_colorNames release];
//    [_popover release];
//    [super dealloc];
//}

- (void)loadView {
    [super loadView];
    _attributeNames = [NSArray arrayWithContentsOfFile:@"Columns"];
    //[_tableColorList setIntercellSpacing:NSMakeSize(3, 3)];
    [_tableAttributeList setTarget:self];
    [_tableAttributeList setAction:@selector(_tableViewAction:)];
}


- (NSArray *)selectedAttributes {
    if ([_tableAttributeList selectedRow] != -1) {
        return [_attributeNames objectsAtIndexes:[_tableAttributeList selectedRowIndexes]];
    } else {
        return nil;
    }
}

- (void)_selectAttributes:(NSArray *)attrNames {
    // Search for that color in our list
    for (NSString* attrName in attrNames) {
        NSInteger row = 0;
        for (NSString *name in _attributeNames) {
            if ([name isEqualToString:attrName]) {
                break;
            }
            row++;
        }
        _updatingSelection = YES;
        // This is done in an animated fashion
        if (row != -1) {
            [_tableAttributeList scrollRowToVisible:row];
            [[_tableAttributeList animator] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
        } else {
            [_tableAttributeList scrollRowToVisible:0];
            [[_tableAttributeList animator] selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:YES];
        }
        _updatingSelection = NO;
    }
}

- (void)_makePopoverIfNeeded {
    if (_popover == nil) {
        // Create and setup our window
        _popover = [[NSPopover alloc] init];
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        _popover.contentViewController = self;
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.delegate = self;
    }
}

//- (void)selectAttribute:(NSString *)attrName withPositioningView:(NSView *)positioningView {
- (void)selectAttribute:(NSArray *)selectedAttributes withPositioningView:(NSView *)positioningView {
    [self _makePopoverIfNeeded];
    [self _selectAttributes:selectedAttributes];
    [_popover showRelativeToRect:[positioningView bounds] ofView:positioningView preferredEdge:NSMinYEdge];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _attributeNames.count;
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *name = [_attributeNames objectAtIndex:row];
    // In IB, the TableColumn's identifier is set to "Automatic". The NSTableCellView's is also set to "Automatic". IB then keeps the two in sync, and we don't have to worry about setting the identifier.
    NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
    result.textField.stringValue = name;
    return result;
}

- (void)_tableViewAction:(id)sender {
    [_popover close];
    if ([self.delegate respondsToSelector:@selector(attribTableController:didChooseAttributes:)]) {
        [self.delegate attribTableController:self didChooseAttributes:self.selectedAttributes ];

    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    // Free the popover to avoid a cycle. We could also just break the contentViewController property, and reset it when we show the popover
    //[_popover release];
    _popover = nil;
}

@end
