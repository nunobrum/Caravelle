//
//  AppOperation.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kSenderKey;
extern NSString *kModeKey;
extern NSString *kOperationCountKey;
extern NSString *kRootPathKey;

//extern NSUInteger appOperationCounter;


@interface AppOperation : NSOperation {
    NSMutableDictionary *_taskInfo;
    NSNumber *_operationID;
@public
    NSUInteger statusCount;
    NSUInteger statusTotal;
}

@property (readonly) NSNumber* operationID;

- (id)initWithInfo:(NSDictionary*)info;
-(NSString*) statusText;

@end
