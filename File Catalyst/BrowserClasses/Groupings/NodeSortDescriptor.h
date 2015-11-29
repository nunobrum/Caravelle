//
//  NodeSortDescriptor.h
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseGrouping.h"

#define SORT_FOLDERS_FIRST_FIELD_ID @"FoldersFirst"

@protocol MySortDescriptorProtocol <NSObject>

-(BOOL) isGrouping;
-(NSString*) field;

@end

// This sort descriptor is only to implement the Folders First
// The isGrouping is set for compatibility with the NodeSortDescriptor
@interface FoldersFirstSortDescriptor : NSSortDescriptor<MySortDescriptorProtocol>



@end


@interface NodeSortDescriptor : NSSortDescriptor<MySortDescriptorProtocol> {
    BOOL _grouping;
    NSString *_field;
    BaseGrouping *_groupObject;
}

-(instancetype) initWithField:(NSString *)field ascending:(BOOL)ascending grouping:(BOOL)grouping;

//-(void) setGrouping:(BOOL)grouping using:(NSString*)groupID ;
-(void) copyGroupObject:(NSSortDescriptor*) other;
-(BaseGrouping*) groupOpject;
-(BOOL) isGrouping;
-(NSArray*) groupItemsForObject:(id)object;
-(NSArray*) flushGroups;
-(void) reset;
-(NSString*) field;

@end



