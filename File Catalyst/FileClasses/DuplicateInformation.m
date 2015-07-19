//
//  DuplicateInformation.m
//  Caravelle
//
//  Created by Nuno Brum on 5/7/12.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "DuplicateInformation.h"
#import "TreeItem.h"


@implementation DuplicateInformation

-(DuplicateInformation *) init {
    self = [super init];
    if (self) {
        _nextDuplicate = nil;
        dupRefreshCounter = 0;
        valid_md5 = FALSE;
        dupGroup = 0;
    }
    return self;
}

@end
