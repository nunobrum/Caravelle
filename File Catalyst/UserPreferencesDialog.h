//
//  UserPreferencesDialog.h
//  File Catalyst
//
//  Created by Nuno Brum on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UserPreferencesDialog : NSWindowController <NSOutlineViewDelegate> {
}
@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSView *placeholderView;
@property (strong) IBOutlet NSView *authorizedURLsView;
@property (strong) IBOutlet NSView *behaviourView;
@property (strong) IBOutlet NSView *browserOptionsView;

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

//
// Authorizations view
//
@property (strong) IBOutlet NSTableView *tableAuthorizations;

- (IBAction)revokeRequest:(id)sender;

@end
