//
//  FileCollectionViewItem.h
//  Caravelle
//
//  Created by Nuno Brum on 20/09/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    IconNotSelected,
    IconSelected,
    IconSelectedInactive,
    IconInEdition,
} EnumIconFormats;

@interface FileCollectionViewItem : NSCollectionViewItem <NSTextFieldDelegate>

- (IBAction)filenameDidChange:(id)sender;

-(void) exitEditMode;

-(void) formatSelected:(EnumIconFormats) iconFormat;

@end
