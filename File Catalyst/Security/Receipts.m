//
//  Receipts.m
//  Caravelle
//
//  Created by Nuno on 28/08/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include "./openssl/include/openssl/bio.h"


NSInteger validateAppReceipt () {
    
    // Locate the receipt
    NSURL *receiptURL;
    @try {
        receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    }
    @catch (NSException *exception) {
        receiptURL = [[NSBundle mainBundle] URLForResource:@"receipt" withExtension:@"" subdirectory:@"/Contents/_MASReceipt"];
    }
    @finally {
        
    }
    
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    if (!receipt) {
        /* No local receipt -- handle the error. */
        return 173;
    }
    
    /* The PKCS #7 container (the receipt) and the output of the verification. */
    //BIO *b_p7;
    //PKCS7 *p7;
    
    // Check the LSMinimumSystemVersion :
    // See: xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#
    
    // Verify if Signed by Apple
    
    // If it fails the local signature, a check with the apple store can be attempted
    //See:xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#
    
    // Verify that the bundle identifier matches
    
    // Verify that the Version matches : Use the CFBundleShortVersionString of the InfoPlist.strings :
    // See : xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#
    
    // Compute the GUID
    
    // Return Success
    return 0;
}
