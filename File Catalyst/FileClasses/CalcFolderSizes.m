//
//  CalcFolderSizes.m
//  Caravelle
//
//  Created by Nuno on 19/07/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "CalcFolderSizes.h"
#import "TreeBranch_TreeBranchPrivate.h"

@implementation CalcFolderSizes

-(void) main {
    long long files = 0;
    long long allocated = 0;
    long long total = 0;
    long long totalallocated = 0;
    
    if (![self isCancelled]) {
        NSLog(@"Start Calculation on %@", self.item.url);
        NSFileManager *localFileManager = [NSFileManager defaultManager];
        NSArray *fieldsToGet = [NSArray arrayWithObjects:NSURLFileSizeKey,
                                NSURLFileAllocatedSizeKey,
                                NSURLTotalFileSizeKey,
                                NSURLTotalFileAllocatedSizeKey,
                                NSURLIsRegularFileKey, nil];
        NSDirectoryEnumerator *treeEnum = [localFileManager enumeratorAtURL:self.item.url
                                                 includingPropertiesForKeys:fieldsToGet
                                                                    options:0
                                                               errorHandler:nil];
        for (NSURL *theURL in treeEnum) {
            NSError *error;
            NSDictionary *fields = [theURL resourceValuesForKeys:fieldsToGet error:&error];
            if ([fields[NSURLIsRegularFileKey] boolValue]) {
                files          += [fields[NSURLFileSizeKey              ] longLongValue];
                allocated      += [fields[NSURLFileAllocatedSizeKey     ] longLongValue];
                total          += [fields[NSURLTotalFileSizeKey         ] longLongValue];
                totalallocated += [fields[NSURLTotalFileAllocatedSizeKey] longLongValue];
                
            }
            if ([self isCancelled]) {
                break;
            }
        }
    }
    else {
        NSLog(@"Canceled Start Calculation on %@", self.item.url);
    }
    if (self.isCancelled) {
        [self.item sizeCalculationCancelled];
        NSLog(@"Canceled Calculation on %@", self.item.url);
    }
    else {
        [self.item setSizes:files allocated:allocated total:total totalAllocated:totalallocated];
        NSLog(@"Calculation done on %@", self.item.url);
    }
    
}
@end
