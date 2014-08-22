//
//  myTableView.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 21/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "MYTableView.h"
#import "Definitions.h"

@implementation MYTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(TreeBranch *)treeNodeSelected {
    return _treeNodeSelected;
}

-(void) setTreeNodeSelected:(TreeBranch*) node {
    /* Sign for receiving drops of files */
    if (node!=nil) {
        //[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
    }
    else {
        [self unregisterDraggedTypes];
    }
    _treeNodeSelected = node;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSDragOperation answer = NSDragOperationNone;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    //    if ( [[pboard types] containsObject:NSColorPboardType] ) {
    //        if (sourceDragMask & NSDragOperationGeneric) {
    //            return NSDragOperationGeneric;
    //        }
    //    }
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            answer = NSDragOperationCopy;
        }
        else if (sourceDragMask & NSDragOperationMove) {
            answer = NSDragOperationMove;
        }
    }
    else
        answer = NSDragOperationNone;
    return answer;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender /* if the destination responded to draggingEntered: but not to draggingUpdated: the return value from draggingEntered: is used */
/* !!! This is actually not true for this Class in Particular */
{
    NSLog(@"update");
    return [self draggingEntered:sender];
}


// TODO !!! Implement draggingUpdated to change the icon to reflect the operation
// Consider also implementing draggingExited so that the icon is reverted to its original form.


// prepareForDragOperation: message followed by performDragOperation: and concludeDragOperation:.

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSLog(@"prepareForDragOperation");
    return YES;
}

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
                              self, kSenderKey,  // pass back to check if user cancelled/started a new scan
                              operation, kOperationKey,
                              [self.treeNodeSelected url], kDestinationKey,
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


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSLog(@"conclude Drag Operation");
    
}
/* draggingEnded: is implemented as of Mac OS 10.5 */
- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    NSLog(@"OH! dragging ended");
}

/* the receiver of -wantsPeriodicDraggingUpdates should return NO if it does not require periodic -draggingUpdated messages (eg. not autoscrolling or otherwise dependent on draggingUpdated: sent while mouse is stationary) */
- (BOOL)wantsPeriodicDraggingUpdates {
    return NO;
}


@end
