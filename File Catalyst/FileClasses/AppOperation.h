//
//  AppOperation.h
//  File Catalyst
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kModeKey;
extern NSString *kRootPathKey;

extern NSString *notificationFinishedOperation;

//extern NSUInteger appOperationCounter;


@interface AppOperation : NSOperation {
    NSMutableDictionary *_taskInfo;
    NSNumber *_operationID;
}

@property (readonly) NSNumber* operationID;

- (id)initWithInfo:(NSDictionary*)info;
-(NSString*) statusText;
-(NSDictionary*) info;
-(void) send_notification:(NSDictionary*)info;

@end


extern BOOL putInQueue(AppOperation *operation);
