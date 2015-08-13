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

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    productsRequest.delegate = self;
    [productsRequest start];
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    // Start with a clean Array
    [self.pluginInformationController removeObjects: [self.pluginInformationController arrangedObjects]];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    for (SKProduct *article in response.products) {
        // Handle valid product identifiers.
        NSLog(@"AppStoreManager.productRequest:didReceiveResponse: The product %@ is valid", article.productIdentifier);
        //NSDictionary * pluginInfo = [self infoForProduct:article.productIdentifier];
        
        // Formatting the price accordint to locale
        [numberFormatter setLocale:article.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:article.price];
        
        // Adding the complementary information
        //NSMutableDictionary *infoWithStoreInfo = [NSMutableDictionary dictionaryWithDictionary:pluginInfo];
        NSDictionary *storeInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   article.localizedTitle, @"title",
                                   formattedPrice, @"price",
                                   @"duplicatesIcon", @"lock",
                                   @"duplicatesIcon", @"icon",
                                   article.localizedDescription, @"description",
                                   nil];
        //[infoWithStoreInfo addEntriesFromDictionary:storeInfo];
        [self.pluginInformationController addObject:storeInfo];
    }
    [self.pluginInformationController commitEditing];
    
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        // Handle any invalid product identifiers.
        NSLog(@"AppStoreManager.productRequest:didReceiveResponse: The product %@ is invalid", invalidIdentifier);
    }
    
    //[self displayStoreUI]; // Custom method
}


// This function will make all the diligences to request an update of the pluginInformation
-(void) updateItemList {
    NSArray *prodIDs = [self.productIdentifiers valueForKeyPath:@"@unionOfObjects.id"];
    [self validateProductIdentifiers:prodIDs];
}


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
                                @"Plugins", @"description",
                                self.paymentsView, @"view",
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

- (IBAction)buyAppIn:(id)sender {
    [self updateItemList];
}


@end
