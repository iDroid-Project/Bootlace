//
//  installClass.h
//  BootlaceV2
//
//  Created by Neonkoala on 26/07/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication2.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOKitKeys.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "getFile.h"
#import "extractionClass.h"

@class getFile;
@class extractionClass;

@interface installClass : NSObject {
	getFile *getFileInstance;
	commonFunctions *commonInstance;
	extractionClass *extractionInstance;
}

@property (nonatomic, retain) commonFunctions *commonInstance;
@property (nonatomic, retain) extractionClass *extractionInstance;

- (int)parseLatestVersionPlist;
- (int)parseInstalledPlist;
- (int)parseUpgradePlist;
- (int)generateInstalledPlist;
- (int)updateInstalledPlist;
- (void)idroidInstall;
- (void)idroidUpgrade;
- (void)idroidRemove;
- (void)cleanUp;
- (void)checkForUpdates;
- (void)checkInstalled;
- (void)updateProgress:(NSNumber *)progress nextStage:(BOOL)next;
- (int)createDirectories:(NSArray *)directoryList;
- (int)addFiles;
- (int)moveFiles:(NSDictionary *)fileList;
- (int)removeFiles:(NSArray *)fileList;
- (int)cherryPickFiles:(NSArray *)fileList;
- (int)runPostInstall:(NSString *)URL;
- (int)dumpMultitouch;
- (int)dumpWiFi;

@end
