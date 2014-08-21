//
//  Definitions.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 04/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#ifndef File_Catalyst_Definitions_h
#define File_Catalyst_Definitions_h

extern NSString *notificationStatusUpdate;
extern NSString *kSelectedFilesKey;

extern NSString *notificationCatalystRootUpdate;
extern NSString *kRootPathKey;

extern NSString *notificationDoFileOperation;
extern NSString *kOperationKey;
extern NSString *kDestinationKey;

extern NSString *opCopyOperation;
extern NSString *opMoveOperation;

extern NSString *notificationTreeConstructionFinished;
extern NSString *kTreeRootKey;
extern NSString *kSenderKey;
extern NSString *kModeKey;
extern NSString *kScanCountKey;

extern NSFileManager *appFileManager;

#define UPDATE_CADENCE_PER_FILE 100


#endif
