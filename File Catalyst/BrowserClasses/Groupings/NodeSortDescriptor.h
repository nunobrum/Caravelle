//
//  NodeSortDescriptor.h
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SORT_FOLDERS_FIRST_FIELD_ID @"FoldersFirst"

@protocol MySortDescriptorProtocol <NSObject>

-(NSString*) field;

@end

// This sort descriptor is only to implement the Folders First
// The isGrouping is set for compatibility with the NodeSortDescriptor
@interface FoldersFirstSortDescriptor : NSSortDescriptor<MySortDescriptorProtocol>



@end


@interface NodeSortDescriptor : NSSortDescriptor<MySortDescriptorProtocol> {
    NSString *_field;
}

-(instancetype) initWithField:(NSString *)field ascending:(BOOL)ascending;
-(NSString*) field;

@end



