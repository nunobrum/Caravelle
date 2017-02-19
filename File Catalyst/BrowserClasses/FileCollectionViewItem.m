//
//  FileCollectionViewItem.m
//  Caravelle
//
//  Created by Nuno Brum on 20/09/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import "FileCollectionViewItem.h"
#import "TreeItem.h"


@interface FileCollectionViewItem ()
@end

@implementation FileCollectionViewItem {
   
}

-(void) formatSelected:(EnumIconFormats) iconFormat {
    if (iconFormat==IconSelected) {
        //[self.view.layer setBorderWidth:1];
        [self.textField setTextColor:[NSColor alternateSelectedControlTextColor]];
        [self.textField setBackgroundColor:[NSColor alternateSelectedControlColor]];
        //[self.imageView setAlphaValue:0.5];
        //[self.imageView.cell setBordered:YES];
        //[self.imageView.cell setFocusRingType:NSFocusRingTypeExterior ];
        //NSLog(@"Selecting %@", self.textField.stringValue);
    }
    else if (iconFormat == IconSelectedInactive) {
        [self.textField setTextColor:[NSColor textColor]];
        [self.textField setBackgroundColor:[NSColor secondarySelectedControlColor]];
    }
    else if (iconFormat == IconInEdition) {
        [self.textField setTextColor:[NSColor textColor]];
        [self.textField setBackgroundColor:[NSColor textBackgroundColor]];
    }
    else {
        [self.textField setEditable:NO];
        //[self.view.layer setBorderWidth:0];
        //[self.imageView setAlphaValue:1];
        //[self.imageView.cell setBordered:NO];
        [self.textField setTextColor:[NSColor textColor]];
        [self.textField setBackgroundColor:[NSColor textBackgroundColor]];
        //NSLog(@"Deselecting %@", self.textField.stringValue);
    }
    self.textField.needsDisplay = YES;
}

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do view setup here.
//    //[self.view setWantsLayer:YES];
//    //[self.textField setNextResponder:self];
//}


-(void) exitEditMode {
    // Revert Colors Back to Normal
    [self formatSelected:(self.isSelected ? IconSelected : IconNotSelected)];
    NSLog(@"exitEditMode");
    // Change the Focus
    [(id<MYViewProtocol>)[[self collectionView] delegate] focusOnFirstView];
}

- (IBAction)filenameDidChange:(id)sender {
    // This is actually not needed. The rename is handled by the Binding
    /*if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(filenameDidChange:)]) {
     [[[self collectionView] delegate] performSelector:@selector(filenameDidChange:) withObject:self];
     }*/
}


-(void) setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected && [(TreeItem*)self.representedObject hasTags:tagTreeItemReadOnly]==NO)
        [self.textField setEditable:YES];
    [self formatSelected:(selected ? IconSelected : IconNotSelected)];
}


/*
 * NSTextFieldDelegate
 */


//// The code below assures that edit of the text is only done when the icon is already selected.
//- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
//    NSLog(@"FileCollectionViewItem.textShouldBeginEditing");
//    return YES;
//}
//
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
//    NSLog(@"textShouldEndEditing");
//    return YES;
//}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(cancelOperation:)) {
        // In cancel will check if it was a new File and if so, remove it
        id item = [self representedObject];
        if ([item isKindOfClass:[TreeItem class]]) {
            if ([(TreeItem*)item hasTags:tagTreeItemNew]) {
                [(TreeItem*)item removeItem];
                
            }
            else {
                // Put old string name
                [control setStringValue:[item name]];
            }
        }
        // Remove Field from First Responder
        [self exitEditMode];
        //return YES; // avoids that the cancelOperation from controller is called.
    }
    else if (commandSelector == @selector(insertNewline:)) {
        // Remove Field from firstResponder
        [self exitEditMode];
    }
    return NO;
}

//-(BOOL) acceptsFirstResponder {
//    return self.isSelected;
//}

//-(BOOL) becomeFirstResponder {
//    if (self.isSelected) {
//        [self formatSelected:IconInEdition];
//    }
//    return self.isSelected;
//}

@end
