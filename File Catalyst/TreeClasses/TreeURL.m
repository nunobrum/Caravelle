//
//  TreeURL.m
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeURL.h"
#import "TreeBranch.h"
#import "TreePackage.h"
#import "TreeManager.h"
#import "FileUtils.h"
#import "DuplicateInformation.h"
#import "PasteboardUtils.h"

// TODO:!!? Store this in the NSURL instead of _store


const NSString *keyDuplicateInfo = @"TStoreDuplicateKey";
//const NSString *keyMD5Info       = @"TStoreMD5Key";
//const NSString *keyDupRefresh    = @"TStoreDupRefreshKey";

@implementation TreeURL


-(instancetype) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super init];
    if (self) {
        self->_tag = 0;
        [self setUrl:url];
        self->_parent = parent;
        self.nameCache = nil;
        self->_store = nil;
    }
    return self;
}

-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    return [self initWithURL: [NSURL fileURLWithPath:path] parent:parent];
}


+(id) treeItemForURL:(NSURL *)url parent:(id)parent {
    // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
    // TODO:!! Check Is regular file First. See NSURLIsRegularFileKey
    NSString *typeIdentifier;
    if ([url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL]) {
        if (isFolder(url)) {
            BOOL ispackage = isPackage(url);
            if (ispackage) {
                if (//[typeIdentifier isEqualToString:(NSString*)kUTTypeApplication] ||
                    //[typeIdentifier isEqualToString:(NSString*)kUTTypeApplicationFile] ||
                    [typeIdentifier isEqualToString:(NSString*)kUTTypeApplicationBundle]) {
                    return [[TreePackage alloc] initWithURL:url parent:parent];
                }
                /* Debug Code */
                /*else if ([typeIdentifier isEqualToString:@"com.apple.xcode.project"] ||
                 [typeIdentifier isEqualToString:@"com.apple.dt.document.workspace"]) {
                 return [[TreeURL alloc] initWithURL:url parent:parent];
                 }*/
            }
            if (//[typeIdentifier isEqualToString:(NSString *)kUTTypeFolder] ||
                [typeIdentifier isEqualToString:(NSString *)kUTTypeVolume]) {
                // TODO:!!! Create a dedicated class for a Volume or a mounting point
            }
            return [[TreeBranch alloc] initWithURL:url parent:parent];
        }
        else {
            /* Check if it is an image type */
            NSArray *imageUTIs = [NSImage imageTypes];
            if ([imageUTIs containsObject:typeIdentifier]) {
                //  TODO:!!! Treat here other file types other than just not folders
                return [[TreeURL alloc] initWithURL:url parent:parent];
            }
            return [[TreeURL alloc] initWithURL:url parent:parent];
        }
    }
    return nil;
}

+(id)treeItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent {
    // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
    //NSString *typeIdentifier = [mdItem valueForAttribute:(id)kMDItemContentType];
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    NSURL *url = [NSURL fileURLWithPath:path];
    id answer = [self treeItemForURL:url parent:parent];
    return answer;
}


-(void) setUrl:(NSURL*)url {
    // The tags shoud be set here accordingly to the information got from URL
    // TODO: When the Icon View is changed to a data Delegate model instead of the ArrayController, the "name" notification can be removed.
    [self willChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change
    self->_url = url;
    self.nameCache = nil; // Will force update in the next call to name
    [self updateFileTags];
    //[self didChangeValueForKey:@"url"];
    [self didChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change.
    [self notifyChange];
}

-(NSURL*) url {
    return _url;
}

-(void) purgeURLCacheResources {
    [self->_url removeAllCachedResourceValues];
}


-(void) updateFileTags {
    _tag &= ~tagTreeItemDirty;
    if (isWritable(_url))
        _tag &= ~tagTreeItemReadOnly;
    else
        _tag |= tagTreeItemReadOnly;
    
    if (isHidden(_url))
        _tag |= tagTreeItemHidden;
    else
        _tag &= ~tagTreeItemHidden;
    
}

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
    NSString const *operation=nil;
    if ([self hasTags:tagTreeItemNew]) {
        operation = opNewFolder;
    }
    else {
        // If the name didn't change. Do Nothing
        if ([newName isEqualToString:[self name]]) {
            return;
        }
        operation = opRename;
    }
    self.nameCache = newName;
    NSArray *items = [NSArray arrayWithObject:self];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          items, kDFOFilesKey,
                          operation, kDFOOperationKey,
                          newName, kDFORenameFileKey,
                          self->_parent, kDFODestinationKey,
                          //self, kFromObjectKey,
                          nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];
    
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
    return [_url path];
}

