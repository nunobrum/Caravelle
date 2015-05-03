//
//  BaseGrouping.h
//  Caravelle
//
//  Created by Nuno Brum on 01/05/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupItem : NSObject
@property NSString * title;
@property NSSortDescriptor *descriptor;
@property NSInteger nElements;

-(instancetype) initWithTitle:(NSString*)title;

@end

@interface BaseGrouping : NSObject {
    BOOL _ascending;
}
@property (strong )id lastObject;



-(instancetype) initWithAscending:(BOOL)ascending;
-(NSArray*) groupItemsFor:(id) newObject;
-(NSArray*) flushGroups;

@end


