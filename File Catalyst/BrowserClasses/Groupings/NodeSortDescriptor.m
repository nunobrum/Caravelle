//
//  NodeSortDescriptor.m
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "NodeSortDescriptor.h"
#import "SizeGrouping.h"
#import "StringGrouping.h"
#import "DateGrouping.h"
#import "NumberGrouping.h"
#import "DuplicateGrouping.h"
#include "Definitions.h"
#import "CustomTableHeaderView.h"

/*
 * Grouping of elements
 */


@implementation FoldersFirstSortDescriptor
// Distribute Alphabet

-(instancetype) init {
    self = [super initWithKey:@"itemType" ascending:YES ];
    return self;
}

-(NSString*) field {
    return SORT_FOLDERS_FIRST_FIELD_ID;
}

@end


@implementation NodeSortDescriptor

-(instancetype) initWithField:(NSString *)field ascending:(BOOL)ascending {
    NSString * key =      [[columnInfo() objectForKey:field] objectForKey:COL_ACCESSOR_KEY];
    NSString *column_id  =[[columnInfo() objectForKey:field] objectForKey:COL_COL_ID_KEY];
    
    if ([column_id isEqualToString:@"COL_NAME"]) // testing the col_id instead of the FieldID. This will also cover the COL_PATH field
        self = [super initWithKey:key ascending:ascending comparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2 options:NSNumericSearch];
        }];
    else
        self = [super initWithKey:key ascending:ascending];
    
    self->_field = field;
    return self;
}


-(NSString*) field {
    return self->_field;
}

@end