-(NSString*) location {
    return [[_url URLByDeletingLastPathComponent] path];
}

-(NSImage*) image {
    NSImage *iconImage;
    
    // First get the image
    if ([self hasTags:tagTreeItemNew] || self.url==nil) {
        return [super image];
    }
    else  {
        iconImage =[[NSWorkspace sharedWorkspace] iconForFile: [_url path]];
        return [self _applyOverlayToIcon:iconImage];
    }
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


-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
    return YES;
}




-(BOOL) removeItem {
    [self removeFromDuplicateRing];
    return [super removeItem];
}
/*
 * Storage Support
 */

-(void) addToStore:(NSDictionary*) dict {
    if (self->_store==nil)
        self->_store = [[NSMutableDictionary alloc] init];
    
    [self->_store addEntriesFromDictionary: dict];
}

#pragma mark -
#pragma mark URL comparison methods

-(enumPathCompare) relationToPath:(NSString*) otherPath {
    return path_relation([self path], otherPath);
}

-(enumPathCompare) compareTo:(TreeURL*) otherItem {
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
    return [self canContainPath:[url path]];
}

-(BOOL) containedInURL: (NSURL*) url {
    return [self containedInPath:[url path]];
    
}


#pragma mark -
#pragma mark NSPasteboardWriting support


//TODO:!!! Try to pass NSFilenamePboardType to see if drag to recycle bin can be executed
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

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
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
    {
        // We only have URLs accepted. Create the URL
        NSURL *url = [[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] ;
        return [TreeURL treeItemForURL:url parent:nil];
    }
}

// Copy and paste support
-(NSDragOperation) supportedPasteOperations:(id<NSDraggingInfo>) info {
    NSDragOperation sourceDragMask = supportedOperations(info);
    sourceDragMask &= NSDragOperationGeneric;
    return sourceDragMask;
}

-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject {
    // TODO:!!!! Implement drop of files
    NSLog(@"TreeURL.acceptDropped:operation:  Missing implementation");
    return nil; // Invalidate all
}

/*
 * Dupplicate Support
 */

-(DuplicateInformation*) duplicateInfo {
    DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
    return dupInfo;
}

-(DuplicateInformation*) startDuplicateInfo {
    DuplicateInformation *dupInfo = [[DuplicateInformation alloc] init];
    [self addToStore:[NSDictionary dictionaryWithObject:dupInfo forKey:keyDuplicateInfo]];
    return dupInfo;
}

-(void) removeDuplicateInfo {
    // It will remove the current duplicate, if exists
    [self->_store removeObjectForKey:keyDuplicateInfo];
}

-(TreeURL*) nextDuplicate {
    DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
    if (dupInfo)
        return [dupInfo nextDuplicate];
    else
        return nil;
}

/*-(void) setNextDuplicate:(TreeURL*)item group:(NSUInteger)group {
    assert(item!=nil);
    // Get nextDuplicate and create it if Needed
    DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
    if (dupInfo == nil) {
        dupInfo = [self startDuplicateInfo];
    }
    [dupInfo setNextDuplicate:item];
    dupInfo->dupGroup = group;
}*/

// The duplicates are organized on a ring fashion for memory space efficiency
// FileA -> FileB -> FileC-> FileA
// This function returns an indicator whether the group should be incremented, if it is a new group of duplicates

-(BOOL) addDuplicate:(TreeURL*)duplicateFile group:(NSUInteger)group {
    DuplicateInformation *selfdi = [self duplicateInfo];
    if (selfdi == nil) {
        selfdi = [self startDuplicateInfo];
    }
    
    DuplicateInformation *dupdi = [duplicateFile duplicateInfo];
    if (dupdi == nil) {
        dupdi = [duplicateFile startDuplicateInfo];
    }
    
    if ([selfdi nextDuplicate]==nil) // A new set of duplicates
    {
        [selfdi setNextDuplicate:duplicateFile];
        selfdi->dupGroup = group;
        [dupdi setNextDuplicate:self];
        dupdi->dupGroup = group;
        return YES;
    }
    else {
        [dupdi setNextDuplicate:[selfdi nextDuplicate]];
        dupdi->dupGroup = selfdi->dupGroup;
        [selfdi setNextDuplicate:duplicateFile];
        return  NO;
    }
}

