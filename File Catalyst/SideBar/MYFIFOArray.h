//
//  MYFIFOArray.h
//  Caravelle
//
//  Created by Nuno on 20/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MYFIFOArray : NSObject {
    NSMutableArray *fifo;
}

-(instancetype) init;
-(instancetype) initWithArray:(NSArray*)array;
-(void) push:(NSObject*) obj;
-(NSObject*) pop;
-(NSArray*) array;
-(NSInteger) count;

@end

@interface MYFIFOArrayUnique : MYFIFOArray {
    SEL selComparator;
}

-(void) setComparator:(SEL)comparator;
-(void) pushFirst:(NSObject*) obj;

@end