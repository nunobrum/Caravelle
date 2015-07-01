//
//  TreeRoot.m
//  Caravelle
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeRoot.h"

@implementation TreeRoot

-(void) setName:(NSString*)name {
    self->_name = name;
}

-(NSString*) name {
    return self->_name;
}

-(void) setFileCollection:(FileCollection*)collection {
    _children = collection.fileArray;
}

-(BOOL) needsRefresh {
    return NO;
}

@end
