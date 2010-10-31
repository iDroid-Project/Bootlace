//
//  BSPatch.h
//  BootlaceV2
//
//  Created by Neonkoala on 30/09/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "commonFunctions.h"
#import <bzlib.h>
#import <string.h>
#import <unistd.h>
#import <fcntl.h>

@interface BSPatch : NSObject {

}

- (off_t)offtin:(u_char *)buf;
- (int)bsPatch:(NSString *)filePath withPatch:(NSString *)patchPath;

@end
