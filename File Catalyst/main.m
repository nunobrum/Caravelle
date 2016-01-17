//
//  main.m
//  File Catalyst
//
//  Created by Nuno Brum on 11/04/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Receipts.h"
#import "Definitions.h"

int main(int argc, const char * argv[])
{
#if (APP_IS_SANDBOXED==1)
    int res = validateAppReceipt();
    if (res!=0) {
        return res;
    }
#endif
    return NSApplicationMain(argc, argv);
}