-(BOOL) hasDuplicates {
    return ([self nextDuplicate] == nil ? NO : YES);
}

-(NSUInteger) duplicateCount {
    if ([self nextDuplicate] == nil)
        return 0;
    else
    {
        TreeURL *cursor=self.nextDuplicate;
        int count =0;
        while (cursor!=self) {
            cursor = cursor.nextDuplicate;
            count++;
        }
        return count;
    }
}

-(NSMutableArray*) duplicateList {
    if (self.nextDuplicate==nil)
        return nil;
    else
    {
        TreeURL *cursor=self.nextDuplicate;
        NSMutableArray *answer =[[NSMutableArray new]init];
        while (cursor!=self && cursor != nil) {
            [answer addObject:cursor];
            cursor = cursor.nextDuplicate;
        }
        return answer;
    }
}

-(void) removeFromDuplicateRing {
    if (self.nextDuplicate!=nil)
    {
        TreeURL *cursor=self.nextDuplicate;
        if (cursor.nextDuplicate == self) { // In case if only one duplicate
            [cursor removeDuplicateInfo];   // Deletes the chain
        }
        else {
            while (cursor.nextDuplicate!=self) { // searches for the file that references this one
                cursor = cursor.nextDuplicate;
            }
            [cursor.duplicateInfo setNextDuplicate: self.nextDuplicate ]; // and bypasses this one
        }
        [self removeDuplicateInfo];
    }
}

-(void) resetDuplicates {
    TreeURL *cursor=self;
    while (cursor.duplicateInfo!=nil) {
        TreeURL *tmp = cursor;
        cursor = cursor.nextDuplicate;
        //[tmp->_store removeObjectForKey:keyDuplicateInfo]; // Deletes the nextDuplicate AND refreshCount
        tmp->_store = nil;
    }
}

-(void) setDuplicateRefreshCount:(NSInteger)count {
    [self duplicateInfo]->dupRefreshCounter = count;
}

-(NSInteger) duplicateRefreshCount {
    return [self duplicateInfo]->dupRefreshCounter;
}

-(NSNumber*)duplicateGroup {
    DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
    if (dupInfo)
        return [NSNumber numberWithInteger:dupInfo->dupGroup];
    else
        return [NSNumber numberWithInt:0];
}




/*-(NSData*) MD5 {
    NSData * MD5;
    // First Check gets the duplicate Info
    DuplicateInformation *dupInfo = [self duplicateInfo];
    if (dupInfo) {
        if (dupInfo->valid_md5) {
            return [[NSData alloc] initWithBytes:dupInfo->md5_checksum length:16];
        }
    }
    else {
        dupInfo = [self startDuplicateInfo];
    }
    calculateMD5(self->_url, dupInfo->md5_checksum);
    return [[NSData alloc] initWithBytes:dupInfo->md5_checksum length:16];
}*/

-(BOOL) compareMD5checksum: (TreeURL *)otherFile {
    DuplicateInformation *myDupInfo = [self duplicateInfo];
    DuplicateInformation *otherDupInfo = [otherFile duplicateInfo];
    
    if (myDupInfo    == nil)
        myDupInfo = [self startDuplicateInfo];
    if (otherDupInfo == nil)
        otherDupInfo = [otherFile startDuplicateInfo];
    
    if (myDupInfo->valid_md5 == NO) {
        calculateMD5(self->_url, myDupInfo->md5_checksum);
        myDupInfo->valid_md5 = YES;
    }
    if (otherDupInfo->valid_md5 == NO) {
        calculateMD5(otherFile->_url, otherDupInfo->md5_checksum);
        otherDupInfo->valid_md5 = YES;
    }
    int res = memcmp(myDupInfo->md5_checksum, otherDupInfo->md5_checksum, 16);
    return  res==0 ? YES : NO;
}


/*
 * Debug
 */

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"%@ url:%@", [super debugDescription], self.url];
}

-(NSString*) description {
    return [NSString stringWithFormat: @"%@ url:%@", [super description], self.url];
}


@end
