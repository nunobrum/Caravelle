//
//  TreeItem.m
//  Caravelle
//
//  Created by Nuno Brum on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "TreeBranch.h"
#import "TreePackage.h"
#import "TreeManager.h"
#import "FileUtils.h"
#import "DuplicateInformation.h"



@implementation TreeItem

-(id) hashObject {
    return _url;
}

-(ItemType) itemType {
    NSAssert(NO, @"This method is supposed to not be called directly. Virtual Method.");
    return ItemTypeNone;
}

-(BOOL) isLeaf {
    return [self itemType] >= ItemTypeLeaf;
}

-(BOOL) isFolder {
    return [self itemType] < ItemTypeLeaf;
}

-(BOOL) needsRefresh {
    return NO;
}

-(void) refresh {
    
}

-(BOOL) isExpandable {
    return NO;
}

-(BOOL) canAndNeedsFlat {
    return NO;
}

-(BOOL) needsSizeCalculation {
    return NO;
}

-(BOOL) isGroup {
    return NO;
}

-(BOOL) hasChildren {
    return NO;
}

-(BOOL) isSelectable {
    return (_tag & tagTreeSelectProtect)==0;
}

-(TreeItem*) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super init];
    if (self) {
        self->_tag = 0;
        [self setUrl:url];
        self->_parent = parent;
        self.nameCache = nil;
    }
    return self;
}

-(TreeItem*) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    return [self initWithURL: [NSURL fileURLWithPath:path] parent:parent];
 }

-(void) deinit {
    [self setTag:tagTreeItemRelease];
}


+(id) treeItemForURL:(NSURL *)url parent:(id)parent {
    // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
    // TODO:1.3.3 Check Is regular file First. See NSURLIsRegularFileKey
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
                    return [[TreeLeaf alloc] initWithURL:url parent:parent];
                }*/
            }
            if (//[typeIdentifier isEqualToString:(NSString *)kUTTypeFolder] ||
                [typeIdentifier isEqualToString:(NSString *)kUTTypeVolume]) {
                // TODO:1.4 Create a dedicated class for a Volume or a mounting point
            }
            return [[TreeBranch alloc] initWithURL:url parent:parent];
        }
        else {
            /* Check if it is an image type */
            NSArray *imageUTIs = [NSImage imageTypes];
            if ([imageUTIs containsObject:typeIdentifier]) {
                //  TODO:1.3.3 Treat here other file types other than just not folders
                return [[TreeLeaf alloc] initWithURL:url parent:parent];
            }
            return [[TreeLeaf alloc] initWithURL:url parent:parent];
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
    // TODO:1.3.3 When the Icon View is changed to a data Delegate model instead of the ArrayController, the "name" notification can be removed.
    [self willChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change
    self->_url = url;
    self->_nameCache = nil; // Will force update in the next call to name
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

-(void) setTag:(TreeItemTagEnum)tag {
    _tag |= tag;
}
-(void) resetTag:(TreeItemTagEnum)tag {
    _tag &= ~tag;
}
-(void) toggleTag:(TreeItemTagEnum)tag {
    _tag ^= tag;
}

-(TreeItemTagEnum) tag {
    return _tag;
}

-(BOOL) hasTags:(TreeItemTagEnum) tag {
    return (_tag & tag)!=0 ? YES : NO;
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
    NSImage *iconImage;
    NSImage *image;
    
    // First get the image
    if ([self hasTags:tagTreeItemNew] || self.url==nil) {
        if ([self isFolder])
            iconImage = [NSImage imageNamed:@"GenericFolderIcon"];
        else
            iconImage = [NSImage imageNamed:@"GenericDocumentIcon"];
    }
    else  {
        iconImage =[[NSWorkspace sharedWorkspace] iconForFile: [_url path]];
    }
    
    
    NSSize imageSize= [iconImage size];
    //TreeItemTagEnum tags = [self tag];
    image = [NSImage imageWithSize:imageSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [iconImage drawInRect:dstRect];
        
        // Then will apply an overlay
        // The code below only draw one of the badges in the order the code is presented.
        // TODO:1.4 Consider making an shifted overlay where all the applicable badges are placed
        //         in sequence, starting from right to left
        if ([self hasTags:tagTreeItemHidden]) {
            [[NSImage imageNamed:@"PrivateFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ private", [self url]);
        }
        else if ([self hasTags:tagTreeItemReadOnly]) {
            [[NSImage imageNamed:@"ReadOnlyFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ read-only", [self url]);
        }
        else if ([self hasTags:tagTreeItemDropped]) {
            [[NSImage imageNamed:@"DropFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ dropped", [self url]);
        }
        return YES;
    }];
    return image;
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



-(TreeItem*) root {
    TreeItem *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
    }
    return cursor;
}

-(void) notifyChange {
    if (self->_parent!=nil) {
        [(TreeBranch*) self->_parent notifyDidChangeTreeBranchPropertyChildren];
    }
}


-(NSArray *) treeComponents {
    NSMutableArray *answer = [NSMutableArray arrayWithObject:self];
    TreeItem *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
        [answer insertObject:cursor atIndex:0];
    }
    return answer;
}

-(NSArray *) treeComponentsToParent:(id)parent {
    NSMutableArray *answer = [NSMutableArray arrayWithObject:self];
    TreeItem *cursor = self;
    while (cursor!=parent && cursor->_parent!=NULL ) {
        cursor=cursor->_parent;
        [answer insertObject:cursor atIndex:0];
    }
    return answer;
}

-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:[self path]];
    return YES;
}

-(BOOL) removeItem {
    if (_parent) {
        [(TreeBranch*)_parent removeChild:self];
    }
    [self deinit];
    return YES;
}

#pragma mark -
#pragma mark URL comparison methods

-(enumPathCompare) relationToPath:(NSString*) otherPath {
    return path_relation([self path], otherPath);
}

-(enumPathCompare) compareTo:(TreeItem*) otherItem {
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
        return [TreeItem treeItemForURL:url parent:nil];
    }
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

#pragma mark - Coding Compliant

/*
 * Coding Compliant methods
 */
-(void) setValue:(id)value forUndefinedKey:(NSString *)key {

    NSLog(@"TreeItem.setValue:forUndefinedKey: Trying to set value for Key %@", key);
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


/*
 * Debug
 */

-(NSString*) debugDescription {
    return [NSString stringWithFormat: @"%@|url:%@", self.className, self.url];
}

-(NSString*) description {
    return [NSString stringWithFormat: @"%@|url:%@", self.className, self.url];
}

@end
