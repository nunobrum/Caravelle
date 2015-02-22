//
//  UserPreferencesDialog.m
//  File Catalyst
//
//  Created by Nuno Brum on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "UserPreferencesDialog.h"

@interface UserPreferencesDialog ()

@end

@implementation UserPreferencesDialog

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    BaseDirectoriesArray = [NSArray arrayWithObjects:@"Browser Preferences", nil];
}

#pragma mark - Tree Outline DataSource Protocol

/*
 * Tree Outline View Data Source Protocol
 */


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if(item==nil) {
        return [BaseDirectoriesArray count];
    }
    else {
        // Returns the total number of leafs
        if ([item respondsToSelector:@selector(count)]) {
            return [item count];
        }
        else {
            return 0;
        }
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    id ret=nil;
    if (item==nil)
        ret = [BaseDirectoriesArray objectAtIndex:index];
    else {
        if ([item respondsToSelector:@selector(objectAtIndex:)]) {
            ret = [item objectAtIndex:index];
        }
    }
    return ret;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL answer=NO;
    if ([item respondsToSelector:@selector(count)]) {
        answer = [item count]>1;
    }
    return answer;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView=nil;
    //cellView= [outlineView makeViewWithIdentifier:@"CatalystView" owner:self
    cellView= [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    [[cellView textField] setStringValue:item ];
    return cellView;
}

//- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//
//}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSLog(@"UserPreferencesDialog.outlineView:setObjectValue:forTableColumn:byItem - Not implemented");
    NSLog(@"setObjectValue Object Class %@ Table Column %@ Item %@",[(NSObject*)object class], tableColumn.identifier, [item name]);
}

#pragma mark - Tree Outline View Delegate Protocol


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    CGFloat answer;
    answer = [outlineView rowHeight];
    return answer;
}

//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//}


//- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
//}

/*
 * Tree Outline View Data Delegate Protocol
 */


/* Called before the outline is selected.
 Can be used later to block access to private directories */
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
//}

//- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
//    if ([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ])  {
//    }
//}



@end
