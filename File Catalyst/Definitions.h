//
//  Definitions.h
//  File Catalyst
//
//  Created by Viktoryia Labunets on 04/08/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#ifndef File_Catalyst_Definitions_h
#define File_Catalyst_Definitions_h

enum enumInRootSet {
    rootHasNoRelation = 1,
    rootAlreadyContained = 0,
    rootContainsExisting = -1
};


extern NSString *notificationStatusUpdate;
extern NSString *selectedFilesNotificationObject;

extern NSString *notificationCatalystRootUpdate;
extern NSString *catalystRootUpdateNotificationPath;


#define UPDATE_CADENCE_PER_FILE 100


#endif
