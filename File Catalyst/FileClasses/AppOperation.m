//
//  AppOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#include "Definitions.h"
#import "AppOperation.h"

// key for obtaining the current scan count
NSString *kOperationCountKey = @"operationCount";

// key for obtaining the associated TreeRoot
NSString *kRootPathKey = @"RootPath";


NSString *kModeKey = @"Mode";

NSString *notificationFinishedOperation = @"FinishedOperation";


static NSUInteger appOperationCounter = 0;



@implementation AppOperation

- (id)initWithInfo:(NSDictionary*)info {
    self = [super init];
    if (self)
    {
        _taskInfo = [NSMutableDictionary dictionaryWithDictionary: info];
        appOperationCounter++;
        _operationID = [NSNumber numberWithInteger: appOperationCounter];
        //[_taskInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:operationCount forKey:kOperationCountKey]];
        _taskInfo[kOperationCountKey] = _operationID;
        statusCount = 0;
    }
    return self;
}

-(NSString*) statusText {
    return [NSString stringWithFormat:@"%lu Files", statusCount];
}

-(NSDictionary*) info {
    return _taskInfo;
}

@end


BOOL putInQueue(AppOperation *operation) {
    //AppOperation *operation = [[AppOperation alloc ] initWithInfo:taskInfo];
    BOOL answer = [operation isReady];
    if (answer==YES)
        [operationsQueue addOperation:operation];
    return answer;
}

