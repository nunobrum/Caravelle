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
    if (self.parent) {
        [self.parent setTag:tagTreeItemDirty];
        [self.parent refresh];
    }
}

-(BOOL) isExpandable {
    return NO;
}

-(BOOL) canBeFlat {
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

-(instancetype) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super init];
    if (self) {
        self->_url = nil;
        self->_tag = 0;
        self->_parent = parent;
        self.nameCache = nil;
        self->_store = nil;
        [self setUrl:url];
    }
    return self;
}

-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
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
    BOOL do_notify = (self->_url!=nil);
    self->_url = url;
    self->_nameCache = nil; // Will force update in the next call to name
    [self updateFileTags];
    //[self didChangeValueForKey:@"url"];
    [self didChangeValueForKey:@"name"]; // This assures that the IconView is informed of the change.
    if (do_notify) // This is to avoid repeated refreshes at the parent.
        [self notifyChange];
}

-(NSURL*) url {
    return _url;
}

-(void) purgeURLCacheResources {
    [self->_url removeAllCachedResourceValues];
}

/*
 * Storage Support
 */

-(void) addToStore:(NSDictionary*) dict {
    if (self->_store==nil)
        self->_store = [[NSMutableDictionary alloc] init];
    
    [self->_store addEntriesFromDictionary: dict];
}

-(void) removeFromStore:(NSArray<NSString*>*)keys {
    if (self->_store!=nil && keys != nil)
        [self->_store removeObjectsForKeys:keys];
}

-(id) objectWithKey:(NSString*) key {
    return [self->_store objectForKey:key];
}

-(void) store:(id)object withKey:(NSString*)key {
    [self->_store setObject:object forKey:key];
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
    
    if (self->_parent) {
        _tag |= (self->_parent.tag & tagTreeAuthorized); // If parent is authorized, this item is also authorized.
    }
    
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
    
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              @[self], kDFOFilesKey,
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

-(NSImage*) _image {
    NSImage *iconImage;
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
    return iconImage;
}

-(NSImage*) _badge {
    // The code below only draw one of the badges in the order the code is presented.
    // TODO:1.4 Consider making an shifted overlay where all the applicable badges are placed
    //         in sequence, starting from right to left
    NSImage *badge = nil;
    if ([self hasTags:tagTreeItemHidden]) {
        badge = [NSImage imageNamed:@"PrivateFolderBadgeIcon"];
    }
    else if ([self hasTags:tagTreeItemReadOnly]) {
        badge = [NSImage imageNamed:@"ReadOnlyFolderBadgeIcon"];
    }
    else if ([self hasTags:tagTreeItemDropped]) {
        badge = [NSImage imageNamed:@"DropFolderBadgeIcon"];
    }
    return badge;
}

-(NSImage*) image {
    NSImage *iconImage;
    NSImage *image;

    iconImage = [self _image];
    NSSize imageSize= [iconImage size];
    //TreeItemTagEnum tags = [self tag];
    image = [NSImage imageWithSize:imageSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [iconImage drawInRect:dstRect];
        
        // Check if there is a badge to be added
        NSImage *badge = [self _badge];
        // If there is a badge, then will apply an overlay
        if (badge) {
            [badge drawInRect:dstRect];
        }
        return YES;
    }];
    return image;
}

-(NSImage*) imageForSize:(NSSize)size {
    NSImage *iconImage;
    NSImage *image;
    
    iconImage = [self _image];
    //TreeItemTagEnum tags = [self tag];
    image = [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [iconImage drawInRect:dstRect];
        
        // Check if there is a badge to be added
        NSImage *badge = [self _badge];
        // If there is a badge, then will apply an overlay
        if (badge) {
            [badge drawInRect:dstRect];
        }
        return YES;
    }];
    return image;
}

-(NSColor*) textColor {
    NSColor *foreground;
    if ([self hasTags:tagTreeItemMarked]) {
        foreground = [NSColor redColor];
    }
    else if ([self hasTags:tagTreeItemDropped+tagTreeItemToMove]) {
        foreground = [NSColor lightGrayColor]; // Sets grey when the file was dropped or moved
    }
    else if ([self hasTags:tagTreeAuthorized]==NO) {
        foreground = [NSColor blueColor]; // Sets a blue color
    }
    else {
        foreground = [NSColor textColor];
    }
    return foreground;
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

// Tree Integration
#pragma mark - Tree Access

-(TreeItem*) root {
    TreeItem *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
    }
    return cursor;
}

-(NSArray*) pathComponents {
    return [self.url pathComponents];
}

-(NSInteger) pathLevel {
    NSUInteger answer = 0;
    TreeItem *cursor = self;
    while (cursor->_parent != nil) {
        answer++;
        cursor=cursor->_parent;
    }
    NSArray *rootPath = [cursor pathComponents];
    answer += [rootPath count];
    
    return answer;
}


/* This routine has two modes of working. 
 If level is negative it uses a relative level reference and descends <level>
 if level is positive, it is an absolute reference */
-(TreeBranch*) parentAtLevel:(NSInteger)level {
    NSLog(@"DEBUG TreeItem.parentAtLevel");
    TreeBranch *cursor = self.parent;
    if (level<0) {
        while (level<0 && cursor!=nil) {
            cursor=cursor.parent;
            level++;
        }
        return cursor; // This will return nil if not found
    }
    else {
        NSInteger l=1;
        while (cursor!=nil) {
            cursor=cursor.parent;
            l++;
        }
        NSArray *rootPath = [cursor pathComponents];
        l += [rootPath count];
        
        if (l>level) return nil;
        l = l-level;
        cursor = self.parent;
        while (l--) {
            cursor = cursor.parent;
        }
        return cursor;
    }
}

/* This function returns the ancester degree to a parent.
 If the answer is negative, then it means that the anscester was not found. */
-(NSInteger) degreeToAncester:(TreeBranch*)ancester {
    NSInteger answer = 0;
    TreeItem *cursor = self;
    do {
        if (cursor == ancester )
            return answer;
        answer++;
        cursor = cursor->_parent;
    } while (cursor);
    return -answer;
}

-(enumPathCompare) relationTo:(TreeItem *)other {
    return pathCompRelation(self.pathComponents, other.pathComponents);
}

-(void) notifyChange {
    if (self->_parent!=nil) {
        [self->_parent willChangeValueForKey:kvoTreeBranchPropertyChildren];
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

-(NSArray*) openWithApplications {
    CFArrayRef appls;
    appls = LSCopyApplicationURLsForURL((__bridge CFURLRef _Nonnull)(self.url),   kLSRolesViewer+kLSRolesEditor );
    NSArray *answer = CFBridgingRelease(appls);
    return answer;
}

-(BOOL) removeItem {
    if (_parent) {
        [_parent removeChild:self];
    }
    [self deinit];
    return YES;
}

// Menu support
// Its the class responding because at this point we only care if
// file answers to it or not. If later the instance can't execute the command,
// the menu will be invalidated.
-(BOOL) respondsToMenuTag:(EnumContextualMenuItemTags)tag {
    BOOL answer;
    switch (tag) {
        case menuInformation:
        case menuOpen:
        case menuRename:
        case menuCopy:
        case menuMove:
        case menuCopyTo:
        case menuMoveTo:
        case menuDelete:
        case menuClipCopy:
        case menuClipCopyName:
        case menuClipCut:
            answer = YES;
            break;
            
        default:
            answer = NO;
    }
    return answer;
}

#pragma mark -
#pragma mark NSPasteboardWriting support


//TODO:1.3.3 Try to pass NSFilenamePboardType to see if drag to recycle bin can be executed
- (NSArray<NSString *> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
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
