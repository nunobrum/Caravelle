//
//  AppOperation.m
//  File Catalyst
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#include "Definitions.h"
#import "AppOperation.h"

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
    }
    return self;
}

-(NSString*) statusText {
    return @"...";
}

-(NSDictionary*) info {
    return _taskInfo;
}

-(void) send_notification:(NSDictionary*)info {
    [_taskInfo addEntriesFromDictionary:info];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationFinishedOperation object:nil userInfo:_taskInfo];
}

-(void) main {
    // Send a fail
    [self send_notification:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kDFOOkKey]];
}

@end


BOOL putInQueue(AppOperation *operation) {
    //AppOperation *operation = [[AppOperation alloc ] initWithInfo:taskInfo];
    BOOL answer = [operation isReady];
    if (answer==YES)
        [operationsQueue addOperation:operation];
    return answer;
}

