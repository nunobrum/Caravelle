//
//  ArraySubsetCollection.h
//  Caravelle
//
//  Created by Nuno Brum on 04/10/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArraySubset.h"

@class ElemEnumerator;



@interface ArraySubsetCollection : NSObject

@property (strong) NSMutableArray <ArraySubset*> *subarrays;

// The total number of items
-(NSUInteger) count;
// The number of sections
-(NSUInteger) countOfSubarrays;

-(ElemEnumerator*) tableElements;


@end



@interface ElemEnumerator : NSEnumerator {
    NSUInteger index;
    NSUInteger section;
    ArraySubsetCollection *_parent;
}
-(instancetype) initWithParent:(ArraySubsetCollection*)parent;

@end
