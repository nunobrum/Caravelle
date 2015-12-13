//
//  CRVLItem.m
//  Caravelle
//
//  Created by Nuno Brum on 12/31/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "CRVLItem.h"
#import "TreeBranch.h"
#import "TreePackage.h"
#import "TreeManager.h"
#import "FileUtils.h"
#import "DuplicateInformation.h"



@implementation CRVLItem


-(NSInteger)itemCount { return 1; }
-(BrowserItemPointer)itemAtIndex:(NSUInteger)index { return nil; }

-(NSMutableArray*) itemsInNode {
    return nil;
}

-(NSMutableArray*) itemsInNodeWithPredicate:(NSPredicate *)filter {
    return nil;
}

-(NSMutableArray*) itemsInBranchTillDepth:(NSInteger)depth {
    return nil;
}

-(NSMutableArray*) itemsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    return nil;
}

-(NSInteger)nodeCount { return 1; }
-(BrowserItemPointer)nodeAtIndex:(NSUInteger)index { return nil; }
-(NSMutableArray*) nodesInNode {
    return nil;
}

-(NSInteger) leafCount {
    return 0;
}

-(CRVLItem*) leafAtIndex:(NSUInteger) index {
    return nil;
}


-(NSMutableArray*) leafsInNode {
    return nil;
}

// This returns the number of leafs in a branch
// this function is recursive to all sub branches
-(NSInteger) numberOfLeafsInBranch {
    return 0;
}

-(NSMutableArray*) leafsInNodeWithPredicate:(NSPredicate *)filter {
    return nil;
}


-(NSMutableArray*) leafsInBranchTillDepth:(NSInteger)depth {
    return nil;
}

-(NSMutableArray*) leafsInBranchWithPredicate:(NSPredicate*)filter depth:(NSInteger)depth {
    return nil;
}



-(BOOL) needsRefresh { return NO; }
-(void)refresh {}

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
    if ([self hasTag:attrViewNew]) {
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


-(NSImage*) image {
    NSImage *iconImage;
    NSImage *image;
    
    // First get the image
    if ([self hasTag:attrViewNew] || self.url==nil) {
        if ([self isFolder])
            iconImage = [NSImage imageNamed:@"GenericFolderIcon"];
        else
            iconImage = [NSImage imageNamed:@"GenericDocumentIcon"];
    }
    else  {
        iconImage =[[NSWorkspace sharedWorkspace] iconForFile: [_url path]];
    }
    
    
    NSSize imageSize= [iconImage size];
    //attrViewTagEnum tags = [self tag];
    image = [NSImage imageWithSize:imageSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        [iconImage drawInRect:dstRect];
        
        // Then will apply an overlay
        // The code below only draw one of the badges in the order the code is presented.
        // TODO: ! Consider making an shifted overlay where all the applicable badges are placed
        //         in sequence, starting from right to left
        if ([self hasTag:attrViewHidden]) {
            [[NSImage imageNamed:@"PrivateFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ private", [self url]);
        }
        else if ([self hasTag:attrViewReadOnly]) {
            [[NSImage imageNamed:@"ReadOnlyFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ read-only", [self url]);
        }
        else if ([self hasTag:attrViewDropped]) {
            [[NSImage imageNamed:@"DropFolderBadgeIcon"] drawInRect:dstRect];
            //NSLog(@"%@ dropped", [self url]);
        }
        return YES;
    }];
    return image;
}

-(NSString*) hint {
    return [self name];
}

-(attrViewTagEnum) tag {
    return _tag;
}

-(void) setTag:(attrViewTagEnum)tags {
    _tag |= tags;
}
-(void) resetTag:(attrViewTagEnum)tags {
    _tag &= ~tags;
}

-(BOOL) hasTag:(attrViewTagEnum) tag {
    return (_tag & tag)!=0 ? YES : NO;
}

-(void) toggleTag:(attrViewTagEnum)tags {
    _tag ^= tags;
}


-(ItemType) itemType {
    return ItemTypeNone;
}

-(BOOL) isExpandable { return NO; }
-(BOOL) needsSizeCalculation { return NO; }
-(BOOL) isGroup { return NO; }
-(BOOL) isFolder {
    return [self itemType] < ItemTypeLeaf;
}
-(BOOL) hasChildren { // has physical children but does not display as folders.
    return NO;
}

-(NSArray*) children {
    return nil;
}

-(id)   hashObject {
    return _url;
}

-(BOOL) isLeaf {
    return [self itemType] >= ItemTypeLeaf;
}


-(instancetype) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super init];
    if (self) {
        self->_tag = 0;
        [self setUrl:url];
        self->_parent = parent;
        self.nameCache = nil;
    }
    return self;
}

-(instancetype) initWithMDItem:(NSMetadataItem*)mdItem parent:(id)parent {
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    return [self initWithURL: [NSURL fileURLWithPath:path] parent:parent];
 }


+(id) CRVLItemForURL:(NSURL *)url parent:(id)parent {
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
                    return [[TreeLeaf alloc] initWithURL:url parent:parent];
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
                return [[CRVLFile alloc] initWithURL:url parent:parent];
            }
            return [[CRVLFile alloc] initWithURL:url parent:parent];
        }
    }
    return nil;
}

+(id)CRVLItemForMDItem:(NSMetadataItem *)mdItem parent:(id)parent {
    // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
    //NSString *typeIdentifier = [mdItem valueForAttribute:(id)kMDItemContentType];
    NSString *path = [mdItem valueForAttribute:(id)kMDItemPath];
    NSURL *url = [NSURL fileURLWithPath:path];
    id answer = [self CRVLItemForURL:url parent:parent];
    return answer;
}

