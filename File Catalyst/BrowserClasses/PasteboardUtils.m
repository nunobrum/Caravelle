//
//  PasteboardUtils.m
//  Caravelle
//
//  Created by Nuno Brum on 16/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "TreeItem.h"

NSDragOperation validateDrop(id<NSDraggingInfo> info,  TreeItem* destItem) {

    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSDragOperation  supportedMask = NSDragOperationNone;
    NSDragOperation validatedOperation;
    NSArray *ptypes;
    NSUInteger modifiers = [NSEvent modifierFlags];

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

    sourceDragMask &= supportedMask; // The offered types and the supported types.


    /* Limit the Operations depending on the Destination Item Class*/
    if ([destItem isFolder]) {
        sourceDragMask &= (NSDragOperationMove + NSDragOperationCopy + NSDragOperationLink);
    }
    else if ([destItem isLeaf]) {
        sourceDragMask &= (NSDragOperationGeneric);
    }
    else {
        sourceDragMask = NSDragOperationNone;
    }

    /* Use the modifiers keys to select */
    //if (modifiers & NSShiftKeyMask) {
    //}
    //TODO:!! Use Space to cycle through the options
    if (modifiers & NSAlternateKeyMask) {
        if (modifiers & NSCommandKeyMask) {
            if      (sourceDragMask & NSDragOperationLink)
                validatedOperation=  NSDragOperationLink;
            else if (sourceDragMask & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
        }
        else {
            if      (sourceDragMask & NSDragOperationCopy)
                validatedOperation=  NSDragOperationCopy;
            else if (sourceDragMask & NSDragOperationMove)
                validatedOperation=  NSDragOperationMove;
            else if (sourceDragMask & NSDragOperationGeneric)
                validatedOperation=  NSDragOperationGeneric;
            else
                validatedOperation= NSDragOperationNone;
        }
        //if (modifiers & NSControlKeyMask) {
    }
    else {
        if      (sourceDragMask & NSDragOperationMove)
            validatedOperation=  NSDragOperationMove;
        else if (sourceDragMask & NSDragOperationCopy)
            validatedOperation=  NSDragOperationCopy;
        else if (sourceDragMask & NSDragOperationLink)
            validatedOperation=  NSDragOperationLink;
        else if (sourceDragMask & NSDragOperationGeneric)
            validatedOperation=  NSDragOperationGeneric;
        else
            validatedOperation= NSDragOperationNone;
    }

    // TODO:!!! Implement the Link Operation
    if (validatedOperation ==  NSDragOperationLink)
        validatedOperation=  NSDragOperationNone;

    return validatedOperation;
}

BOOL acceptDrop(id < NSDraggingInfo > info, TreeItem* destItem, NSDragOperation operation, id fromObject) {
    BOOL fireNotfication = NO;
    NSString const *strOperation;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files = [pboard readObjectsForClasses:[NSArray arrayWithObjects:[NSURL class], nil] options:nil];

    if ([destItem isLeaf]) {
        // TODO: !! Dropping Application on top of file or File on top of Application
        NSLog(@"BrowserController.acceptDrop: - Not impplemented Drop on Files");
        // TODO:! IDEA Maybe an append/Merge/Compare can be done if overlapping two text files
    }
    else if ([destItem isFolder]) {
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
                if ([[destItem path] isEqualToString:[folder path]]) // Avoiding NSURL isEqualTo: since it can cause problems with bookmarked URLs
                {
                    // If true : abort
                    fireNotfication = NO;
                    return fireNotfication;
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
                              destItem, kDFODestinationKey,
                              //fromObject, kFromObjectKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:fromObject userInfo:info];
    }
    else
        NSLog(@"BrowserController.acceptDrop: - Unsupported Operation %lu", (unsigned long)operation);
    return fireNotfication;
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