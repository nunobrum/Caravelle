//
//  UserPreferencesDialog.m
//  File Catalyst
//
//  Created by Nuno Brum on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "UserPreferencesDialog.h"
#import "Definitions.h"


@interface UserPreferencesDialog ()
@property (strong) IBOutlet NSTreeController *prefsTree;

@end

@implementation UserPreferencesDialog

- (void)windowDidLoad {
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSNumber *isLeaf = [NSNumber numberWithBool:YES];
    //NSNumber *isNode = [NSNumber numberWithBool:NO];

    // our model will consist of a dictionary with Name/Image key pairs
    [self.prefsTree addObject: [NSDictionary  dictionaryWithObjectsAndKeys:
                                @"Behaviour", @"description",
                                self.behaviourView, @"view",
                                isLeaf, @"leaf",
                                nil] ] ;
    [self.prefsTree addObject: [NSDictionary  dictionaryWithObjectsAndKeys:
                                @"Authorizations", @"description",
                                self.authorizedURLsView, @"view",
                                isLeaf, @"leaf",
                                nil] ] ;


    [self.prefsTree commitEditing];

    [self.prefsTree setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
    // Corresponding to index 0
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([[notification name] isEqual:NSOutlineViewSelectionDidChangeNotification ])  {
        NSDictionary *item = [[self.prefsTree selectedObjects] firstObject];
        NSView *viewtoset = [item objectForKey:@"view"];

        [self.placeholderView setSubviews:[NSArray arrayWithObject:viewtoset]];
        [self.placeholderView setNeedsDisplay:YES];

    }
}

- (IBAction)revokeRequest:(id)sender {
    NSInteger row = [self.tableAuthorizations selectedRow];
    NSArray *secBookmarks = [[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_SECURITY_BOOKMARKS];
    NSMutableArray *updatedBookmarks = [NSMutableArray arrayWithArray:secBookmarks];
    [updatedBookmarks removeObjectAtIndex:row];
    [[NSUserDefaults standardUserDefaults] setObject:updatedBookmarks forKey:USER_DEF_SECURITY_BOOKMARKS];

}


@end
