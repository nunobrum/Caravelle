//
//  TreeLeaf.m
//  Caravelle
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeLeaf.h"
#import "DuplicateInformation.h"


const NSString *keyDuplicateInfo = @"TStoreDuplicateKey";
const NSString *keyMD5Info       = @"TStoreMD5Key";
const NSString *keyDupRefresh    = @"TStoreDupRefreshKey";

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

-(NSData*) MD5 {
    // First Check in the MD5 Key Store
    NSData *MD5 = [self->_store objectForKey:keyMD5Info];
    if (MD5==nil) {
        // Then tries the duplicate Info
        DuplicateInformation *dupInfo = [self->_store objectForKey:keyDuplicateInfo];
        if (dupInfo) {
            MD5 = dupInfo.getMD5;
        }
        else {
            MD5 = calculateMD5(self->_url);
            /// Stores it
            [self addToStore:[NSDictionary dictionaryWithObjectsAndKeys:MD5, keyMD5Info, nil]];
        }
    }
    return MD5;
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


-(BOOL) compareMD5checksum: (TreeLeaf *)otherFile {
    NSData *myMD5 = [self MD5];
    NSData *otherMD5 = [otherFile MD5];
    return  [myMD5 isEqualToData:otherMD5];
}

-(TreeLeaf*) nextDuplicate {
    return [self->_store objectForKey:keyDuplicateInfo];
}

-(void) setNextDuplicate:(TreeLeaf*) item {
    if (item==nil) {
        // It will remove the current duplicate, if exists
        [self->_store removeObjectForKey:keyDuplicateInfo];
        // and also removes the refreshCount
        [self->_store removeObjectForKey:keyDupRefresh];
    }
    else {
        [self addToStore: [NSDictionary dictionaryWithObjectsAndKeys:item, keyDuplicateInfo, nil]];
    }
}

// The duplicates are organized on a ring fashion for memory space efficiency
// FileA -> FileB -> FileC-> FileA
-(void) addDuplicate:(TreeLeaf*)duplicateFile {
    [self setTag:tagTreeItemDuplicate];
    if (self.nextDuplicate==nil)
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
    return (self.nextDuplicate==nil ? NO : YES);
}

-(NSUInteger) duplicateCount {
    if (self.nextDuplicate==nil)
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
        if (cursor == self.nextDuplicate) // In case if only one duplicate
            [cursor setNextDuplicate: nil];   // Deletes the chain
        else {
            while (cursor.nextDuplicate!=self) { // searches for the file that references this one
                cursor = cursor.nextDuplicate;
            }
            [cursor setNextDuplicate: self.nextDuplicate]; // and bypasses this one
        }
    }
}

-(void) resetDuplicates {
    TreeLeaf *cursor=self;
    TreeLeaf *tmp=self;
    while (cursor.nextDuplicate!=nil) {
        tmp = cursor;
        cursor = cursor.nextDuplicate;
        [tmp setNextDuplicate: nil]; // Deletes the nextDuplicate AND refreshCount
    }
    [self resetTag:tagTreeItemDuplicate];
}

-(void) setDuplicateRefreshCount:(NSInteger)count {
    [self addToStore: [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInteger:count ], keyDupRefresh, nil]];
}

-(NSInteger) duplicateRefreshCount {
    return [[self->_store objectForKey:keyDupRefresh] integerValue];
}


@end
