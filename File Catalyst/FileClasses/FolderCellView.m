//
//  FolderCellView.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 3/30/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "FolderCellView.h"
#import "Definitions.h"

@implementation FolderCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        /* Sign for receiving drops of files */
    }
    
    return self;
}

-(void) setURL:(NSURL *)folderURL {
    self->url = folderURL;
    /* Sign for receiving drops of files */
    //NSLog(@"Registering the Drag capability %@", self.textField);
    [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

- (NSString *)Title {
    return [[self textField ] stringValue];
}

- (void)setTitle:(NSString *)subTitle {
    [[self textField] setStringValue: subTitle];
}

- (NSString *)subTitle {
    return [subTitleTextField stringValue];
}

- (void)setSubTitle:(NSString *)subTitle {
    [subTitleTextField setStringValue: subTitle];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

//    if ( [[pboard types] containsObject:NSColorPboardType] ) {
//        if (sourceDragMask & NSDragOperationGeneric) {
//            return NSDragOperationGeneric;
//        }
//    }
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
        else if (sourceDragMask & NSDragOperationMove) {
            return NSDragOperationMove;
        }
    }
    return NSDragOperationNone;
}

// TODO !!! Implement draggingUpdated to change the icon to reflect the operation
// Consider also implementing draggingExited so that the icon is reverted to its original form.

// prepareForDragOperation: message followed by performDragOperation: and concludeDragOperation:.

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *operation=nil;


        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
        if (sourceDragMask & NSDragOperationCopy) {
            NSLog(@"Going to copy the files");
            //copyFilesThreaded(files, [self->url path]);
            operation = opCopyOperation;

            //[self addLinkToFiles:files];
        } else if (sourceDragMask & NSDragOperationMove) {
            // implement the move here
            NSLog(@"Going to move the file");
            //[self addDataFromFiles:files];
            operation = opMoveOperation;
        }
        else {
            NSLog(@"Unsuported Operation Something went wrong here");
            return NO;
        }
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              files, kSelectedFilesKey,
                              operation, kDropOperationKey,
                              self->url, kDropDestinationKey,
                              nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationDoFileOperation object:self userInfo:info];


    }
//    else if ( [[pboard types] containsObject:NSColorPboardType] ) {
//        // Only a copy operation allowed so just copy the data
//        NSColor *newColor = [NSColor colorFromPasteboard:pboard];
//        [self setColor:newColor];
//    }
    return YES;
}

@end
