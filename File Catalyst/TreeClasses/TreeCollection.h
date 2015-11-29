//
//  TreeRoot.h
//  Caravelle
//
//  Created by Nuno Brum on 1/16/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCollection.h"
#import "TreeBranchCatalyst.h"


@interface TreeCollection : TreeBranchCatalyst {

}

-(NSArray*) roots; // Directly returns the children

-(void) addFileCollection:(FileCollection*)collection;

@end
