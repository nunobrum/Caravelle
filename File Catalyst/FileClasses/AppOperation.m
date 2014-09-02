//
//  AppOperation.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "AppOperation.h"

// key for obtaining the current scan count
NSString *kOperationCountKey = @"operationCount";

NSString *kRootPathKey = @"RootPath";

// key for obtaining the associated TreeRoot
NSString *kSenderKey = @"Sender";

NSString *kModeKey = @"Mode";

@implementation AppOperation

- (id)initWithInfo:(NSDictionary*)info {
    self = [super init];
    if (self)
    {
        _taskInfo = [NSMutableDictionary dictionaryWithDictionary: info];
    }
    return self;
}

@end
