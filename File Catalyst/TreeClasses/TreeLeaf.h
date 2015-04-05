//
//  TreeLeaf.h
//  FileCatalyst1
//
//  Created by Nuno Brum on 1/22/13.
//  Copyright (c) 2013 Nuno Brum. All rights reserved.
//

#import "TreeItem.h"
#import "FileInformation.h"

@interface TreeLeaf : TreeItem <TreeProtocol> {
//    FileInformation *fileInformation;
}
//-(void)       SetFileInformation: (FileInformation *) fileInfo;
-(FileInformation*) getFileInformation;

@end
