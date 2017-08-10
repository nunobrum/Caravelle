//
//  MySortDescriptors.h
//  Caravelle
//
//  Created by Nuno Brum on 20.02.17.
//  Copyright © 2017 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NodeSortDescriptor.h"

@interface MySortDescriptors : NSObject {
    NSMutableArray<NodeSortDescriptor *> *_sortDescArray;
}

- (NSComparisonResult)compareObject:(id _Nonnull)object1 toObject:(id _Nonnull)object2;

-(NSInteger) count;
-(NodeSortDescriptor  * _Nullable ) objectAtIndexedSubscript:(NSUInteger)idx;
-(void) addSortDescriptor:(NodeSortDescriptor * _Nonnull)sortDesc;
-(void) removeAll;

- (NodeSortDescriptor * _Nullable) sortDescriptorForFieldID:(NSString * _Nonnull) fieldID;
//- (NSInteger) indexOfFieldID:(NSString * _Nonnull) fieldID;
- (BOOL) hasFieldID:(NSString * _Nonnull) fieldID;
- (void) removeSortOnField:(NSString * _Nonnull)key;

-(NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState * _Null_unspecified)state objects:(id  _Nullable __unsafe_unretained [_Nonnull])buffer count:(NSUInteger)len;

@end
