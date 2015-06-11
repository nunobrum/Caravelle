//
//  IconCollectionItem.m
//  Caravelle
//
//  Created by Nuno Brum on 09/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "Definitions.h"
#import "IconCollectionItem.h"
#import "TreeItem.h"

@interface IconCollectionItem ()

@end

@implementation IconCollectionItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void) prepareForEdit {
    // Revert Colors Back to Normal
    [[self.iconView name] setTextColor:[NSColor controlTextColor]];

}

-(void) exitEditMode {
    // Revert Colors Back to Normal
    [[self.iconView name] setTextColor:[NSColor alternateSelectedControlTextColor]];

    // Change the Focus
    [(id<MYViewProtocol>)[[self collectionView] delegate] focusOnFirstView];
}

- (IBAction)filenameDidChange:(id)sender {
    // This is actually not needed. The rename is handled by the Binding
    /*if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(filenameDidChange:)]) {
        [[[self collectionView] delegate] performSelector:@selector(filenameDidChange:) withObject:self];
    }*/
}

// NSControlTextEditingDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    //NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        // In cancel will check if it was a new File and if so, remove it
        id item = [self representedObject];
        if ([item isKindOfClass:[TreeItem class]]) {
            if ([(TreeItem*)item hasTags:tagTreeItemNew]) {
                [(TreeItem*)item removeItem];

            }
        }
        // Remove Field from First Responder
        [self exitEditMode];
        return YES; // avoids that the cancelOperation from controller is called.
    }
    else if (commandSelector == @selector(insertNewline:)) {
        // Remove Field from firstResponder
        [self exitEditMode];
    }
    return NO;
}



@end
