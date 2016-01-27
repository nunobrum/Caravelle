//
//  PasteboardUtils.m
//  Caravelle
//
//  Created by Nuno Brum on 16/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"

void DebugPBoard(NSPasteboard*pboard) {
    NSLog(@"PBOARD:%@\n========================================",[pboard name]);
    for (NSString *type in [pboard types]) {
        id pBoardContents = [pboard propertyListForType:type];
        NSLog(@"type:%@, class:%@\n_____________________________________", type, [pBoardContents class]);
        if ([pBoardContents isKindOfClass:[NSString class]]) {
            NSLog(@"String:%@",pBoardContents);
        }
        else if ([pBoardContents isKindOfClass:[NSArray class]]) {
            int i = 1;
            for (id item in pBoardContents) {
                NSLog(@"item %i:%@",i++, item);
            }
        }
        else {
            NSLog(@"unknown:%@",pBoardContents);
        }
    }
}

NSDragOperation supportedOperations(id<NSDraggingInfo> info) {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSDragOperation  supportedMask = NSDragOperationNone;
    NSArray *ptypes;
    
    sourceDragMask = [info draggingSourceOperationMask];
    pboard = [info draggingPasteboard];
    ptypes =[pboard types];

    /* Limit the options in function of the dropped Element */
    // The sourceDragMask should be an or of all the possiblities, and not the only first one.
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

    return supportedMask; // The offered types and the supported types.

}

NSDragOperation selectDropOperation(NSDragOperation dragOperations) {

    NSUInteger modifiers = [NSEvent modifierFlags];
    
    NSDragOperation validatedOperation = NSDragOperationNone;
    

    /* Use the modifiers keys to select */
    //if (modifiers & NSShiftKeyMask) {
    //}
    //TODO:!! Use Space to cycle through the options
    if (modifiers & NSAlternateKeyMask) {
        if (modifiers & NSCommandKeyMask) {
            if      (dragOperations & NSDragOperationLink)
                validatedOperation=  NSDragOperationLink;
            else if (dragOperations & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
        }
        else {
            if      (dragOperations & NSDragOperationCopy)
                validatedOperation=  NSDragOperationCopy;
            else if (dragOperations & NSDragOperationMove)
                validatedOperation=  NSDragOperationMove;
            else if (dragOperations & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
            else
                validatedOperation= NSDragOperationNone;
        }
        //if (modifiers & NSControlKeyMask) {
    }
    else {
        if      (dragOperations & NSDragOperationMove)
            validatedOperation=  NSDragOperationMove;
        else if (dragOperations & NSDragOperationCopy)
            validatedOperation=  NSDragOperationCopy;
        else if (dragOperations & NSDragOperationLink)
            validatedOperation=  NSDragOperationLink;
        else if (dragOperations & NSDragOperationGeneric)
            validatedOperation=  NSDragOperationGeneric;
        else
            validatedOperation= NSDragOperationNone;
    }


    return validatedOperation;
}


extern BOOL writeItemsToPasteboard(NSArray *items, NSPasteboard *pboard, NSArray *types) {
    BOOL answer = NO;
    NSArray *typesDeclared = [types arrayByAddingObjectsFromArray:
                              [[items firstObject] writableTypesForPasteboard:pboard]];
    
    [pboard declareTypes:typesDeclared owner:nil];
    if ([pboard writeObjects:items]==NO) return NO;
    
//    if ([types containsObject:NSURLPboardType] == YES) {
//        NSArray *selectedURLs = [items valueForKeyPath:@"@unionOfObjects.url"];
//        answer |= [pboard setPropertyList:selectedURLs forType:NSURLPboardType];
//    }
    if ([types containsObject:NSFilenamesPboardType] == YES) {
        NSArray *selectedPaths = [items valueForKeyPath:@"@unionOfObjects.path"];
        answer |= [pboard setPropertyList:selectedPaths forType:NSFilenamesPboardType];
    }
    if ([types containsObject:NSStringPboardType] == YES) {
        NSArray* str_representation = [items valueForKeyPath:@"@unionOfObjects.path"];
        // Join the paths, one name per line
        NSString* pathPerLine = [str_representation componentsJoinedByString:@"\n"];
        //Now add the pathsPerLine as a string
        answer |= [pboard setString:pathPerLine forType:NSStringPboardType];
    }
    //Debug
    NSLog(@"Writing to Pasteboard types Declared");
    DebugPBoard(pboard);
    return answer;
}


NSArray *supportedPasteboardTypes() {
    static NSArray* SPT = nil;

    if (SPT == nil) {
        SPT = [NSArray arrayWithObjects:
                          NSURLPboardType,
                          NSFilenamesPboardType,
                          // NSFileContentsPboardType, not passing file contents
                          NSStringPboardType, nil];
    }
    return SPT;
}