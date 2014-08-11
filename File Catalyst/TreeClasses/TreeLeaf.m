//
//  TreeLeaf.m
//  FileCatalyst1
//
//  Created by Viktoryia Labunets on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeLeaf.h"

@implementation TreeLeaf

//-(void) SetFileInformation: (FileInformation *) fileInfo {
//    fileInformation = fileInfo;
//}
//
-(FileInformation*)getFileInformation {
    return [FileInformation createWithURL: self.myURL];
}
-(BOOL) isBranch {
    return NO;
}
@end
