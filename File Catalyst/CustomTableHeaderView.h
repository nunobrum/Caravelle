//
//  CustomTableHeaderView.h
//  File Catalyst
//
//  Created by Nuno Brum on 02/11/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define COLUMN_NOTIFICATION

#ifdef COLUMN_NOTIFICATION
extern NSString *notificationColumnSelect;
extern NSString *kReferenceViewKey;
extern NSString *kColumnChanged;
#endif


// Class accessor to the ColumnInfo read from PLIST
// It has a static variable so that the PLIST is only read once by the application
// and it is shared between Browsers

extern NSDictionary *columnInfo();
extern NSArray* sortedColumnNames();
extern NSString* keyForColID(NSString* colID);

@interface CustomTableHeaderView : NSTableHeaderView {
    NSInteger columnClicked;
    NSDictionary *_columnSelected;

}

@end
