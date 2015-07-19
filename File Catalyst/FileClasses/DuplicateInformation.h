//
//  DuplicateInformation.h
//  Caravelle
//
//  Created by Nuno Brum on 5/7/12.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSValue.h>

#import "TreeLeaf.h"

#include "MD5.h"

@interface DuplicateInformation : NSObject {
@public
    md5_byte_t md5_checksum[16];
    bool valid_md5;
    NSUInteger dupRefreshCounter;
    NSUInteger dupGroup;
}

@property TreeLeaf *nextDuplicate;

-(DuplicateInformation *) init;

@end
