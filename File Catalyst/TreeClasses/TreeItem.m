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
        //self->_byteSize = 0;
        self->_url = nil;
        //self->_parent = nil;
    }
    return self;
}

-(TreeItem*) initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        //self->_byteSize = filesize;
        self->_url = url;
        //self->_parent = nil;
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
        return [_url lastPathComponent];
//    }
//    return filename;
}

-(NSDate*) dateModified {
    NSDate *date=nil;
    NSError *errorCode;
    if ([_url isFileURL]) {
        [_url getResourceValue:&date forKey:NSURLContentModificationDateKey error:&errorCode];
        if (errorCode || date==nil) {
            [_url getResourceValue:&date forKey:NSURLContentAccessDateKey error:&errorCode];
            
        }
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[_url path] error:NULL];
        date = [dirAttributes fileModificationDate];

    }
    return date;
}

-(NSString*) path {
    //NSString *path;
    //[_url getResourceValue:&path     forKey:NSURLPathKey error:NULL];
    return [_url path];
}


-(long long) filesize {
    NSNumber *filesize;
    [_url getResourceValue:&filesize     forKey:NSURLFileSizeKey error:NULL];
    return [filesize longLongValue];
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
