//
//  TreeLeaf.m
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeLeaf.h"
#import "DuplicateInformation.h"

// TODO:!!? Store this in the NSURL instead of _store


const NSString *keyDuplicateInfo = @"TStoreDuplicateKey";
//const NSString *keyMD5Info       = @"TStoreMD5Key";
//const NSString *keyDupRefresh    = @"TStoreDupRefreshKey";

@implementation TreeLeaf

-(TreeLeaf*) initWithURL:(NSURL*)url parent:(id)parent {
    self = [super initWithURL:url parent:parent];
    if (self) {
        self->_store = nil;
    }
    return self;
}

-(ItemType) itemType {
    return ItemTypeLeaf;
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

-(TreeLeaf*) nextDuplicate {
    DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
    if (dupInfo)
        return [dupInfo nextDuplicate];
    else
        return nil;
}

-(void) setNextDuplicate:(TreeLeaf*) item {
    if (item==nil) {
        // It will remove the current duplicate, if exists
        [self->_store removeObjectForKey:keyDuplicateInfo];
    }
    else {
        // Get nextDuplicate and create it if Needed
        DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
        if (dupInfo == nil) {
            dupInfo = [self startDuplicateInfo];
        }
        [dupInfo setNextDuplicate:item];
    }
}

// The duplicates are organized on a ring fashion for memory space efficiency
// FileA -> FileB -> FileC-> FileA
-(void) addDuplicate:(TreeLeaf*)duplicateFile {
    if ([self nextDuplicate]==nil)
    {
        [self setNextDuplicate: duplicateFile];
        [duplicateFile setNextDuplicate: self];
    }
    else {
        [duplicateFile setNextDuplicate: [self nextDuplicate]];
        [self setNextDuplicate: duplicateFile];
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
        TreeLeaf *cursor=self.nextDuplicate;
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
        TreeLeaf *cursor=self.nextDuplicate;
        NSMutableArray *answer =[[NSMutableArray new]init];
        while (cursor!=self) {
            [answer addObject:cursor];
            cursor = cursor.nextDuplicate;
        }
        return answer;
    }
}

-(void) removeFromDuplicateRing {
    if (self.nextDuplicate!=nil)
    {
        TreeLeaf *cursor=self.nextDuplicate;
        if (cursor.nextDuplicate == self) { // In case if only one duplicate
            [cursor setNextDuplicate: nil];   // Deletes the chain
        }
        else {
            while (cursor.nextDuplicate!=self) { // searches for the file that references this one
                cursor = cursor.nextDuplicate;
            }
            [cursor setNextDuplicate: self.nextDuplicate]; // and bypasses this one
        }
        [self setNextDuplicate:nil];
    }
}

-(void) resetDuplicates {
    TreeLeaf *cursor=self;
    while (cursor.duplicateInfo!=nil) {
        TreeLeaf *tmp = cursor;
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

-(BOOL) compareMD5checksum: (TreeLeaf *)otherFile {
    DuplicateInformation *myDupInfo = [self duplicateInfo];
    DuplicateInformation *otherDupInfo = [otherFile duplicateInfo];
    
    if (myDupInfo    == nil)
        myDupInfo = [self startDuplicateInfo];
    if (otherDupInfo == nil)
        otherDupInfo = [otherFile startDuplicateInfo];
    
    if (myDupInfo->valid_md5 == NO)
        calculateMD5(self->_url, myDupInfo->md5_checksum);
    if (otherDupInfo->valid_md5 == NO)
        calculateMD5(self->_url, otherDupInfo->md5_checksum);
    
    int res = memcmp(myDupInfo->md5_checksum, otherDupInfo->md5_checksum, 16);
    return  res==0 ? YES : NO;
}


@end
