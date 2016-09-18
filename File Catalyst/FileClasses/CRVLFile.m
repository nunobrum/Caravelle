//
//  CRVLFile.m
//  Caravelle
//
//  Created by Nuno on 28/05/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "CRVLFile.h"
#import "FileUtils.h"

@implementation CRVLFile

-(instancetype) initWithURL:(NSURL*)url {
    self->_url = url;
    self->_nameCache = nil;
    return self;
}

-(void) setUrl:(NSURL*)url {
    // The tags shoud be set here accordingly to the information got from URL
    // TODO:1.3.3 When the Icon View is changed to a data Delegate model instead of the ArrayController, the "name" notification can be removed.
    [self willChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change
    self->_url = url;
    self->_nameCache = nil; // Will force update in the next call to name
    
    //[self didChangeValueForKey:@"url"];
    [self didChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change.
}

-(NSURL*) url {
    return _url;
}

-(void) purgeURLCacheResources {
    [self->_url removeAllCachedResourceValues];
}

#pragma mark - Item Protocol

-(NSString*) name {
    if (self.nameCache) {
        return self.nameCache;
    }
    NSString *nameStr = [_url lastPathComponent];
    if ([nameStr isEqualToString:@"/"]) {
        nameStr = mediaNameFromURL(_url);
    }
    self.nameCache = nameStr;
    return nameStr;
}

-(void) setName:(NSString*)newName {
    self.nameCache = newName;
    NSArray *items = [NSArray arrayWithObject:self];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          items, kDFOFilesKey,
                          opRename, kDFOOperationKey,
                          newName, kDFORenameFileKey,
                          //self, kFromObjectKey,
                          nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
    
}

-(BOOL) isHidden {
    return isHidden(_url);
}

-(BOOL) isReadOnly {
    return isWritable(_url)==NO;
}

-(BOOL) isSelectable {
    return YES;
}

-(BOOL) isFolder {
    return NO;
}

-(NSDate*) date_modified {
    NSDate *date=nil;
    NSError *errorCode;
    if ([_url isFileURL]) {
        [_url getResourceValue:&date forKey:NSURLContentModificationDateKey error:&errorCode];
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[_url path] error:NULL];
        date = [dirAttributes fileModificationDate];
        
    }
    return date;
}

-(NSDate*)   date_accessed {
    NSDate *date=nil;
    NSError *errorCode;
    if ([_url isFileURL]) {
        [_url getResourceValue:&date forKey:NSURLContentAccessDateKey error:&errorCode];
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[_url path] error:NULL];
        date = [dirAttributes fileModificationDate];
        
    }
    return date;
}
-(NSDate*)   date_created {
    NSDate *date=nil;
    NSError *errorCode;
    if ([_url isFileURL]) {
        [_url getResourceValue:&date forKey:NSURLCreationDateKey error:&errorCode];
    }
    else {
        NSDictionary *dirAttributes =[[NSFileManager defaultManager] attributesOfItemAtPath:[_url path] error:NULL];
        date = [dirAttributes fileCreationDate];
        
    }
    return date;
}

-(NSString*) path {
    //NSString *path;
    //[_url getResourceValue:&path     forKey:NSURLPathKey error:NULL];
    return [_url path];
}

-(NSString*) location {
    //NSString *path;
    //[_url getResourceValue:&path     forKey:NSURLPathKey error:NULL];
    return [[_url URLByDeletingLastPathComponent] path];
}

-(NSImage*) image {
    return [[NSWorkspace sharedWorkspace] iconForFile: [_url path]];
}


-(NSNumber*) exactSize {
    NSNumber *exactSize;
    [_url getResourceValue:&exactSize     forKey:NSURLFileSizeKey error:NULL];
    return exactSize;
}

-(NSNumber*) allocatedSize {
    NSNumber *filesize;
    [_url getResourceValue:&filesize     forKey:NSURLFileAllocatedSizeKey error:NULL];
    return filesize;
}