+(id) createFromPastedObject:(id)object {
    // Only creates from URLs for the time being
    if ([object isKindOfClass:[NSURL class]]) {
        return [self CRVLItemForURL:object parent:self];
    }
    return nil;
}


-(void) setUrl:(NSURL*)url {
    // The tags shoud be set here accordingly to the information got from URL
    // TODO: When the Icon View is changed to a data Delegate model instead of the ArrayController, the "name" notification can be removed.
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



-(void) updateFileTags {
    _tag &= ~attrViewDirty;
    if (isWritable(_url))
        _tag &= ~attrViewReadOnly;
    else
        _tag |= attrViewReadOnly;
    
    if (isHidden(_url))
        _tag |= attrViewHidden;
    else
        _tag &= ~attrViewHidden;
    
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




-(NSNumber*) exactSize {
    NSNumber *exactSize;
    [_url getResourceValue:&exactSize     forKey:NSURLFileSizeKey error:NULL];
    return exactSize;
}

-(NSNumber*) allocatedSize {
    NSNumber *allocatedSize;
    [_url getResourceValue:&allocatedSize     forKey:NSURLFileAllocatedSizeKey error:NULL];
    return allocatedSize;
}

-(NSNumber*) totalSize {
    NSNumber *totalSize;
    [_url getResourceValue:&totalSize     forKey:NSURLTotalFileSizeKey error:NULL];
    return totalSize;
}

-(NSNumber*) totalAllocatedSize {
    NSNumber *totalAllocatedSize;
    [_url getResourceValue:&totalAllocatedSize     forKey:NSURLTotalFileAllocatedSizeKey error:NULL];
    return totalAllocatedSize;
}

-(NSString*) fileKind {
    NSString *kind;
    [_url getResourceValue:&kind     forKey:NSURLLocalizedTypeDescriptionKey error:NULL];
    return kind;
}




-(instancetype) root {
    CRVLItem *cursor = self;
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
    CRVLItem *cursor = self;
    while (cursor->_parent!=NULL) {
        cursor=cursor->_parent;
        [answer insertObject:cursor atIndex:0];
    }
    return answer;
}

-(NSArray *) treeComponentsToParent:(id)parent {
    NSMutableArray *answer = [NSMutableArray arrayWithObject:self];
    CRVLItem *cursor = self;
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
    [self setTag:attrViewRelease];
    return YES;
}

#pragma mark -
#pragma mark URL comparison methods

-(enumPathCompare) relationToPath:(NSString*) otherPath {
    return path_relation([self path], otherPath);
}

-(enumPathCompare) compareTo:(CRVLItem*) otherItem {
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
        return [CRVLItem CRVLItemForURL:url parent:nil];
    }
}


#pragma mark - Pasteboard Drop support

-(NSDragOperation) supportedDragOperations:(id<NSDraggingInfo>)info {
    
    NSDragOperation sourceDragMask = [info draggingSourceOperationMask];
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *ptypes =[pboard types];
    /* Limit the options in function of the dropped Element */
    // The sourceDragMask should be an or of all the possiblities, and not the only first one.
    NSDragOperation  supportedMask = NSDragOperationNone;
    
    if ( [ptypes containsObject:NSFilenamesPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    if ( [ptypes containsObject:(id)NSURLPboardType] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
    else if ( [ptypes containsObject:(id)kUTTypeFileURL] ) {
        supportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#ifdef USE_UTI
    else if ( [ptypes containsObject:(id)kTreeItemDropUTI] ) {
        suportedMask |= ( NSDragOperationCopy + NSDragOperationLink + NSDragOperationMove);
    }
#endif
    
    sourceDragMask &= supportedMask; // The offered types and the supported types.
    
    /* Limit the Operations depending on the Destination Item Class*/
    if ([self isFolder]) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    }
    else if ([self isFolder]==NO) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        sourceDragMask = NSDragOperationNone;
    }
    return sourceDragMask;
}

-(NSArray*) acceptDropped:(id<NSDraggingInfo>)info operation:(NSDragOperation)operation sender:(id)fromObject {
    BOOL fireNotfication = NO;
    NSString const *strOperation;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];
    
    if ([self isFolder]==NO) {
        // TODO: !! Dropping Application on top of file or File on top of Application
        NSLog(@"BrowserController.acceptDrop: - Not impplemented Drop on Files");
        // TODO:! IDEA Maybe an append/Merge/Compare can be done if overlapping two text files
    }
    else {
        if (operation == NSDragOperationCopy) {
            strOperation = opCopyOperation;
            fireNotfication = YES;
        }
        else if (operation == NSDragOperationMove) {
            strOperation = opMoveOperation;
            fireNotfication = YES;
            
            // Check whether the destination item is equal to the parent of the item do nothing
            for (NSURL* file in files) {
                NSURL *folder = [file URLByDeletingLastPathComponent];
                if ([[self path] isEqualToString:[folder path]]) // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
                {
                    // If true : abort
                    return nil;
                }
            }
        }
        else if (operation == NSDragOperationLink) {
            // TODO: !!! Operation Link
        }
        else {
            // Invalid case
            fireNotfication = NO;
        }
        
    }
    if (fireNotfication==YES) {
        // The copy and move operations are done in the AppDelegate
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kDFOFilesKey,
                              strOperation, kDFOOperationKey,
                              self, kDFODestinationKey,
                              //fromObject, kFromObjectKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:fromObject userInfo:info];
        return files;
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)operation);
    return nil;
}

#pragma mark - Coding Compliant

/*
 * Coding Compliant methods
 */
-(void) setValue:(id)value forUndefinedKey:(NSString *)key {

    NSLog(@"CRVLItem.setValue:forUndefinedKey: Trying to set value for Key %@", key);
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
