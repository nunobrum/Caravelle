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
#include "openssl/include/openssl/pkcs7.h"

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
    BIO *b_p7;
    PKCS7 *p7;
    
    /* The Apple root certificate, as raw data and in its OpenSSL representation. */
    BIO *b_x509;
    X509 *Apple;
    
    /* The root certificate for chain-of-trust verification. */
    X509_STORE *store = X509_STORE_new();
    
    /* ... Initialize both BIO variables using BIO_new_mem_buf() with a buffer and its size ... */
    const int bufsize = 4096;
    void *buf =malloc(bufsize * sizeof(char));
    b_p7 = BIO_new_mem_buf(buf, bufsize);
    
    /* Initialize b_out as an output BIO to hold the receipt payload extracted during signature verification. */
    BIO *b_out = BIO_new(BIO_s_mem());
    
    /* Capture the content of the receipt file and populate the p7 variable with the PKCS #7 container. */
    p7 = d2i_PKCS7_bio(b_p7, NULL);
    
    /* ... Load the Apple root certificate into b_X509 ... */
    
    /* Initialize b_x509 as an input BIO with a value of the Apple root certificate and load it into X509 data structure. Then add the Apple root certificate to the structure. */
    Apple = d2i_X509_bio(b_x509, NULL);
    X509_STORE_add_cert(store, Apple);
    
    /* Verify the signature. If the verification is correct, b_out will contain the PKCS #7 payload and rc will be 1. */
    int rc = PKCS7_verify(p7, NULL, store, NULL, b_out, 0);
    
    /* For additional security, you may verify the fingerprint of the root certificate and verify the OIDs of the intermediate certificate and signing certificate. The OID in the certificate policies extension of the intermediate certificate is (1 2 840 113635 100 5 6 1), and the marker OID of the signing certificate is (1 2 840 113635 100 6 11 1). */
    
    // Check the LSMinimumSystemVersion :
    // See: xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#
    
    // Verify if Signed by Apple
    
    // If it fails the local signature, a check with the apple store can be attempted
    //See:xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html#
    
    // Verify that the bundle identifier matches
    
    // Verify that the Version matches : Use the CFBundleShortVersionString of the InfoPlist.strings :
    // See : xcdoc://?url=developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#
    
    // Compute the GUID
    
    // Cleanout Allocations
    
    BIO_free(b_out);
    BIO_free(b_p7);
    free(buf);
    
    // Return Success
    return 0;
}
