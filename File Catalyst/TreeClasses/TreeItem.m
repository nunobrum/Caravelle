//
//  TreeItem.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
//#import "MyDirectoryEnumerator.h"

@implementation TreeItem

-(TreeItem*) init {
    self = [super init];
    if (self) {
        [self setByteSize: 0];
        //[self setDateModified: nil];
    }
    return self;
}

-(BOOL) isBranch {
    NSAssert(NO, @"This method is supposed to not be called directly. Virtual Method.");
    return NO;
}

-(NSString*) name {
//    NSString *filename;
//    NSError *error;
//    [_theURL getResourceValue:&filename forKey:NSURLNameKey error:&error];
//    if (filename==nil) {
        return [_theURL lastPathComponent];
//    }
//    return filename;
}

-(NSDate*) dateModified {
    NSDate *date=nil;
    NSError *errorCode;
    if ([_theURL isFileURL]) {
        [_theURL getResourceValue:&date forKey:NSURLContentModificationDateKey error:&errorCode];
        if (errorCode || date==nil) {
            [_theURL getResourceValue:&date forKey:NSURLContentAccessDateKey error:&errorCode];
            
        }
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[_theURL path] error:NULL];
        date = [dirAttributes fileModificationDate];

    }
    return date;
}

-(NSString*) path {
    NSString *path;
    [_theURL getResourceValue:&path     forKey:NSURLPathKey error:NULL];
    return path;
}

-(NSNumber*) filesize {
    NSNumber *filesize;
    [_theURL getResourceValue:&filesize     forKey:NSURLFileSizeKey error:NULL];
    return filesize;
}

-(BOOL) sendToRecycleBin {
    return [[NSFileManager defaultManager] removeItemAtPath:[self path] error:nil];
}

-(BOOL) eraseFile {
    // !!! TODO
    return NO;
}

-(BOOL) copyFileTo:(NSString *)path {
    // !!! TODO : Missing implementation
    NSLog(@"Copy File Method not implemented");
    return NO;
}
-(BOOL) moveFileTo:(NSString *)path {
    // !!! TODO : Missing implementation
    NSLog(@"Move File Method not implemented");
    return NO;
}

-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
    return YES;
}


@end
