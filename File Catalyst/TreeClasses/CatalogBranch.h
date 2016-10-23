//
//  CatalogBranch.h
//  Caravelle
//
//  Created by Nuno Brum on 26/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//
// Description: This class serves to divide Tree Items into filterBranch Classes.
// This is used to create the virtual Folders in which each catalog will create its own subfolders.

#import "searchTree.h"

@interface CatalogBranch : filterBranch

@property NSString *catalogKey;
@property NSValueTransformer *valueTransformer;

@end
