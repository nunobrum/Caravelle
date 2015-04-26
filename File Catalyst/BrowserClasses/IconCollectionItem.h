//
//  IconCollectionItem.h
//  Caravelle
//
//  Created by Nuno Brum on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IconViewBox.h"

@interface IconCollectionItem : NSCollectionViewItem

@property (strong) IBOutlet IconViewBox *iconView;


- (IBAction)doubleClick:(id)sender;
- (IBAction)rightClick:(id)sender;
- (IBAction)filenameDidChange:(id)sender;

-(void) prepareForEdit;
-(void) exitEditMode;

@end
