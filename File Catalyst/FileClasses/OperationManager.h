//
//  OperationManager.h
//  Caravelle
//
//  Created by Nuno on 07/05/16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OperationManager : NSObject {
    NSMutableArray *_executedOperations;
}

// Class resposible for managing undo/redo operations and in the future, handling all the visualization, that will be moved from AppDelegate to here.\

-(instancetype) init ;
-(void) completeOperation:(NSMutableDictionary*)operationInfo;
-(NSMutableDictionary*) makeUndoOperation;

@end
