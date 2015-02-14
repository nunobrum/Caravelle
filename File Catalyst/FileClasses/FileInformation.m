//
//  FileInformation.m
//  FileCatalyst1
//
//  Created by Nuno Brum on 12/28/12.
//  Copyright (c) 2012 Nuno Brum. All rights reserved.
//

#import "FileInformation.h"


@implementation FileInformation

+(FileInformation *) createWithURL: (NSURL*) theURL {
    FileInformation *ret = [[FileInformation new] init];
    [ret setURL:theURL];
    return ret;
}

-(FileInformation *) init {
    self = [super init];
    if (self) {
        //self->URL = Nil;
        self->name = Nil;
        self->Type = Nil;
        valid_md5 = FALSE;
        duplicate_chain = nil;
        dCounter = 0;
    }
    return self;
}

-(void) setURL:(NSURL*)theURL {
    NSString *filename;
    NSDate  *date;
    NSNumber *size;
    NSString *path0;
    [theURL getResourceValue:&filename forKey:NSURLNameKey error:NULL];
    [theURL getResourceValue:&path0     forKey:NSURLPathKey error:NULL];
    [theURL getResourceValue:&size     forKey:NSURLFileSizeKey error:NULL];
    [theURL getResourceValue:&date     forKey:NSURLContentModificationDateKey error:NULL];
    self->name = filename;
    self->path = path0;
    self->fileSize = size;
    self->dateModified = date;
    //self->URL=theURL;

}
-(NSURL*) getURL {
    return [NSURL fileURLWithPath:self->path isDirectory:NO];
}
-(NSString*) getName {
    return self->name;
}
-(NSString*) getPath {
    return self->path;
}
-(NSArray*) getPathComponents {
    return [self->path pathComponents];
}
-(NSDate*) getDateModified {
    return self->dateModified;
}
-(NSNumber*) getFileSize {
    return self->fileSize;
}

-(BOOL) equalName:(FileInformation *)otherFile {
    return (NSOrderedSame==[self->name compare: otherFile->name]) ? TRUE : FALSE;
}

-(BOOL) equalSize:(FileInformation *)otherFile {
    return (self->fileSize == otherFile->fileSize) ? TRUE : FALSE;

}
-(BOOL) equalDate:(FileInformation *)otherFile {
    return (self->dateModified == otherFile->dateModified) ? TRUE : FALSE;
}

-(NSComparisonResult) compareSize:(FileInformation *)otherFile {
    if (self->fileSize < otherFile->fileSize)
        return NSOrderedAscending;
    else if (self->fileSize > otherFile->fileSize)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
    
}

-(BOOL) compareContents:(FileInformation*)otherFile {
    return [[NSFileManager defaultManager] contentsEqualAtPath:self->path andPath:otherFile->path];
}
//#define BUFFER_SIZE_COMPARE 1024
//-(BOOL) compareContents:(FileInformation*)otherFile {
//    NSData *bufferA;
//    NSData *bufferB;
//    NSUInteger bytes_read;
//    BOOL comparison = TRUE;
//
//    NSFileHandle *fileA = [NSFileHandle fileHandleForReadingAtPath:self->path ];
//    NSFileHandle *fileB = [NSFileHandle fileHandleForReadingAtPath:self->path ];
//    
//    if (fileA!=nil && fileB!=nil) {
//        do  {
//            bufferA = [fileA readDataOfLength:BUFFER_SIZE_COMPARE];
//            bufferB = [fileB readDataOfLength:BUFFER_SIZE_COMPARE];
//            bytes_read = [bufferA length];
//            if ([bufferB length]==bytes_read) {
//                if (0!=memcmp([bufferA bytes], [bufferB bytes], bytes_read)) {
//                    comparison = FALSE;
//                    break;
//                }
//            }
//        } while (bytes_read == BUFFER_SIZE_COMPARE);
//    }
//    [fileA closeFile];
//    [fileB closeFile];
//    return (comparison);
//}

-(BOOL) validMD5 {
    return valid_md5;
}

