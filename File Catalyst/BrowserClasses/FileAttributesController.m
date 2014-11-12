//
//  FileAttributesController.m
//  File Catalyst
//
//  Created by Viktoryia Labunets on 01/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "FileAttributesController.h"

@interface FileAttributesController ()

@end

@implementation FileAttributesController

//- (void)viewDidLoad {
//    [super viewDidLoad];
    // Do view setup here.
//}


+ (FileAttributesController *)sharedFileAttributeController {
    static FileAttributesController *gSharedColorTableController = nil;
    if (gSharedColorTableController == nil) {
        gSharedColorTableController = [[[self class] alloc] initWithWindowNibName:@"FileAttributeController" ];
    }
    return gSharedColorTableController;
}

@synthesize delegate = _delegate;
@dynamic selectedAttributes;





@end
