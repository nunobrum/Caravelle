//
//  PasteboardUtils.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 16/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#ifndef Caravelle_PasteboardUtils_h
#define Caravelle_PasteboardUtils_h

extern NSDragOperation validateDrop(id<NSDraggingInfo> info,  TreeItem* destItem);
extern BOOL acceptDrop(id < NSDraggingInfo > info, TreeItem* destItem, NSDragOperation operation, id fromObject);

extern BOOL writeItemsToPasteboard(NSArray *items, NSPasteboard *pboard, NSArray *types);

extern NSArray* supportedPasteboardTypes();

#endif
