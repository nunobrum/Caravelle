//
//  DuplicateDelegate.h
//  Caravelle
//
//  Created by Nuno on 10/01/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileCollection.h"
#import "TreeCollection.h"
#import "filterBranch.h"
#import "AppDelegate.h"

@interface DuplicateDelegate : NSObject <PathObserverProtocol>

    // Duplicate Support
@property FileCollection *duplicates;
@property filterBranch *unifiedDuplicatesRoot;
@property TreeCollection *rootsWithDuplicates;

-(instancetype) initWithInfo:(NSDictionary*) info app:(AppDelegate*)app;

-(void) setDuplicateInfo:(NSDictionary *)info;
-(void) deinit;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
