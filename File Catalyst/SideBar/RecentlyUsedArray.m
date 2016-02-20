//
//  RecentlyUsedArray.m
//  Caravelle
//
//  Created by Nuno on 20/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "RecentlyUsedArray.h"
#include "Definitions.h"

RecentlyUsedArray *_recentlyUsedLocations;

RecentlyUsedArray *recentlyUsedLocations() {
    if (_recentlyUsedLocations==nil) {
        _recentlyUsedLocations = [[RecentlyUsedArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:USER_DEF_MRU]];
        NSInteger sz = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEF_MRU_COUNT];
        [_recentlyUsedLocations setMaxSize:sz];
    }
    return _recentlyUsedLocations;
}

void storeRecentlyUsed() {
    [[NSUserDefaults standardUserDefaults] setObject:_recentlyUsedLocations.array forKey:USER_DEF_MRU];
}


@implementation RecentlyUsedArray

-(instancetype) initWithArray:(NSArray*) array {
    self = [super init];
    self->_array = [[MYFIFOArrayUnique alloc] initWithArray:array];
    [self->_array setComparator:@selector(isEqualToString:)];
    self->_size = NSIntegerMax;
    return self;
}

-(void) setMaxSize:(NSInteger)size {
    self->_size = size;
}

-(NSArray*) array {
    return [self->_array array];
}

-(void) addRecentlyUsed:(NSObject *)item {
    [self->_array pushFirst:item];
    if ([self->_array count] >= self->_size) {
        [self->_array pop];
    }
}

@end
