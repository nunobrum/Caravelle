//
//  BrowserIconView.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IconViewBox.h"

@interface BrowserIconView : NSCollectionView

-(IconViewBox*) iconWithItem:(id) item;

@end
