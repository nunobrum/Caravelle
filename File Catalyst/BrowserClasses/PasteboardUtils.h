//
//  PasteboardUtils.h
//  Caravelle
//
//  Created by Nuno Brum on 16/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#ifndef Caravelle_PasteboardUtils_h
#define Caravelle_PasteboardUtils_h

extern NSDragOperation supportedOperations(id<NSDraggingInfo> info);

extern void DebugPBoard(NSPasteboard*pboard);

extern NSDragOperation selectDropOperation(NSDragOperation dragOperations);

extern BOOL writeItemsToPasteboard(NSArray *items, NSPasteboard *pboard, NSArray *types);

extern NSArray* supportedPasteboardTypes();

#endif
