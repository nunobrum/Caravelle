//
//  PasteboardUtils.m
//  Caravelle
//
//  Created by Nuno Brum on 16/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"

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
    NSArray *typesDeclared;

    if ([types containsObject:NSURLPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSURLPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedURLs = [items valueForKeyPath:@"@unionOfObjects.url"];
        return [pboard writeObjects:selectedURLs];
    }
    else if ([types containsObject:NSFilenamesPboardType] == YES) {
        typesDeclared = [NSArray arrayWithObject:NSFilenamesPboardType];
        [pboard declareTypes:typesDeclared owner:nil];
        NSArray *selectedURLs = [items valueForKeyPath:@"@unionOfObjects.url"];
        NSArray *selectedPaths = [selectedURLs valueForKeyPath:@"@unionOfObjects.path"];
        return [pboard writeObjects:selectedPaths];
    }
    return NO;
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