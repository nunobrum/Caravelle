//
//  TreeItem.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
//#import "MyDirectoryEnumerator.h"
#import "TreeBranch.h"

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

#pragma mark -
#pragma mark NSPasteboardWriting support

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [self.url writableTypesForPasteboard:pasteboard];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    return [self.url pasteboardPropertyListForType:type];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([self.url respondsToSelector:@selector(writingOptionsForType:pasteboard:)]) {
        return [self.url writingOptionsForType:type pasteboard:pasteboard];
    } else {
        return 0;
    }
}

#pragma mark -
#pragma mark  NSPasteboardReading support

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    // We allow creation from folder and image URLs only, but there is no way to specify just file URLs that contain images
    return [NSArray arrayWithObjects:(id)kUTTypeFolder, (id)kUTTypeFileURL, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardReadingAsString;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    // We recreate the appropriate object
    //[self release];
    self = nil;
    // We only have URLs accepted. Create the URL
    NSURL *url = [[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] ;
    // Now see what the data type is; if it isn't an image, we return nil
    NSString *urlUTI;
    if ([url getResourceValue:&urlUTI forKey:NSURLTypeIdentifierKey error:NULL]) {
        // We could use UTTypeConformsTo((CFStringRef)type, kUTTypeImage), but we want to make sure it is an image UTI type that NSImage can handle
        // TODO !!! TO BE Further Developped
//        if ([[NSImage imageTypes] containsObject:urlUTI]) {
//            // We can use it with NSImage
//            self = [[TreeLeafImageFile alloc] initWithFileURL:url];
//        } else if ([urlUTI isEqualToString:(id)kUTTypeFolder]) {
//            // It is a folder
//            self = [[TreeBranch alloc] initWithURL:url parent:nil];
//        }
    }
    // We may return nil
    return self;
}

#pragma mark -


@end
