//
//  OpeniBootClass.h
//  BootlaceV2
//
//  Created by Neonkoala on 25/09/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <Foundation/NSTask.h>
#import <sys/mman.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "nvramFunctions.h"
#import "BSPatch.h"
#import "ASIHTTPRequest.h"
#import "partial/partial.h"

@class BSPatch;

@interface OpeniBootClass : NSObject {
	BSPatch *bsPatchInstance;
	nvramFunctions *nvramInstance;
	commonFunctions *commonInstance;
	
	NSString *llbPath;
	NSString *iBootPath;
	NSString *openibootPath;
	
	NSMutableDictionary *deviceDict;
	
	NSDictionary *iBootPatches;
	NSDictionary *LLBPatches;
	NSDictionary *kernelPatches;	
}

@property (nonatomic, retain) NSString *llbPath;
@property (nonatomic, retain) NSString *iBootPath;
@property (nonatomic, retain) NSString *openibootPath;

@property (nonatomic, retain) NSMutableDictionary *deviceDict;

@property (nonatomic, retain) NSDictionary *iBootPatches;
@property (nonatomic, retain) NSDictionary *LLBPatches;
@property (nonatomic, retain) NSDictionary *kernelPatches;

//OpeniBoot install functions
- (void)opibOperation:(NSNumber *)operation;
- (int)opibParseUpdatePlist;
- (int)opibGetNORFromManifest;
- (int)opibFlashManifest:(BOOL)remove;
- (int)opibFlashIMG3:(NSString *)path usingService:(io_connect_t)norServiceConnection type:(BOOL)isLLB;
- (int)opibEncryptIMG3:(NSString *)srcPath to:(NSString *)dstPath with:(NSString *)templateIMG3 key:(NSString *)key iv:(NSString *)iv type:(BOOL)isLLB;
- (int)opibDecryptIMG3:(NSString *)srcPath to:(NSString *)dstPath key:(NSString *)key iv:(NSString *)iv type:(BOOL)isLLB;
- (int)opibPatchNORFiles:(BOOL)withIbox;
- (int)opibPatchIbox:(NSString *)path;
- (int)opibGetFirmwareBundle;
- (int)opibGetOpeniBoot;
- (int)opibSetVersion:(NSString *)version;
- (int)opibResetConfig;

- (io_service_t)opibGetIOService:(NSString *)name;

- (void)opibCleanUp;
- (void)opibCheckForUpdates;
- (void)opibCheckInstalled;
- (void)opibUpdateProgress:(float)subProgress;

//KernelPAtch functions
- (void)opibPatchKernelCache;
- (void)opibKernelPatchCleanup;

//QuickBoot functions
- (int)opibRebootAndroid;
- (int)opibRebootConsole;

//OpeniBoot config functions
- (int)opibApplyConfig;
- (int)opibBackupConfig;
- (int)opibRestoreConfig;
- (int)opibResetConfig;


@end
