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

// key for obtaining the associated TreeRoot
NSString *kRootPathKey = @"RootPath";

// Key for obtaining the sender of the notification !!! TODO Test if this is really needed. notifications already include sender objects anyway. Maybe just for convinience of resending the Dictionary.
NSString *kSenderKey = @"Sender";

NSString *kModeKey = @"Mode";

@implementation AppOperation

- (id)initWithInfo:(NSDictionary*)info {
    self = [super init];
    if (self)
    {
        _taskInfo = [NSMutableDictionary dictionaryWithDictionary: info];
        operationCount = [info objectForKey:kOperationCountKey];
        statusCount = 0;
    }
    return self;
}

-(NSString*) statusText {
    return [NSString stringWithFormat:@"%d Files Indexed", statusCount];
}

@end
