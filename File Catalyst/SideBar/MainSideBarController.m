//
//  MainSideBarController.m
//  Caravelle
//
//  Created by Nuno on 01/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#include "Definitions.h"
#import "MainSideBarController.h"
#import "SidebarTableCellView.h"
#import "SideBarObject.h"
#import "RecentlyUsedArray.h"
#import "TreeManager.h"

@implementation MainSideBarController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    //NSLog(@"MainSideController.initWithNibName:bundle: Init done");
    return self;
}

- (void)awakeFromNib {
    // The array determines our order
    _topLevelItems = [NSArray arrayWithObjects:@"Favorites", @"Recently Used", @"Authorizations", @"Devices", nil];
    
    // The data is stored ina  dictionary. The objects are the nib names to load.
    _childrenDictionary = [NSMutableDictionary new];
    [self populateAuthorizations];
    //[self populateFavorites];
    [self populateRecentlyUsed];
    
    // The basic recipe for a sidebar. Note that the selectionHighlightStyle is set to NSTableViewSelectionHighlightStyleSourceList in the nib
    [_sidebarOutlineView sizeLastColumnToFit];
    [_sidebarOutlineView reloadData];
    [_sidebarOutlineView setFloatsGroupRows:NO];
    
    // NSTableViewRowSizeStyleDefault should be used, unless the user has picked an explicit size. In that case, it should be stored out and re-used.
    [_sidebarOutlineView setRowSizeStyle:NSTableViewRowSizeStyleDefault];
    
    // Expand all the root items; disable the expansion animation that normally happens
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [_sidebarOutlineView expandItem:nil expandChildren:YES];
    [NSAnimationContext endGrouping];
    
    // Set an observer to the USER Defaults
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:USER_DEF_SECURITY_BOOKMARKS
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}


- (void)_setContentViewToName:(NSString *)name {
    NSLog(@"Change view to %@", name);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([_sidebarOutlineView selectedRow] != -1) {
        NSString *item = [_sidebarOutlineView itemAtRow:[_sidebarOutlineView selectedRow]];
        if ([_sidebarOutlineView parentForItem:item] != nil) {
            // Only change things for non-root items (root items can be selected, but are ignored)
            [self _setContentViewToName:item];
        }
    }
}

- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = [_childrenDictionary allKeys];
    } else {
        children = [_childrenDictionary objectForKey:item];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [[self _childrenForItem:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([outlineView parentForItem:item] == nil) {
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item==nil)
        return [_childrenDictionary count];
    return [[self _childrenForItem:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if (item==nil)
        return NO;
    return [_topLevelItems containsObject:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    // As an example, hide the "outline disclosure button" for FAVORITES. This hides the "Show/Hide" button and disables the tracking area for that row.
    if (0) { //[item isEqualToString:@"Favorites"]) {
        return NO;
    } else {
        return YES;
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // For the groups, we just return a regular text view.
    if ([_topLevelItems containsObject:item]) {
        NSTextField *result = [outlineView makeViewWithIdentifier:@"HeaderTextField" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        NSString *value = [item uppercaseString];
        [result setStringValue:value];
        return result;
    } else  {
        // The cell is setup in IB. The textField and imageView outlets are properly setup.
        // Special attributes are automatically applied by NSTableView/NSOutlineView for the source list
        SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        if ([item isKindOfClass:[SideBarObject class]] ) {
            SideBarObject *it = item;
            result.textField.stringValue = it.title;
            result.imageView.image = it.image;
            [result.button setHidden:YES];
            return result;
        }
        else {
            // !!!!! The test code below should disappear
            result.textField.stringValue = item;
            // Setup the icon based on our section
            id parent = [outlineView parentForItem:item];
            NSInteger index = [_topLevelItems indexOfObject:parent];
            NSInteger iconOffset = index % 4;
            switch (iconOffset) {
                case 0: {
                    result.imageView.image = [NSImage imageNamed:NSImageNameIconViewTemplate];
                    break;
                }
                case 1: {
                    result.imageView.image = [NSImage imageNamed:NSImageNameHomeTemplate];
                    break;
                }
                case 2: {
                    result.imageView.image = [NSImage imageNamed:NSImageNameQuickLookTemplate];
                    break;
                }
                case 3: {
                    result.imageView.image = [NSImage imageNamed:NSImageNameSlideshowTemplate];
                    break;
                }
            }
            BOOL hideUnreadIndicator = YES;
            // Setup the unread indicator to show in some cases. Layout is done in SidebarTableCellView's viewWillDraw
            if (index == 0) {
                // First row in the index
                hideUnreadIndicator = NO;
                [result.button setTitle:@"42"];
                [result.button sizeToFit];
                // Make it appear as a normal label and not a button
                [[result.button cell] setHighlightsBy:0];
            } else if (index == 2) {
                // Example for a button
                hideUnreadIndicator = NO;
                result.button.target = self;
                result.button.action = @selector(buttonClicked:);
                [result.button setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
                // Make it appear as a button
                [[result.button cell] setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
            }
            [result.button setHidden:hideUnreadIndicator];
            return result;
        }
    }
}

- (void)buttonClicked:(id)sender {
    // Example target action for the button
    NSInteger row = [_sidebarOutlineView rowForView:sender];
    NSLog(@"row: %ld", row);
}

- (IBAction)sidebarMenuDidChange:(id)sender {
    // Allow the user to pick a sidebar style
    NSInteger rowSizeStyle = [sender tag];
    [_sidebarOutlineView setRowSizeStyle:rowSizeStyle];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    for (NSInteger i = 0; i < [menu numberOfItems]; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if (![item isSeparatorItem]) {
            // In IB, the tag was set to the appropriate rowSizeStyle. Read in that value.
            NSInteger state = ([item tag] == [_sidebarOutlineView rowSizeStyle]) ? 1 : 0;
            [item setState:state];
        }
    }
}

-(void) populateAuthorizations {
    NSArray *secBookmarks = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_SECURITY_BOOKMARKS];
    NSMutableArray *authorizedItems = [NSMutableArray arrayWithCapacity:[secBookmarks count]];
    
    // Retrieve allowed URLs
    for (NSData *bookmark in secBookmarks) {
        BOOL dataStalled;
        NSError *error;
        NSURL *allowedURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                      options:NSURLBookmarkResolutionWithSecurityScope
                                                relativeToURL:nil
                                          bookmarkDataIsStale:&dataStalled
                                                        error:&error];
        if (error==nil && dataStalled==NO) {
            SideBarObject *item = [[SideBarObject alloc] init];
            TreeItem *tItem = [appTreeManager addTreeItemWithURL:allowedURL askIfNeeded:NO];
            item.title = [tItem name];
            item.image = [tItem image];
            item.objValue = tItem;
            [authorizedItems addObject:item];
        }
    }
    if ([authorizedItems count] > 0)
        [_childrenDictionary setObject:authorizedItems forKey:@"Authorizations"];
}

-(void) populateRecentlyUsed {
    RecentlyUsedArray *registeredMRUs = recentlyUsedLocations();
    NSMutableArray *MRUItems = [NSMutableArray arrayWithCapacity:[registeredMRUs.array count]];
    
    // Retrieve allowed URLs
    for (NSString *path in registeredMRUs.array) {
        SideBarObject *item = [[SideBarObject alloc] init];
        NSURL *url = [NSURL fileURLWithPath:path];
        if (url) {
            TreeItem *tItem = [appTreeManager addTreeItemWithURL:url askIfNeeded:NO];
            if (tItem) {
                item.title = [tItem name];
                item.image = [tItem image];
                item.objValue = tItem;
                
                [MRUItems addObject:item];
            }
        }
    }
    if ([MRUItems count] > 0)
        [_childrenDictionary setObject:MRUItems forKey:@"Recently Used"];
}

-(void) populateFavorites {
    [_childrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView2", @"ContentView3", nil] forKey:@"Favorites"];
    
}

-(void) populateDevices {
    [_childrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView2", @"ContentView3", nil] forKey:@"Devices"];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:USER_DEF_SECURITY_BOOKMARKS]) {
        //NSLog(@"BrowserController.observeValueForKeyPath: %@", keyPath);
        [self populateAuthorizations];
    }
}


@end
