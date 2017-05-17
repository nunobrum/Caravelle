//
//  DataSourceProtocol.h
//  Caravelle
//
//  Created by Nuno Brum on 29.12.16.
//  Copyright © 2016 Nuno Brum. All rights reserved.
//

#ifndef DataSourceProtocol_h
#define DataSourceProtocol_h

#import "TreeBranch.h"
#import "MySortDescriptors.h"

@protocol TreeViewerProtocol <NSObject>

-(void) reset;
-(void) setSortDescriptor:(MySortDescriptors*) sortDesc;

-(void) setDepth:(NSInteger)depth;
-(NSInteger) depth;

-(void) setParent:(TreeBranch*)parent;
-(TreeBranch*) parent;

-(void) setFilter:(NSPredicate*)filter;
-(NSPredicate*) filter;

-(BOOL) needsRefresh;
-(void) setNeedsRefresh;

@end

#endif /* DataSourceProtocol_h */
