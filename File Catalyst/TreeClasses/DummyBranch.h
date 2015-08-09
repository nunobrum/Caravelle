//
//  DummyBranch.h
//  Caravelle
//
//  Created by Nuno on 08/08/15.
//  Copyright (c) 2015 Nuno Brum. All rights reserved.
//

#import "TreeBranch.h"

@interface DummyBranch : TreeBranch

+(instancetype) parentFor:(TreeItem*) item;

@end
