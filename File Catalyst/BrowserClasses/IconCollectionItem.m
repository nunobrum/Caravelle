//
//  IconCollectionItem.m
//  Caravelle
//
//  Created by Viktoryia Labunets on 09/04/15.
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


- (IBAction) doubleClick:(id)sender {
    //NSLog(@"double click in the collectionItem");
    if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
        [[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
    }
}

- (IBAction)rightClick:(id)sender {
    if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(rightClick:)]) {
        [[[self collectionView] delegate] performSelector:@selector(rightClick:) withObject:self];
    }
}
- (IBAction)filenameDidChange:(id)sender {
    NSLog(@"Filename Did Change");
    if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(filenameDidChange:)]) {
        [[[self collectionView] delegate] performSelector:@selector(filenameDidChange:) withObject:self];
    }
}

// NSControlTextEditingDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        // In cancel will check if it was a new File and if so, remove it
        id item = [self representedObject];
        if ([item isKindOfClass:[TreeItem class]]) {
            if ([(TreeItem*)item hasTags:tagTreeItemNew]) {
                // TODO: !!!! Delete the Created Icon

            }
        }
        // Remove Field from First Responder
        [(id<MYViewProtocol>)[[self collectionView] delegate] focusOnFirstView];
    }
    else if (commandSelector == @selector(insertNewline:)) {
        // Remove Field from firstResponder
        [(id<MYViewProtocol>)[[self collectionView] delegate] focusOnFirstView];
    }
    return NO;
}
/*
- (BOOL)control:(NSControl *)control
textShouldBeginEditing:(NSText *)fieldEditor {
    return YES;
}

- (BOOL)control:(NSControl *)control
textShouldEndEditing:(NSText *)fieldEditor {
    return YES;
}*/

@end
