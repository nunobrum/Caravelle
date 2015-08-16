//
//  UserPreferencesDialog.m
//  File Catalyst
//
//  Created by Nuno Brum on 27/12/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "UserPreferencesManager.h"
#import "Definitions.h"
#include "getGUID.h"


typedef NS_OPTIONS(NSUInteger, EnumAppIns) {
    AppInsNotRead         = 0,
    AppInsValidated       = 1 << 0,
    AppInDuplicateManager = 1 << 1

};

@interface UserPreferencesManager () {
    EnumAppIns authorizedAppIns;
}
@property (strong) IBOutlet NSTreeController *prefsTree;


@end


@implementation UserPreferencesManager {

}


- (instancetype)initWithWindowNibName:(NSString*)window {
    self = [super initWithWindowNibName:window];
    // inialization here
    self->_requestPending = @0;
    self->_products = nil;
    self->authorizedAppIns = AppInsNotRead;
    
    // Try to get products from UserDefaults
    
    
    return self;
}


#pragma mark - InApp Handling

-(NSArray*) productIdentifiers {
    static NSArray *productIdentifiers =  nil;
    
    if (productIdentifiers == nil) {
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"payplugins"
                                             withExtension:@"plist"];
        productIdentifiers = [NSArray arrayWithContentsOfURL:url];
    }
    return productIdentifiers;
}


// Search for a product information
-(NSDictionary*) infoForProduct:(NSString*)ID {
    for (NSDictionary *article in self.productIdentifiers) {
        NSString *articleID = [article objectForKey:@"id"];
        if ([articleID isEqualToString:ID]) {
            return article;
        }
    }
    return nil;
}

-(SKProduct*) productWithID:(NSString*)ID {
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:ID]) {
            return product;
        }
    }
    return nil;
}

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    if ([self.requestPending boolValue]==NO) {
        self.requestPending = @1;
        
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                              initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}


// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    
    self->_products = response.products;
    [self populateArrayControllerWithProducts];
    
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        // Handle any invalid product identifiers.
        NSLog(@"AppStoreManager.productRequest:didReceiveResponse: The product %@ is invalid", invalidIdentifier);
    }
    self.requestPending = @0;
    
    // Store received products on user defaults
//    [[NSUserDefaults standardUserDefaults] setObject:response.products forKey:USER_DEF_APPIN_PRODUCTS];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void) checkoutProductID:(NSString*)productID {
    SKProduct *product = [self productWithID:productID];
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    self->authorizedAppIns = AppInsNotRead; // Need to later update the authorizedAppIns
}

-(void) restoreAcquiredAppIns {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    self->authorizedAppIns = AppInsNotRead; // Need to later update the authorizedAppIns
}

#pragma mark - PaymentTransactionObserver Protocol

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *newStatus;
        switch (transaction.transactionState) {
                // Call the appropriate custom method for the transaction state.
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"PaymentTransactionObserver: Purchasing...%@",transaction.payment.productIdentifier);
                newStatus = @"Purchasing";
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"PaymentTransactionObserver: Deferred...%@",transaction.payment.productIdentifier);
                newStatus = @"Deferred";
                //[self showTransactionAsInProgress:transaction deferred:YES];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"PaymentTransactionObserver: Failed !!!%@",transaction.payment.productIdentifier);
                newStatus = @"Failed";
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"PaymentTransactionObserver: Complete.%@",transaction.payment.productIdentifier);
                @try {
                    [self storeTransaction:transaction];
                    newStatus = @"Active";
                }
                @catch (NSException *exception) {
                    NSLog(@"Unable to store the transaction");
                    newStatus = @"Failed";
                }
                @finally {
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                //[self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"PaymentTransactionObserver: Restored...%@",transaction.payment.productIdentifier);
                @try {
                    [self storeTransaction:transaction.originalTransaction];
                    newStatus = @"Restored";
                }
                @catch (NSException *exception) {
                    NSLog(@"Unable to store the transaction");
                    newStatus = @"Failed";
                }
                @finally {
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                //[self restoreTransaction:transaction];
                break;
            default:
                // For debugging
                NSLog(@"PaymentTransactionObserver: Unexpected transaction state %@", @(transaction.transactionState));
                newStatus = @"Unexpected";
                break;
        }
        [self updateStatus:newStatus onProduct:transaction.payment.productIdentifier];
    }
}

//- (void) paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
//    // called when transactions are removed from the queue
//}
//
//- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
//    // called when transaction completed successfully
//}
//
//- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
//    // When there are errors on the transaction
//}

