//
//  MyURL.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 11/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "MyURL.h"

@implementation MyURL


-(BOOL) sendToRecycleBin {
    return [[NSFileManager defaultManager] removeItemAtPath:[self path] error:nil];
}

-(BOOL) eraseFile {
    // Missing implementation
    NSLog(@"Erase File Method not implemented");
    return NO;
}
-(BOOL) copyFileTo:(NSString *)path {
    // Missing implementation
    NSLog(@"Copy File Method not implemented");
    return NO;
}
-(BOOL) moveFileTo:(NSString *)path {
    // Missing implementation
    NSLog(@"Move File Method not implemented");
    return NO;
}

-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
    return YES;
}

@end
