//
//  AppStoreManager.h
//  Caravelle
//
//  Created by Nuno on 12/08/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface AppStoreManager : NSObject<SKProductsRequestDelegate>

@property NSMutableArray * appInInformation;


-(NSArray*) productIdentifiers;

-(void) updateItemList;


@end
