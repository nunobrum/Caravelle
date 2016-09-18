//
//  OperationManager.m
//  Caravelle
//
//  Created by Nuno on 07/05/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "OperationManager.h"
#import "Definitions.h"
#import "TreeItem.h"

@implementation OperationManager

-(instancetype) init {
    self = [super init];
    self->_executedOperations=nil;
    return self;
}


-(void) completeOperation:(NSMutableDictionary*)operationInfo {
    // adds the completed operation to the executed operation
    if (self->_executedOperations==nil) self->_executedOperations = [NSMutableArray array];
    [self->_executedOperations addObject:operationInfo];
    
}

-(NSMutableDictionary*) makeUndoOperation {
    NSMutableDictionary *opToUndo = [self->_executedOperations lastObject];
    NSMutableDictionary *taskInfo;
    
    NSString *opCode = opToUndo[kDFOOperationKey];
    
    if ([opCode isEqualTo:opCopyOperation]) {
        // Delete destination address
        taskInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    opSendRecycleBinOperation, kDFOOperationKey,
                    opToUndo[kDFOFilesKey], kDFOFilesKey,
                    nil];
        
    } else  if([opCode isEqualTo:opMoveOperation]){
        // Move From destination to Source
        NSMutableArray *files = opToUndo[kDFOFilesKey];
        id destItem = opToUndo[kDFODestinationKey];
        NSURL *destURL = getURL(destItem);
        
        for (NSUInteger i=0; i < files.count; i++) {
            NSURL *url =getURL(files[i]);
            
            NSURL *sourceURL = [destURL URLByAppendingPathComponent:url.lastPathComponent];
            files[i] = sourceURL;
        }
        taskInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    opMoveOperation, kDFOOperationKey,
                    files, kDFOFilesKey,
                    destURL, kDFODestinationKey,
                    nil];
    }
    else if ([opCode isEqual:opNewFolder]) {
        // Erase Created Folder
        NSString *newName = [taskInfo objectForKey:kDFORenameFileKey];
        id destObj = [taskInfo objectForKey:kDFODestinationKey];
        NSURL *parentURL = getURL(destObj);
        
        NSURL *folderToDelete = [parentURL URLByAppendingPathComponent:newName isDirectory:YES];
        taskInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    opSendRecycleBinOperation, kDFOOperationKey,
                    @[folderToDelete], kDFOFilesKey,
                    nil];
    }
    else if ([opCode isEqual:opRename]) {
        // Erase Created Folder
        NSString *newName = [taskInfo objectForKey:kDFORenameFileKey];
        id destObj = [taskInfo objectForKey:kDFODestinationKey];
        NSURL *parentURL = getURL(destObj);
        
        NSURL *fileToRename = [parentURL URLByAppendingPathComponent:newName];
        NSString *originalName;
        id orig = taskInfo[kDFOFilesKey];
        if ([orig isKindOfClass:[TreeItem class]])
            originalName = [(TreeItem*)orig name];
        else
            originalName = [(NSURL*)orig lastPathComponent];
        
        taskInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    opRename, kDFOOperationKey,
                    @[fileToRename], kDFOFilesKey,
                    originalName, kDFORenameFileKey,
                    nil];
    }
    else if ([opCode isEqual:opSendRecycleBinOperation]) {
        // Move from Recycle bin back to original location
    }
    else {
        /* All other operations can't be undone.
         opEraseOperation;
         opReplaceOperation;
         */
        taskInfo = nil;
    }
    return taskInfo;
}

@end