-(NSNumber*) totalSize {
    NSNumber *filesize;
    [_url getResourceValue:&filesize     forKey:NSURLTotalFileSizeKey error:NULL];
    return filesize;
}

-(NSNumber*) totalAllocatedSize {
    NSNumber *filesize;
    [_url getResourceValue:&filesize     forKey:NSURLTotalFileAllocatedSizeKey error:NULL];
    return filesize;
}

-(NSString*) fileKind {
    NSString *kind;
    [_url getResourceValue:&kind     forKey:NSURLLocalizedTypeDescriptionKey error:NULL];
    return kind;
}

-(NSString*) hint {
    return [self name];
}


-(NSString*) fileOwnerName {
    NSError *error;
    NSDictionary *fileAttributes = [appFileManager attributesOfItemAtPath:self.url.path error:&error];
    
    if (fileAttributes != nil) {
        NSString *fileOwner = [fileAttributes fileOwnerAccountName];
        return fileOwner;
    }
    return nil;
}

-(NSNumber*) fileOwnerID {
    NSError *error;
    NSDictionary *fileAttributes = [appFileManager attributesOfItemAtPath:self.url.path error:&error];
    
    if (fileAttributes != nil) {
        NSNumber *fileOwner = [fileAttributes fileOwnerAccountID];
        return fileOwner;
    }
    return nil;
}

-(NSString*) fileGroupName {
    NSError *error;
    NSDictionary *fileAttributes = [appFileManager attributesOfItemAtPath:self.url.path error:&error];
    
    if (fileAttributes != nil) {
        NSString *fileOwner = [fileAttributes fileGroupOwnerAccountName];
        return fileOwner;
    }
    return nil;
}

-(NSNumber*) fileGroupID {
    NSError *error;
    NSDictionary *fileAttributes = [appFileManager attributesOfItemAtPath:self.url.path error:&error];
    
    if (fileAttributes != nil) {
        NSNumber *fileOwner = [fileAttributes fileGroupOwnerAccountID];
        return fileOwner;
    }
    return nil;
}

/*
 -(NSString*) fileLock {
 NSError * error;
 NSDictionary *attributes =  [[NSFileManager defaultManager] attributesOfItemAtPath:self.url.path error:&error];
 //NSNumber *fileLock = [attributes objectForKey:@"NSFileImmutable"];
 if ([attributes fileIsImmutable])
 return @"Locked";
 else
 return @"";
 }*/

-(NSString*) filePermissions {
    NSError *error;
    NSDictionary *fileAttributes = [appFileManager attributesOfItemAtPath:self.url.path error:&error];
    
    if (fileAttributes != nil) {
        NSUInteger filePermissions = [fileAttributes filePosixPermissions];
        
        unichar permissions [9] = {'r','w','x','r','w','x','r','w','x'};
        for (int i=8;i>=0;i--) {
            if ((filePermissions & 1)==0) {
                permissions[i] = '-';
            }
            filePermissions = filePermissions >> 1;
        }
        NSString *pattr = [NSString stringWithCharacters:permissions length:9];
        return pattr;
    }
    return nil;
}

-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
    return YES;
}

-(NSArray*) openWithApplications {
    CFArrayRef appls;
    appls = LSCopyApplicationURLsForURL((__bridge CFURLRef _Nonnull)(self.url),   kLSRolesViewer+kLSRolesEditor );
    NSArray *answer = CFBridgingRelease(appls);
    return answer;
}

#pragma mark -
#pragma mark URL comparison methods

-(enumPathCompare) relationToPath:(NSString*) otherPath {
    return path_relation([self path], otherPath);
}

-(enumPathCompare) compareTo:(CRVLFile*) otherItem {
    return [self relationToPath:[otherItem path]];
}

/* This is a test if it can contain the URL */
-(BOOL) canContainPath:(NSString*)path {
    NSArray *cpself = [[self path] pathComponents];
    NSArray *cppath = [path pathComponents];
    NSUInteger cpsc = [cpself count];
    if (cpsc> [cppath count])
        return NO;
    for (NSUInteger i = 0 ; i < cpsc ; i++) {
        if (NO == [cpself[i] isEqualToString:cppath[i]]) {
            return NO;
        }
    }
    return YES;
}

