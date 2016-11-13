//
//  ArraySubset.h
//  Caravelle
//
//  Created by Nuno Brum on 04/10/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArraySubset : NSObject

@property (weak) NSArray *array;
@property NSRange range;

-(id) objectInRangeAtIndex:(NSUInteger)index;

@end