/* This function will calculate the file checksum based on the MD5 protocol */
#define BUFFER_SIZE_MD5 4096
-(void) calculateMD5 {
    NSData *NSbuffer;
	md5_state_t state;
	md5_byte_t digest[16];
    md5_byte_t *data_pointer;
    NSUInteger bytes_read;
    
	char hex_output[16*2 + 1];
	int di;
    
    NSFileHandle *handler = [NSFileHandle fileHandleForReadingAtPath:self->path];
    
    if (handler!=nil) {
        
        md5_init(&state);
        
        do  {
            NSbuffer = [handler readDataOfLength:BUFFER_SIZE_MD5];
            bytes_read = [NSbuffer length];
            data_pointer = (md5_byte_t *)[NSbuffer bytes];
            md5_append(&state, data_pointer, (int)bytes_read); // Potential dangerous cast since it is converting from unsigned long to int, mind size declared in BUFFER_SIZE
            
        } while (bytes_read == BUFFER_SIZE_MD5);
        md5_finish(&state, digest);
    }
	for (di = 0; di < 16; ++di)
	    sprintf(hex_output + di * 2, "%02x", digest[di]);
    memcpy(&self->md5_checksum, digest, 16);
    valid_md5 = TRUE;
    //NSLog(@"%s",hex_output);
    [handler closeFile];
}

-(BOOL) compareMD5checksum: (FileInformation *)otherFile {
    int i;
    if (!valid_md5)
        [self calculateMD5];
    if (!otherFile->valid_md5)
        [otherFile calculateMD5];
    
    for (i=0; i<16; i++)
        if (self->md5_checksum[i]!=otherFile->md5_checksum[i]) {
            return FALSE;
        }
    return TRUE;
}

// The duplicates are organized on a ring fashion for memory space efficiency
// FileA -> FileB -> FileC-> FileA
-(void) addDuplicate:(FileInformation*)duplicateFile {
    if (duplicate_chain==nil)
    {
        self->duplicate_chain = duplicateFile;
        duplicateFile->duplicate_chain = self;
    }
    else {
        duplicateFile->duplicate_chain = self->duplicate_chain;
        self->duplicate_chain = duplicateFile;
    }
}

-(BOOL) hasDuplicates {
    return (self->duplicate_chain==nil ? NO : YES);
}

-(NSUInteger) duplicateCount {
    if (duplicate_chain==nil)
        return 0;
    else
    {
        FileInformation *cursor=self->duplicate_chain;
        int count =0;
        while (cursor!=self) {
            cursor = cursor->duplicate_chain;
            count++;
        }
        return count;
    }
}
-(NSMutableArray*) duplicateList {
    if (duplicate_chain==nil)
        return nil;
    else
    {
        FileInformation *cursor=self->duplicate_chain;
        NSMutableArray *answer =[[NSMutableArray new]init];
        while (cursor!=self) {
            [answer addObject:cursor];
            cursor = cursor->duplicate_chain;
        }
        return answer;
    }
}

-(void) removeFromDuplicateRing {
    if (self->duplicate_chain!=nil)
    {
        FileInformation *cursor=self->duplicate_chain;
        if (cursor == self->duplicate_chain) // In case if only one duplicate
            cursor->duplicate_chain = nil;   // Deletes the chain
        else {
            while (cursor->duplicate_chain!=self) { // searches for the file that references this one
                cursor = cursor->duplicate_chain;
            }
            cursor->duplicate_chain = self->duplicate_chain; // and bypasses this one
        }
    }
}

-(void) resetDuplicates {
    FileInformation *cursor=self;
    FileInformation *tmp=self;
    while (cursor->duplicate_chain!=nil) {
        tmp = cursor;
        cursor = cursor->duplicate_chain;
        tmp->duplicate_chain = nil;
    }
}


-(BOOL) sendToRecycleBin {
    BOOL remove_sucess = [[NSFileManager defaultManager] removeItemAtPath:self->path error:nil];
    // Must delete the file from the duplicate
    if (remove_sucess) {
        [self removeFromDuplicateRing];
    }
    return remove_sucess;
}

-(BOOL) eraseFile {
    // Missing implementation
    NSLog(@"Erase File Method not implemented");
    return NO;
}
-(BOOL) copyFileTo:(NSString *)path {
    // Missing implementation
    NSLog(@"Copy File Method not implemented");
    return NO;
}
-(BOOL) moveFileTo:(NSString *)path {
    // Missing implementation
    NSLog(@"Move File Method not implemented");
    return NO;
}

-(BOOL) openFile {
    [[NSWorkspace sharedWorkspace] openFile:self->path];
    return YES;
}

@end
