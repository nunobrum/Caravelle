//
//  IconViewBox.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IconViewBox : NSBox {
    IBOutlet id delegate;
}

-(void)mouseDown:(NSEvent *)theEvent;

@end
