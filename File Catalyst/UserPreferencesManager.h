//
//  UserPreferencesDialog.h
//  File Catalyst
//
//  Created by Nuno Brum on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppStoreManager.h"

extern NSString *userPrefsPanelBehaviour;
extern NSString *userPrefsPanelAuthorizations;
extern NSString *userPrefsPanelBrowserOptions;
extern NSString *userPrefsPanelAppIns;

@interface UserPreferencesManager : NSWindowController <NSOutlineViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver> {
}
@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSView *placeholderView;
@property (strong) IBOutlet NSView *authorizedURLsView;
@property (strong) IBOutlet NSView *behaviourView;
@property (strong) IBOutlet NSView *browserOptionsView;
@property (strong) IBOutlet NSView *paymentsView;
@property (strong) IBOutlet NSArrayController *pluginInformationController;



- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

//
// Authorizations view
//
@property (strong) IBOutlet NSTableView *tableAuthorizations;


@property (strong) NSNumber *requestPending;
@property (readonly) NSArray *products;
@property (strong) NSArray *activeAppIns;

- (instancetype)initWithWindowNibName:(NSString*)window;

- (IBAction)revokeRequest:(id)sender;
- (IBAction)buyAppIn:(id)sender;
- (IBAction)restoreProducts:(id)sender;

-(void) selectPanel:(NSString*) panelID;
-(BOOL) duplicatesAuthorized;
-(NSArray*) productIdentifiers;


@end

extern UserPreferencesManager *userPreferenceManager;
