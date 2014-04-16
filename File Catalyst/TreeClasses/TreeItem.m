//
//  TreeItem.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"

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
    NSString *filename;
    NSError *error;
    [_theURL getResourceValue:&filename forKey:NSURLNameKey error:&error];
    if (filename==nil) {
        return [_theURL absoluteString];
    }
    return filename;
}

-(NSDate*) dateModified {
    NSDate *date;
    [_theURL getResourceValue:&date forKey:NSURLContentModificationDateKey error:NULL];
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
@end