-(BOOL) containedInPath: (NSString*) path {
    NSArray *cpself = [[self path] pathComponents];
    NSArray *cppath = [path pathComponents];
    NSUInteger cppc = [cppath count];
    if (cppc> [cpself count])
        return NO;
    for (NSUInteger i = 0 ; i < cppc ; i++) {
        if (NO == [cppath[i] isEqualToString:cpself[i]]) {
            return NO;
        }
    }
    return YES;
}
/* This is a test if it can contain the URL */
-(BOOL) canContainURL:(NSURL*)url {
    //TODO:!!!! optimize this
    return [self canContainPath:[url path]];
}

-(BOOL) containedInURL: (NSURL*) url {
    return [self containedInPath:[url path]];
    
}

/*
 * Duplicate Support
 */
// This function is just a placeholder. It has to be overriden in Branches and Leafs
-(BOOL) hasDuplicates {
    return NO;
}

-(NSNumber*)duplicateGroup {
    return [NSNumber numberWithInt:0];
}

#pragma mark -
#pragma mark NSPasteboardWriting support


//TODO:1.3.3 Try to pass NSFilenamePboardType to see if drag to recycle bin can be executed
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
#ifdef USE_UTI
    /* Adding the TreeType */
    NSMutableArray *answer =[NSMutableArray arrayWithObject:(__bridge id)kTreeItemDropUTI];
    [answer addObjectsFromArray:[self.url writableTypesForPasteboard:pasteboard]];
    return answer;
#else
    return [self.url writableTypesForPasteboard:pasteboard];
#endif
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    id answer;
#ifdef USE_UTI
    if (UTTypeEqual ((__bridge CFStringRef)(type),kTreeItemDropUTI)) {
        answer = self;
    }
    else
#endif
        answer = [self.url pasteboardPropertyListForType:type];
    return answer;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    NSPasteboardWritingOptions answer;
#ifdef USE_UTI
    if (UTTypeEqual ((__bridge CFStringRef)(type),kTreeItemDropUTI)) {
        // If a custom UTI is ever considered, write the Write to pasteboard
        answer = 0;
    }
    else
#endif
        if ([self.url respondsToSelector:@selector(writingOptionsForType:pasteboard:)]) {
            answer = [self.url writingOptionsForType:type pasteboard:pasteboard];
        } else {
            answer = 0;
        }
    return answer;
}

#pragma mark -
#pragma mark  NSPasteboardReading support

+ (NSArray<NSString *> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    //return [NSArray arrayWithObjects: //(id)kUTTypeFolder, (id)kUTTypeFileURL, (id)kUTTypeItem,
    //        (id)NSFilenamesPboardType, (id)NSURLPboardType, OwnUTITypes nil];
    return [NSURL readableTypesForPasteboard:pasteboard];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    //return NSPasteboardReadingAsString;
    return [NSURL readingOptionsForType:type pasteboard:pasteboard];
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    // We recreate the appropriate object
#ifdef USE_UTI
    if (UTTypeEqual ((__bridge CFStringRef)(type),kTreeItemDropUTI)) {
        // If a custom UTI is ever considered, write the Write to pasteboard
        return propertyList; // If ever the custom UTI is created. Check if this works
    }
    else
#endif
        
        // We only have URLs accepted. Create the URL
    NSURL *url = [[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] ;
    [self setUrl:url];
    return self;
}

// Copy and paste support
-(NSDragOperation) supportedPasteOperations:(id<NSDraggingInfo>) info {
    NSLog(@"TreeItem.supportedPasteOperations:  This method should be overrided.");
    return NSDragOperationNone;
}

-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject {
    NSLog(@"TreeItem.acceptDropped:operation:  This method should be overrided.");
    return nil; // Invalidate all
}



@end
