//
//  RenameFileDialog.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 13/01/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "RenameFileDialog.h"

@interface RenameFileDialog () 

@end

@implementation RenameFileDialog

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

/* NSTextFieldDelegate Notifications and Delegates */

//- (void)textDidEndEditing:(NSNotification *)aNotification {
//    if ([aNotification object]==_ebFilename) {
//       [self RenameAction:nil];
//    }
//}


//- (void)controlTextDidEndEditing:(NSNotification *)obj {
//    id object = [obj object];
//    if (object == _ebRenameHead || object == _ebRenameExtension) {
//        // Should validate and close the rename dialog
//        [self renameAction:object];
//    }
//}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(insertNewline:)) {
        if (control == _ebFilename) {
            //Do something against ENTER key
            [self RenameAction:nil];
            return YES;
        }
    } else if (commandSelector == @selector(deleteForward:)) {
        //Do something against DELETE key

    } else if (commandSelector == @selector(deleteBackward:)) {
        //Do something against BACKSPACE key

    } else if (commandSelector == @selector(insertTab:)) {
        //Do something against TAB key
    }

    return NO;
}

- (IBAction)RenameAction:(id)sender {
    [[self window] close];
    [NSApp stopModal];
}

- (IBAction)RenameCancel:(id)sender {
    // sets back the file to the old name, so the delegate won't do nothing
    [[self ebFilename] setStringValue:oldFilename];
    [[self window] close];
    [NSApp stopModal];
}


-(void) setRenamingFile:(NSString *)filename {

    oldFilename = filename;
    [[self ebFilename] setStringValue:oldFilename];
    // Select the name only

    [[self ebFilename] selectText:self];
    NSUInteger head_size = [[oldFilename stringByDeletingPathExtension] length];
    NSRange selectRange = {0, head_size};

    [[[self ebFilename] currentEditor] setSelectedRange:selectRange];

    //Another option to do it
    //[(NSText *)[[[self ebFilename] window] firstResponder] setSelectedRange:selectRange];

}

-(NSString*) getRenameFile {
    return [[self ebFilename] stringValue];
}

@end
