//
//  IconCollectionItem.h
//  Caravelle
//
//  Created by Viktoryia Labunets on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IconCollectionItem : NSCollectionViewItem <NSControlTextEditingDelegate>

- (IBAction)doubleClick:(id)sender;
- (IBAction)rightClick:(id)sender;
- (IBAction)filenameDidChange:(id)sender;

@end