//
//  FileAttributesController.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 01/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@protocol FileAttributesControllerDelegate;

@interface FileAttributesController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSPopoverDelegate> {
@private
    IBOutlet NSTableView *_tableAttributeList;

    //NSColorList *_colorList;
    NSArray *_attributeNames;
    id <FileAttributesControllerDelegate> _delegate;

    BOOL _updatingSelection;

    NSPopover *_popover;
}

+ (FileAttributesController *)sharedFileAttributeController;

- (void)selectAttribute:(NSArray *)selectedAttributes withPositioningView:(NSView *)positioningView;

@property(readonly) NSArray *selectedAttributes;

@property id <FileAttributesControllerDelegate> delegate;

@end

@protocol FileAttributesControllerDelegate <NSObject>

@optional
- (void)attribTableController:(FileAttributesController *)controller didChooseAttributes:(NSArray *)attributeNames;
@end

