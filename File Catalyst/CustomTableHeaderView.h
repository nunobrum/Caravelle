//
//  CustomTableHeaderView.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 02/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define COLUMN_NOTIFICATION

#ifdef COLUMN_NOTIFICATION
extern NSString *notificationColumnSelect;
extern NSString *kReferenceViewKey;
extern NSString *kColumnChanged;
#endif

@interface CustomTableHeaderView : NSTableHeaderView {
    NSInteger columnClicked;
}

@property NSDictionary *columnControl;
@end
