//
//  main.m
//  File Catalyst
//
//  Created by Nuno Brum on 11/04/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Receipts.h"

int main(int argc, const char * argv[])
{
    int res = validateAppReceipt();
    if (res!=0) {
        return res;
    }
    return NSApplicationMain(argc, argv);
}
