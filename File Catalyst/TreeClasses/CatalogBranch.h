//
//  CatalogBranch.h
//  File Catalyst
//
//  Created by Nuno Brum on 26/10/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "searchTree.h"

@interface CatalogBranch : searchTree

@property NSString *catalogKey;
@property NSValueTransformer *valueTransformer;

@end
