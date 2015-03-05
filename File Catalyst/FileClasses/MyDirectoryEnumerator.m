//
//  MyDirectoryEnumerator.m
//  File Catalyst
//
//  Created by Nuno Brum on 15/04/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "MyDirectoryEnumerator.h"

NSArray *urlKeyFieldsToStore() {
    NSArray * URL_KEY_FIELDS = nil;
    if (URL_KEY_FIELDS==nil)
        URL_KEY_FIELDS = [NSArray arrayWithObjects:
                          NSURLNameKey,
                          NSURLIsDirectoryKey,
                          NSURLContentModificationDateKey,
                          NSURLFileSizeKey,
                          NSURLIsWritableKey,
                          NSURLIsRegularFileKey,
                          nil];
    return URL_KEY_FIELDS;
}

@implementation MyDirectoryEnumerator

-(MyDirectoryEnumerator *) init:(NSURL*)directoryToScan WithMode:(BViewMode) viewMode {
     NSDirectoryEnumerationOptions dirEnumOptions = 0;
    if (viewMode == BViewCatalystMode) {
        dirEnumOptions = NSDirectoryEnumerationSkipsHiddenFiles;
    }
    else if (viewMode == BViewBrowserMode){
        dirEnumOptions = NSDirectoryEnumerationSkipsSubdirectoryDescendants;

    } else if (viewMode == BViewDuplicateMode){
        dirEnumOptions = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    }
    // Checks whether to browse packages or if to treat them as folders
    if (NO==[[NSUserDefaults standardUserDefaults] boolForKey:@"BrowseAppsAsFolder"]) {
        dirEnumOptions |= NSDirectoryEnumerationSkipsPackageDescendants;
    }

    // Checks whether to display hidden files
    if (NO==[[NSUserDefaults standardUserDefaults] boolForKey:@"BrowseAHiddenFiles"]) {
        dirEnumOptions |= NSDirectoryEnumerationSkipsHiddenFiles;
    }

    if (dirEnumOptions==0)  {
        NSLog(@"MyDirectoryEnumerator.initWithMode: - No options set in the Enumerator");
    }
    NSFileManager *localFileManager=[[NSFileManager alloc] init];




    self = (MyDirectoryEnumerator*)[localFileManager enumeratorAtURL:directoryToScan
                                                  includingPropertiesForKeys:urlKeyFieldsToStore()
                                                                     options:dirEnumOptions
                                                                errorHandler:nil];

    //self = [super init];
    return self;
}

/*
- (id)nextObject {
    id theURL = [super nextObject];
    // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
    NSString *fileName;
    [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
    //NSLog(@"File %@",fileName);

    // Retrieve whether a directory. From NSURLIsDirectoryKey, also
    // cached during the enumeration.
    NSNumber *isDirectory;
    [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];

    // Ignore files under the _extras directory
    if (([fileName caseInsensitiveCompare:@"_extras"]==NSOrderedSame) &&
     ([isDirectory boolValue]==YES))
     {
     [dirEnumerator skipDescendants];
     NSLog(@"Skipping %@",fileName);
     }
     else
    if ([isDirectory boolValue]==NO)
    {
        FileInformation *theFile = [FileInformation createWithURL: theURL];
        return theFile;
    }
    else {
        return 
    }
}*/

@end