// Validating receipts Locally
- (void) storeTransaction:(SKPaymentTransaction*) transaction {
    
#ifdef USE_APP_RECEIPT
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    // Custom method to work with receipts
    BOOL rocketCarEnabled = [self receipt:receiptData
                        includesProductID:@"com.example.rocketCar"];
    // See Receipt Validation Programming Guide.
    // https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Introduction.html#//apple_ref/doc/uid/TP40010573
#else
#ifdef USE_ICLOUD_STORAGE
    NSUbiquitousKeyValueStore *storage = [NSUbiquitousKeyValueStore defaultStore];
#else
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
#endif
    

    NSArray *newReceipt = [NSArray arrayWithObjects:
                           transaction.payment.productIdentifier, // First Element
                           transaction.transactionIdentifier,     // Second Element
                           transaction.transactionDate,
                           // TODO:!!!!!! XOR with GUID, the transaction Identifier
                           nil];
    
    NSArray *savedReceipts = [storage arrayForKey:USER_DEF_APPIN_PRODUCTS];
    if (!savedReceipts) {
        // Storing the first receipt
        [storage setObject:@[newReceipt] forKey:USER_DEF_APPIN_PRODUCTS];
    } else {
        // Adding another receipt
        NSArray *updatedReceipts = [savedReceipts arrayByAddingObject:newReceipt];
        [storage setObject:updatedReceipts forKey:USER_DEF_APPIN_PRODUCTS];
    }
    
    [storage synchronize];
#endif
    
    // Finishing the transaction
    //[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(BOOL) validateAppIn:(NSString*)ID {
#ifdef USE_ICLOUD_STORAGE
    NSUbiquitousKeyValueStore *storage = [NSUbiquitousKeyValueStore defaultStore];
#else
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
#endif
    NSArray *savedReceipts = [storage arrayForKey:USER_DEF_APPIN_PRODUCTS];
    if (savedReceipts) {
        for (NSArray *transactionRecord in savedReceipts) {
            // TODO:!!!! XOR with GUID
            if ([ID isEqualToString: [transactionRecord firstObject]]) {
                return YES;
            }
        }
    }
    return NO;
}

-(void) validateAppIns {
    self->authorizedAppIns = AppInsNotRead;
#ifdef USE_ICLOUD_STORAGE
    NSUbiquitousKeyValueStore *storage = [NSUbiquitousKeyValueStore defaultStore];
#else
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
#endif
    NSArray *savedReceipts = [storage arrayForKey:USER_DEF_APPIN_PRODUCTS];
    if (savedReceipts) {
        for (NSArray *transactionRecord in savedReceipts) {
            // TODO:!!!! XOR with GUID
            if ([[transactionRecord firstObject] isEqualToString:@"com.cascode.duplicates"]) {
                authorizedAppIns |= AppInDuplicateManager;
            }
        }
    }
    self->authorizedAppIns |= AppInsValidated; // Signals that the authorized AddIns were read
}

// This function will make all the diligences to request an update of the pluginInformation
-(void) updateItemList {
    
    NSArray *prodIDs = [self.productIdentifiers valueForKeyPath:@"@unionOfObjects.id"];
    [self validateProductIdentifiers:prodIDs];
}

-(void) populateArrayControllerWithProducts {
    
    if (self.products) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        // Start with a clean Array
        [self.pluginInformationController removeObjects: [self.pluginInformationController arrangedObjects]];
        
        
        for (SKProduct *article in self->_products) {
            // Handle valid product identifiers.
            NSLog(@"AppStoreManager.productRequest:didReceiveResponse: The product %@ is valid", article.productIdentifier);
            NSDictionary * pluginInfo = [self infoForProduct:article.productIdentifier];
            NSImage *icon = [NSImage imageNamed:[pluginInfo objectForKey:@"icon"]];
            
            NSString *statusInfo;
            NSNumber *active;
            if ([self validateAppIn:article.productIdentifier]) {
                statusInfo = @"Active";
                active = @1; // A
            }
            else {
                // Formatting the price accordint to locale
                [numberFormatter setLocale:article.priceLocale];
                statusInfo = [numberFormatter stringFromNumber:article.price];
                active = @0;
            }
            // Adding the complementary information
            //NSMutableDictionary *infoWithStoreInfo = [NSMutableDictionary dictionaryWithDictionary:pluginInfo];
            NSMutableDictionary *storeInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       article.productIdentifier, @"id",
                                       article.localizedTitle, @"title",
                                       statusInfo, @"status",
                                       icon, @"icon",
                                       article.localizedDescription, @"description",
                                       active, @"active",
                                       nil];
            //[infoWithStoreInfo addEntriesFromDictionary:storeInfo];
            [self.pluginInformationController addObject:storeInfo];
        }
        [self.pluginInformationController commitEditing];
    }
}

-(void) updateStatus:(NSString*) newStatus onProduct:(NSString*) productIdentifier {
    NSArray *articles = [self.pluginInformationController arrangedObjects];
    for (id article in articles) {
        if ([[article objectForKey:@"id"] isEqualToString:productIdentifier]) {
            [article setObject:newStatus forKey:@"status"];
        }
    }
    [self.pluginInformationController commitEditing];
}

#pragma mark - Window Management

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

    [self.prefsTree addObject: [NSDictionary  dictionaryWithObjectsAndKeys:
                                @"Browser Options", @"description",
                                self.browserOptionsView, @"view",
                                isLeaf, @"leaf",
                                nil] ] ;
    
    [self.prefsTree addObject: [NSDictionary  dictionaryWithObjectsAndKeys:
                                @"App-Ins", @"description",
                                self.paymentsView, @"view",
                                isLeaf, @"leaf",
                                nil] ] ;
    
    [self.prefsTree commitEditing];

    [self.prefsTree setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
    // Corresponding to index 0
    
    // TODO:!!!!! Get the information from User Defaults :USER_DEF_APPIN_PRODUCTS;
    // Get the App-In information from App Store
    [self updateItemList];
    
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


- (IBAction)buyAppIn:(id)sender {
    NSDictionary *article = [[self.pluginInformationController selectedObjects] firstObject];
    NSString *productID = [article objectForKey:@"id"];
    [self checkoutProductID:productID];
}

- (IBAction)restoreProducts:(id)sender {
    [self restoreAcquiredAppIns];
}

-(BOOL) duplicatesAuthorized {
    if ((self->authorizedAppIns & AppInsValidated) == 0) {
        [self validateAppIns];
    }
    return (self->authorizedAppIns & AppInDuplicateManager) != 0;
}

@end
