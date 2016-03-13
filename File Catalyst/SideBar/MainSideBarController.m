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
    _topLevelItems = [[NSMutableArray alloc] init ];
    
    
    // The data is stored ina  dictionary. The objects are the nib names to load.
    [self populateAuthorizations];
    [self populateFavorites];
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
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:USER_DEF_FAVORITES
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([_sidebarOutlineView selectedRow] != -1) {
        SideBarObject *item = [_sidebarOutlineView itemAtRow:[_sidebarOutlineView selectedRow]];
        if ([_sidebarOutlineView parentForItem:item] != nil) {
            // Only change things for non-root items (root items can be selected, but are ignored)
            if ([[(SideBarObject*)item objValue] isKindOfClass:[TreeItem class]]) {
                TreeItem *tItem = (TreeItem*)[(SideBarObject*)item objValue];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSArray arrayWithObject:tItem], kDFOFilesKey,
                                      opOpenOperation, kDFOOperationKey,
                                      self, kDFOFromViewKey,
                                      nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
            }
        }
        else {
            NSLog(@"Change view to %@", item);
            
        }
    }
}

- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = _topLevelItems;
    } else {
        children = [item children];
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
        return [_topLevelItems count];
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
    SideBarObject *itObj = item;
    if ([_topLevelItems containsObject:itObj]) {
        NSTextField *result = [outlineView makeViewWithIdentifier:@"HeaderTextField" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        NSString *value = [itObj.title uppercaseString];
        [result setStringValue:value];
        return result;
    } else  {
        // The cell is setup in IB. The textField and imageView outlets are properly setup.
        // Special attributes are automatically applied by NSTableView/NSOutlineView for the source list
        SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];

        result.textField.stringValue = itObj.title;
        result.imageView.image = itObj.image;
        result.objectValue = itObj.objValue;
        if ([itObj.objValue isKindOfClass: [TreeItem class]]) {
            [result setToolTip: [(TreeItem*)itObj.objValue path]];
            result.button.target = self;
            result.button.action = @selector(buttonClicked:);
            [result.button setImage:[NSImage imageNamed:@"StopButton"]];
            //[[result.button cell] setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
            [result.button setBezelStyle:NSInlineBezelStyle];
            [result.button sizeToFit];
        }
        [result.button setHidden:YES];
        return result;
        
    }
}

- (void)buttonClicked:(id)sender {
    // Example target action for the button
    NSInteger row = [_sidebarOutlineView rowForView:sender];
    if (row != -1) {
        SideBarObject *item = [_sidebarOutlineView itemAtRow:row];
        SideBarObject * parent = [_sidebarOutlineView parentForItem:item];
        if (parent != nil) {
            // Only change things for non-root items (root items can be selected, but are ignored)
            if ([parent.objValue isEqualTo:SIDE_GROUP_FAVORITES]) {
                //NSLog(@"MainSideBarController.buttonClicked: Deleteing Favorite");
                [self deleteFavorite:item];
            }
            else if ([parent.objValue isEqualTo:SIDE_GROUP_RECENT_USED]) {
                //NSLog(@"MainSideBarController.buttonClicked: Deleting Recently Used");
                [self deleteRecentlyUsed:item];
            }
            else if ([parent.objValue isEqualTo:SIDE_GROUP_AUTHORIZATIONS]) {
                //NSLog(@"MainSideBarController.buttonClicked:  Deleting Authorizations");
                [self deleteAuthorization:item];
            }
        }
        else {
            NSLog(@"Change view to %@", item);
        }
    }
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
    if ([authorizedItems count] > 0) {
        SideBarObject *authorizations = [[SideBarObject alloc] init];
        authorizations.title = @"Authorizations";
        authorizations.children = authorizedItems;
        authorizations.objValue = SIDE_GROUP_AUTHORIZATIONS;
        [_topLevelItems addObject:authorizations];
    }
}

-(void) deleteAuthorization:(SideBarObject*) item {
    NSString *path = [(TreeItem*)item.objValue path];
    [appTreeManager removeAuthorization:path];
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
    if ([MRUItems count] > 0) {
        SideBarObject *recentlyUsed = [[SideBarObject alloc] init];
        recentlyUsed.title = @"Recently Used";
        recentlyUsed.objValue = SIDE_GROUP_RECENT_USED;
        recentlyUsed.children = MRUItems;
        [_topLevelItems addObject:recentlyUsed];
    }

}

-(void) deleteRecentlyUsed:(SideBarObject*)item {
    // TODO:!!!!!!!!!!
}

-(void) populateFavorites {
    NSArray *favPaths = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_FAVORITES];
    
    if (favPaths!=nil) {
        NSMutableArray *favorites = [NSMutableArray arrayWithCapacity:[favPaths count]];
        
        for (NSString *path in favPaths) {
            SideBarObject *item = [[SideBarObject alloc] init];
            NSURL *url = [NSURL fileURLWithPath:path];
            if (url) {
                TreeItem *tItem = [appTreeManager addTreeItemWithURL:url askIfNeeded:NO];
                if (tItem) {
                    item.title = [tItem name];
                    item.image = [tItem image];
                    item.objValue = tItem;
                    
                    [favorites addObject:item];
                }
            }
        }
        if ([favorites count] > 0) {
            SideBarObject *favItem = [[SideBarObject alloc] init];
            favItem.title = @"Favorites";
            favItem.objValue = SIDE_GROUP_FAVORITES;
            favItem.children = favorites;
            [_topLevelItems addObject:favItem];
        }
    }
}

-(void) deleteFavorite:(SideBarObject*) item {
    NSString *path = [(TreeItem*)item.objValue path];
    NSArray *favPaths = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_FAVORITES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF != %@", path];
    NSArray *newPaths = [favPaths filteredArrayUsingPredicate: predicate];
    [[NSUserDefaults standardUserDefaults] setObject:newPaths forKey:USER_DEF_FAVORITES];
}

//-(void) populateDevices {
//    [_childrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView2", @"ContentView3", nil] forKey:@"Devices"];
//    
//}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:USER_DEF_SECURITY_BOOKMARKS]) {
        //NSLog(@"BrowserController.observeValueForKeyPath: %@", keyPath);
        [self populateAuthorizations];
    }
    else if ([keyPath isEqualToString:USER_DEF_FAVORITES]) {
        [self populateFavorites];
    }
    [_sidebarOutlineView reloadData];
}


@end
