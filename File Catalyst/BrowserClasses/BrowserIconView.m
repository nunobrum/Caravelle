
//
//  BrowserIconView.m
//  Caravelle
//
//  Created by Nuno Brum on 11/04/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "BrowserIconView.h"
#import "Definitions.h"
#import "IconViewController.h"

@implementation BrowserIconView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(FileCollectionViewItem*) iconForEvent:(NSEvent*) theEvent {
    NSPoint xy =[theEvent locationInWindow];
    NSPoint x1y1 = [self convertPoint:xy fromView:nil];
    NSIndexPath *ipath = [self indexPathForItemAtPoint:x1y1];
    if (ipath != nil) {
        id item = [self itemAtIndexPath:ipath];
        NSAssert([item isKindOfClass:[FileCollectionViewItem class]],@"Expected FileCollectionViewItem class");
        return (FileCollectionViewItem*) item;
    }
    else
        return nil;
}

-(id) objectValueAtIndexPath:(NSIndexPath*)indexPath {
    id item = [self itemAtIndexPath:indexPath];
    if (item == nil) {
        NSLog(@"BrowserIconView.objectValueAtIndexPath: nil Object at indexPath (%ld,%ld) ", indexPath.section, indexPath.item);
        return nil;
    }
    if (NO == [item isKindOfClass:[FileCollectionViewItem class]]) {
        NSLog(@"BrowserIconView.objectValueAtIndexPath: Unexpected object Received");
        NSAssert(NO,@"BrowserIconView.objectValueAtIndexPath: Expected FileCollectionViewItem class");
    }
    return [(FileCollectionViewItem*)item representedObject];
}

-(NSMutableArray *) objectsAtIndexPathSet:(NSSet<NSIndexPath*>*)indexPathSet {
    NSMutableArray *answer;
    answer = [NSMutableArray arrayWithCapacity:indexPathSet.count];
    [indexPathSet enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, BOOL * _Nonnull stop) {
        id reprObj = [self objectValueAtIndexPath:obj];
        [answer addObject:reprObj];
    }];
    return answer;
}

-(NSIndexPath*) indexPathForRepresentedObject:(id)representedObject {
    for (FileCollectionViewItem* item in self.content) {
        if ([item.representedObject isEqualTo:representedObject]) {
            return [self indexPathForItem:item];
        }
    }
    return nil;
}

-(NSSet <NSIndexPath*> *) indexPathsWithHashes:(NSArray*) hashes {
    NSMutableSet <NSIndexPath*> *answer;
    answer = [[NSMutableSet alloc] initWithCapacity:hashes.count];
    
    for (FileCollectionViewItem* item in self.content) {
        id hash = [item.representedObject hashObject];
        if ([hashes containsObject:hash]) {
            NSIndexPath *indexPath = [self indexPathForItem:item];
            [answer addObject:indexPath];
        }
    }
    return answer;
}

-(FileCollectionViewItem*) lastClicked {
    return self->_lastClicked;
}

- (IBAction)mouseDown:(NSEvent *)theEvent {
    self->_lastClicked = [self iconForEvent:theEvent];
    if([theEvent clickCount] > 1) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(doubleClick:)]) {
            [(IconViewController*)self.delegate doubleClick:self];
        }
    }
    else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(lastClick:)]) {
            [(IconViewController*)self.delegate lastClick:self];
            if (self->_lastClicked.isSelected) {
                [self startEditInIcon:self->_lastClicked];
                return; // Stop here don't propagete the mouseDown any further
            }
        }
    }
    [super mouseDown:theEvent];
    
}

- (IBAction)rightMouseDown:(NSEvent *)theEvent {
    self->_lastClicked = [self iconForEvent:theEvent];
    if(self.delegate && [self.delegate respondsToSelector:@selector(lastRightClick:)]) {
        [(IconViewController*)self.delegate lastRightClick:self];
    }
    [super rightMouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *key = [theEvent characters];
    unichar keyCode = [key characterAtIndex:0];

    NSInteger behave = [[NSUserDefaults standardUserDefaults] integerForKey: USER_DEF_APP_BEHAVIOUR] ;

    if ((([theEvent modifierFlags] & NSCommandKeyMask) &&
         (keyCode == KeyCodeUp  ||
          keyCode == KeyCodeDown )) ||
        (behave == APP_BEHAVIOUR_MULTIPLATFORM &&
         ([key isEqualToString:@"\r"] || // The Return key will open the file
          [key isEqualToString:@"\t"] || // the tab key will switch Panes
          [key isEqualToString:@"\x19"] || // Shift-Tab will also switch Panes
          [key isEqualToString:@" "])) ||   // The space will mark the file
        (behave == APP_BEHAVIOUR_NATIVE &&
         ([key isEqualToString:@"\r"] || // The Return key will rename the file
          [key isEqualToString:@" "] || // The Space will open the file
          [key isEqualToString:@"\x19"] || // Shift-Tab will move to previous file
          [key isEqualToString:@"\t"]))) { // the tab key will move to next file
             [[self delegate ] performSelector:@selector(keyDown:) withObject:theEvent];
         }

    // perform nextView
    else {
        // propagate to super
        [super keyDown:theEvent];
    }
}

- (void)cancelOperation:(id)sender {
    // clean the filter
    [[self delegate] performSelector:@selector(cancelOperation:) withObject:self];
    // and pass the cancel operation upwards anyway
    [super cancelOperation:sender];
}

-(BOOL) startEditInIcon:(FileCollectionViewItem*) icon {
    NSTextField *textField = [icon textField];
    NSAssert(textField!=nil, @"IconViewController.startEditItemName: textField not found!");
    [icon formatSelected:IconInEdition];
    [self.window makeFirstResponder:textField];
    // Recuperate the old filename
    NSString *oldFilename = [textField stringValue];
    // Select the part up to the extension
    NSUInteger head_size = [[oldFilename stringByDeletingPathExtension] length];
    NSRange selectRange = {0, head_size};
    [[textField currentEditor] setSelectedRange:selectRange];
    return YES;
}


- (BOOL)becomeFirstResponder {
    // Highlight the selections
    
    for (NSCollectionViewItem *icon in self.visibleItems) {
        if (icon.isSelected && [icon isKindOfClass:[FileCollectionViewItem class]]) {
            [((FileCollectionViewItem*)icon) formatSelected:IconSelected];
        }
    }
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    // Set selected fill color to grey
    for (NSCollectionViewItem *icon in self.visibleItems) {
        if (icon.isSelected && [icon isKindOfClass:[FileCollectionViewItem class]]) {
            [((FileCollectionViewItem*)icon) formatSelected:IconSelectedInactive];
        }
    }
    return[super resignFirstResponder];
}
@end
