//
//  RecentlyUsedArray.h
//  Caravelle
//
//  Created by Nuno on 20/02/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MYFIFOArray.h"

@interface RecentlyUsedArray : NSObject {
    MYFIFOArrayUnique *_array;
    NSInteger _size;
}

-(instancetype) initWithArray:(NSArray*)array;
-(NSArray*) array;

-(void) addRecentlyUsed:(NSObject*) item;
-(void) setMaxSize:(NSInteger)size;

@end

extern RecentlyUsedArray *recentlyUsedLocations();
void storeRecentlyUsed();
