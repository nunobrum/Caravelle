//
//  FileOperation.h
//  File Catalyst
//
//  Created by Nuno Brum on 02/09/14.
//  Copyright (c) 2014 Nuno Brum. All rights reserved.
//

#import "AppOperation.h"

@interface FileOperation : AppOperation {
    NSArray *files;
    NSString *op;
    NSUInteger fileCount;
    NSUInteger fileOKCount;
    NSUInteger totalFileCount;
}
@end
