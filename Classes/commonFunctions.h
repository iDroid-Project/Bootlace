//
//  commonFunctions.h
//  Bootlace
//
//  Created by Neonkoala on 12/05/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <sys/mount.h>
#import <sys/param.h>
#import <sys/types.h>
#import <sys/reboot.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import <notify.h>
#import <dlfcn.h>

#import "commonData.h"
#import "extractionClass.h"
#import "DroidViewController.h"
#import "OpeniBootClass.h"


// DLog is almost a drop-in replacement for NSLog
#ifdef DEBUG
#	define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@class OpeniBootClass;

@interface commonFunctions : NSObject {
	installClass *installInstance;
	OpeniBootClass *opibInstance;
}

- (BOOL)checkMains;
- (void)toggleAirplaneMode;
- (float)getFreeSpace;
- (NSString *)dataMD5:(NSData *)data;
- (NSString *)fileMD5:(NSString *)path;
- (void)getPlatform;
- (void)getSystemVersion;
- (void)firstLaunch;
- (void)sendError:(NSString *)alertMsg;
- (void)sendWarning:(NSString *)alertMsg;
- (void)sendTerminalError:(NSString *)alertMsg;
- (void)sendConfirmation:(NSString *)alertMsg withTag:(int)tag;
- (void)sendSuccess:(NSString *)alertMsg;

@end
