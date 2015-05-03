//
//  NodeSortDescriptor.h
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseGrouping.h"


@interface AlphabetGroupping : BaseGrouping
@end


@interface NodeSortDescriptor : NSSortDescriptor {
    BOOL _grouping;
    BaseGrouping *_groupObject;
}

-(void) setGrouping:(BOOL)grouping;
-(BOOL) isGrouping;
-(NSArray*) groupItemsForObject:(id)object;
-(NSArray*) flushGroups;

@end


BaseGrouping* groupingFor(id objTemplate, BOOL ascending);


