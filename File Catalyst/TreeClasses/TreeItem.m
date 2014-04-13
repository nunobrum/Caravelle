//
//  TreeItem.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"

@implementation TreeItem

-(TreeItem*) init {
    self = [super init];
    if (self) {
        [self setByteSize: 0];
        [self setDateModified: nil];
    }
    return self;
}

-(BOOL) isBranch {
    NSAssert(NO, @"This method is supposed to not be called directly. Virtual Method.");
    return NO;
}

@end
