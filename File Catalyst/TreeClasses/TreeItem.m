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
#import "FileUtils.h"

@implementation TreeItem

-(TreeItem*) init {
    self = [super init];
    if (self) {
        self->_url = nil;
        self.tag = 0;
    }
    return self;
}

-(TreeItem*) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super init];
    if (self) {
        self.tag = 0;
        self->_url = url;
        self->_parent = nil;
    }
    return self;
}

+ (TreeItem *)treeItemForURL:(NSURL *)url parent:(id)parent {
    // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
    NSString *typeIdentifier;
    if ([url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL]) {
        if ([typeIdentifier isEqualToString:(NSString *)kUTTypeFolder]) {
            return [[TreeBranch alloc] initWithURL:url parent:parent];
        }
        NSArray *imageUTIs = [NSImage imageTypes];
        if ([imageUTIs containsObject:typeIdentifier]) {
            // !!! TODO : Treat here other file types other than just not folders
            return [[TreeLeaf alloc] initWithURL:url parent:parent];
        }
        else {
            return [[TreeLeaf alloc] initWithURL:url parent:parent];
        }
    }
    return nil;
}


-(BOOL) isBranch {
    NSAssert(NO, @"This method is supposed to not be called directly. Virtual Method.");
    return NO;
}

-(NSString*) name {
    NSString *nameStr = [_url lastPathComponent];
    if ([nameStr isEqualToString:@"/"]) {
        nameStr = mediaNameFromURL(_url);
    }
    return nameStr;
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

-(TreeItem*) root {
    TreeItem *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
    }
    return cursor;
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
    return [NSArray arrayWithObjects:(id)kUTTypeFolder, (id)kUTTypeFileURL, (id)kUTTypeItem, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardReadingAsString;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    // We recreate the appropriate object
    // We only have URLs accepted. Create the URL
    NSURL *url = [[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] ;
    return [TreeItem treeItemForURL:url parent:nil];
}

#pragma mark -


@end
