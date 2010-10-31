//
//  nvramFunctions.h
//  Bootlace
//
//  Created by Neonkoala on 15/05/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "commonData.h"
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

@interface nvramFunctions : NSObject {

}

- (int)dumpNVRAM;
- (int)updateNVRAM:(int)mode;
- (int)backupNVRAM;
- (int)restoreNVRAM;

@end
