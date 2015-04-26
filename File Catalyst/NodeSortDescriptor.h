//
//  NodeSortDescriptor.h
//  Caravelle
//
//  Created by Nuno Brum on 23/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>



/*
 * Grouping of elements
 */

@interface BaseGroupingObject : NSObject {
    BOOL _ascending;
    id _lastObject;
    NSString* _currentTitle;
}


-(instancetype) initWithAscending:(BOOL)ascending;
-(NSString*) groupTitleFor:(id) newObject;
-(void) restart;

@end


@interface NumberGrouping : BaseGroupingObject
@end

@interface DateGrouping : BaseGroupingObject
@end

@interface StringGrouping : BaseGroupingObject
@end

@interface AlphabetGroupping : BaseGroupingObject
@end


@interface NodeSortDescriptor : NSSortDescriptor {
    BOOL _grouping;
    BaseGroupingObject *_groupObject;
}

-(void) setGrouping:(BOOL)grouping;
-(BOOL) isGrouping;
-(NSString*) groupTitleForObject:(id)object;
-(void) restart;

@end


BaseGroupingObject* groupingFor(id objTemplate, BOOL ascending);


