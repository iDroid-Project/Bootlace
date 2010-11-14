//
//  installClass.m
//  BootlaceV2
//
//  Created by Neonkoala on 26/07/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "installClass.h"


@implementation installClass

@synthesize commonInstance, extractionInstance;

- (int)parseLatestVersionPlist {
	DLog(@"Parsing latest version Plist");

	commonData* sharedData = [commonData sharedData];
	
	//Check device match
	NSMutableDictionary* platformDict = [sharedData.latestVerDict objectForKey:sharedData.platform];
	if (platformDict==nil) {
		sharedData.updateCanBeInstalled = -1;
		DLog(@"  - No platform match! iDroid isn't available for this device.");
		return -1;
	} 
	
	sharedData.updateCanBeInstalled = 1;
	sharedData.updateVer = [platformDict objectForKey:@"iDroidVersion"];
	sharedData.updateAndroidVer = [platformDict objectForKey:@"AndroidVersion"];
	sharedData.updateDate = [platformDict objectForKey:@"ReleaseDate"];
	sharedData.updateOpibRequired = [platformDict objectForKey:@"OpeniBootRequired"];
	sharedData.updateBootlaceRequired = [platformDict objectForKey:@"BootlaceRequired"];
	sharedData.updateURL = [platformDict objectForKey:@"URL"];
	sharedData.updateMD5 = [platformDict objectForKey:@"MD5"];
	sharedData.updateSize = [[platformDict objectForKey:@"Size"] intValue];
	sharedData.updateFiles = [platformDict objectForKey:@"Files"];
	sharedData.updateDependencies = [platformDict objectForKey:@"Dependencies"];
	sharedData.updateDirectories = [platformDict objectForKey:@"Directories"];
	sharedData.updateClean = [platformDict objectForKey:@"Clean"];
	
	sharedData.updateFirmwarePath = [sharedData.updateDependencies objectForKey:@"Directory"];
	
	DLog(@"Latest version plist parsed");
	
	DLog(@"OpibRequired: %@", sharedData.updateOpibRequired);
	
	return 0;
}

- (int)parseUpgradePlist {
	DLog(@"Parsing upgrade plist");
	
	commonData* sharedData = [commonData sharedData];
	
	NSMutableDictionary* deltaDict = [sharedData.upgradeDict objectForKey:@"Delta"];
	NSMutableDictionary* comboDict = [sharedData.upgradeDict objectForKey:@"Combo"];
	
	if (deltaDict==nil || comboDict==nil) {
		DLog(@"  - No delta/combo match!");
		
		return -1;
	}
	
	//Parse Delta
	NSMutableDictionary *deltaPlatformDict = [deltaDict objectForKey:sharedData.platform];
	
	if (deltaPlatformDict==nil) {
		DLog(@"  - No platform delta match! Upgrade path unavailable for this device.");
		
		return -2;
	}
	
	sharedData.upgradeDeltaDestructive = [deltaPlatformDict objectForKey:@"Destructive"];
	sharedData.upgradeDeltaReqVer = [deltaPlatformDict objectForKey:@"RequiredVersion"];
	sharedData.upgradeDeltaCreateDirectories = [deltaPlatformDict objectForKey:@"CreateDirectories"];
	sharedData.upgradeDeltaRemoveFiles = [deltaPlatformDict objectForKey:@"RemoveFiles"];
	sharedData.upgradeDeltaMoveFiles = [deltaPlatformDict objectForKey:@"MoveFiles"];
	sharedData.upgradeDeltaAddFiles = [deltaPlatformDict objectForKey:@"AddFiles"];
	sharedData.upgradeDeltaPostInstall = [deltaPlatformDict objectForKey:@"PostInstall"];
	
	//Parse Combo
	NSMutableDictionary *comboPlatformDict = [comboDict objectForKey:sharedData.platform];
	
	if (comboPlatformDict==nil) {
		DLog(@"  - No platform combo match! Upgrade path unavailable for this device.");
		
		return -3;
	}
	
	sharedData.upgradeComboDestructive = [comboPlatformDict objectForKey:@"Destructive"];
	sharedData.upgradeComboReqVer = [comboPlatformDict objectForKey:@"RequiredVersion"];
	sharedData.upgradeComboCreateDirectories = [comboPlatformDict objectForKey:@"CreateDirectories"];
	sharedData.upgradeComboRemoveFiles = [deltaPlatformDict objectForKey:@"RemoveFiles"];
	sharedData.upgradeComboMoveFiles = [deltaPlatformDict objectForKey:@"MoveFiles"];
	sharedData.upgradeComboAddFiles = [deltaPlatformDict objectForKey:@"AddFiles"];
	sharedData.upgradeComboPostInstall = [deltaPlatformDict objectForKey:@"PostInstall"];
	
	NSLog(@"Destructive? 1: %@ 2: %@", sharedData.upgradeDeltaDestructive, sharedData.upgradeComboDestructive);
	
	return 0;
}

- (int)parseInstalledPlist {
	DLog(@"Parsing Installed Plist");

	commonData* sharedData = [commonData sharedData];
	
	NSString *installedPlistPath = [sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"];
	NSDictionary *installedDict = [NSDictionary dictionaryWithContentsOfFile:installedPlistPath];
	
	sharedData.installedVer = [installedDict objectForKey:@"iDroidVersion"];
	sharedData.installedAndroidVer = [installedDict objectForKey:@"AndroidVersion"];
	sharedData.installedDate = [installedDict objectForKey:@"InstalledDate"];
	sharedData.installedOpibRequired = [installedDict objectForKey:@"OpeniBootRequired"];
	sharedData.installedFiles = [installedDict objectForKey:@"Files"];
	sharedData.installedDirectories = [installedDict objectForKey:@"Directories"];
	sharedData.installedDependencies = [installedDict objectForKey:@"Dependencies"];
	
	if(sharedData.installedVer==nil || sharedData.installedAndroidVer==nil || sharedData.installedDate==nil || sharedData.installedFiles==nil || sharedData.installedDependencies==nil || sharedData.installedDirectories==nil) {
		DLog(@"Plist is invalid, missing data values.");
		return -1;
	}
	
	return 0;
}

- (int)generateInstalledPlist {
	DLog(@"Generating Installed Plist");

	int i, count;
	commonData* sharedData = [commonData sharedData];
	NSMutableArray *installedDependencies;
	NSMutableDictionary *installedPlist = [NSMutableDictionary dictionaryWithCapacity:6];
	
	count = [sharedData.updateFiles count];
	NSMutableArray *installedFiles = [NSMutableArray arrayWithCapacity:count];
	
	for (i=0; i<count; i++) {
		NSString *key = [NSString stringWithFormat:@"%d", i];
		NSArray *fileDetails = [sharedData.updateFiles objectForKey:key];
		
		[installedFiles addObject:[[fileDetails objectAtIndex:1] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]]];
	}
	
	count = [sharedData.updateDirectories count];
	NSMutableArray *installedDirectories = [NSMutableArray arrayWithCapacity:count];
	
	if([sharedData.updateDependencies objectForKey:@"WiFi"]) {
		NSDictionary *wifiDict = [sharedData.updateDependencies objectForKey:@"WiFi"];
		count = [wifiDict count];
		
		installedDependencies = [NSMutableArray arrayWithCapacity:(count+2)];
	
		for (i=0; i<count; i++) {
			NSString *key = [NSString stringWithFormat:@"%d", i];
			NSArray *fileDetails = [wifiDict objectForKey:key];
		
			[installedDependencies addObject:[sharedData.updateFirmwarePath stringByAppendingPathComponent:[fileDetails objectAtIndex:0]]];
		}
	} else {
		installedDependencies = [NSMutableArray arrayWithCapacity:2];
	}
	
	if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F52,1"] || [[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F51,1"]) {
		[installedDependencies addObject:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"]];

		DLog(@"Zephyr2 multitouch location added.");
	} else if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z1F50,1"]) {
		[installedDependencies addObject:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_main.bin"]];
		[installedDependencies addObject:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_aspeed.bin"]];
		
		DLog(@"Zephyr1 multitouch location added.");
	}
	
	[installedPlist setObject:sharedData.updateVer forKey:@"iDroidVersion"];
	[installedPlist setObject:sharedData.updateAndroidVer forKey:@"AndroidVersion"];
	[installedPlist setObject:sharedData.updateOpibRequired forKey:@"OpeniBootRequired"];
	[installedPlist setObject:[NSDate date] forKey:@"InstalledDate"];
	[installedPlist setObject:installedFiles forKey:@"Files"];
	[installedPlist setObject:installedDirectories forKey:@"Directories"];
	[installedPlist setObject:installedDependencies forKey:@"Dependencies"];
	
	if(![installedPlist writeToFile:[sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"] atomically:YES]) {
		DLog(@"Failed to write Installed Plist");
		return -1;
	}
	
	DLog(@"Installed Plist generated successfully.");

	return 0;
}

- (int)updateInstalledPlist {
	DLog(@"Updating Installed Plist");
	
	commonData* sharedData = [commonData sharedData];
	int i, count1, count2;
	NSString *key;
	
	NSString *installedPlistPath = [sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:installedPlistPath]) {
		DLog(@"Installed.plist not present, wtf?");
		return -1;
	}

	NSMutableDictionary *installedPlist = [NSDictionary dictionaryWithContentsOfFile:installedPlistPath];
	
	if(sharedData.upgradeUseDelta) {
		count1 = [sharedData.upgradeDeltaAddFiles count];
		count2 = [sharedData.upgradeDeltaMoveFiles count];
	} else {
		count1 = [sharedData.upgradeComboAddFiles count];
		count2 = [sharedData.upgradeComboMoveFiles count];
	}
		
	NSMutableArray *installedFiles = [NSMutableArray arrayWithCapacity:(count1 + count2)];
	
	for (i=0; i<count1; i++) {
		if(sharedData.upgradeUseDelta) {
			key = [sharedData.upgradeDeltaAddFiles objectAtIndex:i];
		} else {
			key = [sharedData.upgradeComboAddFiles objectAtIndex:i];
		}		
		
		NSArray *fileDetails = [sharedData.updateFiles objectForKey:key];
		[installedFiles addObject:[[fileDetails objectAtIndex:1] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]]];
	}
	
	for (i=0; i<count2; i++) {
		NSString *key = [NSString stringWithFormat:@"%d", i];
		NSArray *fileDetails;
		
		if(sharedData.upgradeUseDelta) {
			fileDetails = [sharedData.upgradeDeltaMoveFiles objectForKey:key];
		} else {
			fileDetails = [sharedData.upgradeComboMoveFiles objectForKey:key];
		}
		
		[installedFiles addObject:[fileDetails objectAtIndex:1]];
	}
	
	[installedPlist setObject:sharedData.updateVer forKey:@"iDroidVersion"];
	[installedPlist setObject:sharedData.updateAndroidVer forKey:@"AndroidVersion"];
	[installedPlist setObject:sharedData.updateOpibRequired forKey:@"OpeniBootRequired"];
	[installedPlist setObject:[NSDate date] forKey:@"InstalledDate"];
	[installedPlist setObject:installedFiles forKey:@"Files"];
	
	[[NSFileManager defaultManager] removeItemAtPath:installedPlistPath error:nil];
	
	if(![installedPlist writeToFile:[sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"] atomically:YES]) {
		DLog(@"Failed to write Installed Plist");
		return -1;
	}
	
	DLog(@"Installed Plist updated successfully.");
	
	return 0;
}

- (void)idroidInstall {
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	extractionInstance = [[extractionClass alloc] init];
	int success;
	
	sharedData.updateFail = 0;
	sharedData.updateStage = 0;
	
	[UIApplication sharedApplication].idleTimerDisabled = YES; //Stop autolock
	
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	NSString *match = @"*tar.gz";
	
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedData.workingDirectory error:nil];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
	NSArray *results = [dirContents filteredArrayUsingPredicate:predicate];
	
	if([results count] > 0) {
		DLog(@"Found downloaded package: %@ \r\nChecking MD5.", [results objectAtIndex:0]);
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
		
		NSString *pkg = [sharedData.workingDirectory stringByAppendingPathComponent:[results objectAtIndex:0]];
		NSString *md5hash = [commonInstance fileMD5:pkg];
		
		DLog(@"Found package MD5: %@", md5hash);
		
		if([sharedData.updateMD5 isEqualToString:md5hash]) {
			[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
			sharedData.updatePackagePath = pkg;
		} else {
			DLog(@"MD5 mismatch redownloading.");
			[[NSFileManager defaultManager] removeItemAtPath:pkg error:nil];
			
			sharedData.updateStage = 1;
		}
	}
	
	if(sharedData.updateStage == 1) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		getFileInstance = [[getFile alloc] initWithUrl:sharedData.updateURL directory:sharedData.workingDirectory];
		DLog(@"DEBUG: updateURL = %@", sharedData.updateURL);
		DLog(@"DEBUG: workingDirectory = %@", sharedData.workingDirectory);
		
		[getFileInstance getFileDownload:self];
		
		BOOL keepAlive = YES;
		
		do {        
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
			//Check NSURLConnection for activity
			if (getFileInstance.getFileWorking == NO) {
				keepAlive = NO;
			}
			if(sharedData.updateFail == 1) {
				DLog(@"DEBUG: Failed to get iDroid package. Cleaning up.");
				[self cleanUp];
				return;
			}
		} while (keepAlive);
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		sharedData.updatePackagePath = getFileInstance.getFilePath;
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
		
		//Calculate file MD5
		NSString *md5hash = [commonInstance fileMD5:sharedData.updatePackagePath];
		DLog(@"MD5 Hash: %@", md5hash);
		
		if(![sharedData.updateMD5 isEqualToString:md5hash]) {
			DLog(@"MD5 hash does not match, assuming download is corrupt.");
			sharedData.updateFail = 9;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	}
	
	//Create directories
	success = [self createDirectories:sharedData.updateDirectories];
	
	if(success < 0) {
		ALog(@"Directory creation returned: %d", success);
		sharedData.updateFail = 8;
		[self cleanUp];
		return;
	}
	
	//Extract file
	NSString *tarDest = [sharedData.workingDirectory stringByAppendingPathComponent:@"idroid.tar"];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tarDest];
	
	if(!fileExists) { 
		[[NSFileManager defaultManager] createFileAtPath:tarDest contents:nil attributes:nil];
	}
	
	success = [extractionInstance inflateGzip:sharedData.updatePackagePath toDest:tarDest];
	
	if(success < 0) {
		ALog(@"GZip extraction returned: %d", success);
		sharedData.updateFail = 2;
		[self cleanUp];
		return;
	}
	
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	//Clean up so we save 50mb
	if(sharedData.updatePackagePath) {
		[[NSFileManager defaultManager] removeItemAtPath:sharedData.updatePackagePath error:nil];
	}
	
	success = [extractionInstance extractTar:tarDest toDest:sharedData.workingDirectory];
	
	if(success < 0) {
		ALog(@"Tar extraction returned: %d", success);
		sharedData.updateFail = 3;
		[self cleanUp];
		return;
	}
	
	//Extract files to correct locations
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	success = [self addFiles];
	
	if(success < 0) {
		ALog(@"File relocation returned: %d", success);
		sharedData.updateFail = 4;
		[self cleanUp];
		return;
	}
	
	//Check dependencies
	//Special multitouch routine
	
	[self updateProgress:[NSNumber numberWithFloat:0.25] nextStage:NO];
	
	//Check if exists
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:sharedData.updateFirmwarePath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:sharedData.updateFirmwarePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	if([sharedData.updateDependencies objectForKey:@"Multitouch"]) {
		success = [self dumpMultitouch];
		
		if(success < 0) {
			ALog(@"Dumping of multitouch firmware returned: %d", success);
			sharedData.updateFail = 5;
			[self cleanUp];
			return;
		}
	}
	
	[self updateProgress:[NSNumber numberWithFloat:0.5] nextStage:NO];
	
	if([sharedData.updateDependencies objectForKey:@"WiFi"]) {
		success = [self dumpWiFi];
		
		if(success < 0) {
			ALog(@"WiFi firmware retrieval returned: %d", success);
			sharedData.updateFail = 6;
			[self cleanUp];
			return;
		}
	}
	
	[self updateProgress:[NSNumber numberWithFloat:0.75] nextStage:NO];
	
	//Clean up
	[self cleanUp];
	
	//Set installed plist
	success = [self generateInstalledPlist];
	
	if(success < 0) {
		ALog(@"Installed plist generation returned: %d", success);
		sharedData.updateFail = 7;
		[self cleanUp];
		return;
	}
	
	[UIApplication sharedApplication].idleTimerDisabled = NO; //Re-enable autolock
	
	[self checkInstalled];
	
	[self updateProgress:[NSNumber numberWithFloat:1] nextStage:NO];
}

- (void)idroidUpgrade {
	DLog(@"Upgrading iDroid");
	
	commonData* sharedData = [commonData sharedData];
	extractionInstance = [[extractionClass alloc] init];
	int success;
	
	sharedData.updateFail = 0;
	sharedData.updateStage = 0;
	
	[UIApplication sharedApplication].idleTimerDisabled = YES; //Stop autolock
	
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	NSString *match = @"*tar.gz";
	
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sharedData.workingDirectory error:nil];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
	NSArray *results = [dirContents filteredArrayUsingPredicate:predicate];
	
	if([results count] > 0) {
		DLog(@"Found downloaded package: %@ \r\nChecking MD5.", [results objectAtIndex:0]);
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
		
		NSString *pkg = [sharedData.workingDirectory stringByAppendingPathComponent:[results objectAtIndex:0]];
		NSString *md5hash = [commonInstance fileMD5:pkg];
		
		DLog(@"Found package MD5: %@", md5hash);
		
		if([sharedData.updateMD5 isEqualToString:md5hash]) {
			[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
			sharedData.updatePackagePath = pkg;
		} else {
			DLog(@"MD5 mismatch redownloading.");
			[[NSFileManager defaultManager] removeItemAtPath:pkg error:nil];
			
			sharedData.updateStage = 1;
		}
	}
	
	if(sharedData.updateStage == 1) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		getFileInstance = [[getFile alloc] initWithUrl:sharedData.updateURL directory:sharedData.workingDirectory];
		DLog(@"DEBUG: updateURL = %@", sharedData.updateURL);
		DLog(@"DEBUG: workingDirectory = %@", sharedData.workingDirectory);
		
		[getFileInstance getFileDownload:self];
		
		BOOL keepAlive = YES;
		
		do {        
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
			//Check NSURLConnection for activity
			if (getFileInstance.getFileWorking == NO) {
				keepAlive = NO;
			}
			if(sharedData.updateFail == 1) {
				DLog(@"DEBUG: Failed to get iDroid package. Cleaning up.");
				[self cleanUp];
				return;
			}
		} while (keepAlive);
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		sharedData.updatePackagePath = getFileInstance.getFilePath;
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
		
		//Calculate file MD5
		NSString *md5hash = [commonInstance fileMD5:sharedData.updatePackagePath];
		DLog(@"MD5 Hash: %@", md5hash);
		
		if(![sharedData.updateMD5 isEqualToString:md5hash]) {
			DLog(@"MD5 hash does not match, assuming download is corrupt.");
			sharedData.updateFail = 10;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	}
	
	//Extract file
	NSString *tarDest = [sharedData.workingDirectory stringByAppendingPathComponent:@"idroid.tar"];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tarDest];
	
	if(!fileExists) {
		[[NSFileManager defaultManager] createFileAtPath:tarDest contents:nil attributes:nil];
	}
	
	success = [extractionInstance inflateGzip:sharedData.updatePackagePath toDest:tarDest];
	
	if(success < 0) {
		ALog(@"GZip extraction returned: %d", success);
		sharedData.updateFail = 2;
		[self cleanUp];
		return;
	}
	
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	success = [extractionInstance extractTar:tarDest toDest:sharedData.workingDirectory];
	
	//Clean up so we save 50mb
	if(sharedData.updatePackagePath) {
		[[NSFileManager defaultManager] removeItemAtPath:sharedData.updatePackagePath error:nil];
	}
	
	if(success < 0) {
		ALog(@"Tar extraction returned: %d", success);
		sharedData.updateFail = 3;
		[self cleanUp];
		return;
	}
	
	[self updateProgress:[NSNumber numberWithInt:0] nextStage:YES];
	
	//Check if we're gonna do this delta style
	if(sharedData.upgradeUseDelta) {
		DLog(@"Delta style baby...");
		
		success = [self createDirectories:sharedData.upgradeDeltaCreateDirectories];
		
		if(success < 0) {
			ALog(@"Directory Creation returned: %d", success);
			sharedData.updateFail = 4;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithFloat:0.15] nextStage:NO];
		
		success = [self removeFiles:sharedData.upgradeDeltaRemoveFiles];
		
		if(success < 0) {
			ALog(@"File removal returned: %d", success);
			sharedData.updateFail = 5;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithFloat:0.3] nextStage:NO];
		
		success = [self moveFiles:sharedData.upgradeDeltaMoveFiles];
		
		if(success < 0) {
			ALog(@"Moving files returned: %d", success);
			sharedData.updateFail = 6;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithFloat:0.5] nextStage:NO];
		
		success = [self cherryPickFiles:sharedData.upgradeDeltaAddFiles];
		
		if(success < 0) {
			ALog(@"Cherry picking files returned: %d", success);
			sharedData.updateFail = 7;
			[self cleanUp];
			return;
		}
		
		[self updateProgress:[NSNumber numberWithFloat:0.7] nextStage:NO];
		
		if([sharedData.upgradeDeltaPostInstall length] != 0) {
			DLog(@"Post Install script needs running...");
			
			success = [self runPostInstall:sharedData.upgradeDeltaPostInstall];
			
			if(success < 0) {
				ALog(@"Post install script returned: %d", success);
				sharedData.updateFail = 8;
				[self cleanUp];
				return;
			}
		}
		
		[self updateProgress:[NSNumber numberWithFloat:0.9] nextStage:NO];
	} else {
		DLog(@"Combo update for this bad boy...");
	}
	
	//Clean up
	[self cleanUp];
	
	//Set installed plist
	success = [self updateInstalledPlist];
	
	if(success < 0) {
		ALog(@"Installed plist generation returned: %d", success);
		sharedData.updateFail = 9;
		[self cleanUp];
		return;
	}
	
	[UIApplication sharedApplication].idleTimerDisabled = NO; //Re-enable autolock
	
	[self checkInstalled];
	
	[self updateProgress:[NSNumber numberWithFloat:1] nextStage:NO];
}

- (void)idroidRemove {
	DLog(@"Removing iDroid");

	int i, count;
	commonData* sharedData = [commonData sharedData];
	
	count = [sharedData.installedFiles count];
	
	for (i=0; i<count; i++) {
		[[NSFileManager defaultManager] removeItemAtPath:[sharedData.installedFiles objectAtIndex:i] error:nil];
	}
	
	count = [sharedData.installedDependencies count];
	
	for (i=0; i<count; i++) {
		[[NSFileManager defaultManager] removeItemAtPath:[sharedData.installedDependencies objectAtIndex:i] error:nil];
	}
	
	count = [sharedData.installedDirectories count];
	
	for (i=0; i<count; i++) {
		[[NSFileManager defaultManager] removeItemAtPath:[sharedData.installedDependencies objectAtIndex:i] error:nil];
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"] error:nil];
	
	sharedData.installed = NO;
	sharedData.installedVer = nil;
	sharedData.installedAndroidVer = nil;
	sharedData.installedOpibRequired = nil;
	sharedData.installedDate = nil;
	sharedData.installedDependencies = nil;
	
	[self checkInstalled];
}

- (void)updateProgress:(NSNumber *)progress nextStage:(BOOL)next {
	commonData* sharedData = [commonData sharedData];
	
	if(next) {
		sharedData.updateStage++;
		sharedData.updateCurrentProgress = 0;
		DLog(@"Current stage: %d", sharedData.updateStage);
	}
	
	sharedData.updateOverallProgress = ([progress floatValue]/5)+((sharedData.updateStage-1)*0.2);
	sharedData.updateCurrentProgress = [progress floatValue];
}

- (void)cleanUp {
	DLog(@"Cleaning up");

	commonData* sharedData = [commonData sharedData];
	
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:sharedData.updateClean] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:@"idroid.tar"] error:nil];
	if(sharedData.updatePackagePath) {
		[[NSFileManager defaultManager] removeItemAtPath:sharedData.updatePackagePath error:nil];
	}
	
	DLog(@"Cleanup complete.");
}

- (void)checkForUpdates {
	int success;
	commonData* sharedData = [commonData sharedData];
	
	sharedData.updateCanBeInstalled = 0;
	
	DLog(@"Checking for updates");
	
	NSURL *updatePlistURL;
	
	//Grab update plist	
	if(sharedData.debugMode) {
		updatePlistURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://beta.neonkoala.co.uk/%@/bootlaceupdate.plist", sharedData.bootlaceVersion]];
	} else {
		updatePlistURL = [NSURL URLWithString:@"http://bootlace.idroidproject.org/bootlaceupdate.plist"];
	}
	NSMutableDictionary *updateDict = [NSMutableDictionary dictionaryWithContentsOfURL:updatePlistURL];
	
	if(updateDict == nil) {
		sharedData.updateCanBeInstalled = -2;
		DLog(@"Could not retrieve update plist - server problem?");
		return;
	}
	
	sharedData.latestVerDict = [updateDict objectForKey:@"LatestVersion"];
	sharedData.upgradeDict = [updateDict objectForKey:@"Upgrade"];
	
	NSDictionary *restoreDict = [updateDict objectForKey:@"Restore"];
	
	sharedData.restoreUserDataURL = [restoreDict objectForKey:@"UserDataURL"];
	sharedData.restoreUserDataPath = [restoreDict objectForKey:@"UserDataPath"];
	
	//Call func to parse plist
	success = [self parseLatestVersionPlist];
	
	if(success < 0) {
		DLog(@"Update plist could not be parsed");
	}
	
	if(sharedData.updateCanBeInstalled==1 && sharedData.installed) {
		sharedData.upgradeUseDelta = NO;
		
		if([sharedData.updateVer compare:sharedData.installedVer options:NSNumericSearch] == NSOrderedDescending) {
			DLog(@"Update %@ is newer than installed version %@", sharedData.updateVer, sharedData.installedVer);
			
			[self parseUpgradePlist];
			
			if([sharedData.upgradeDeltaReqVer isEqualToString:sharedData.installedVer]) {
				DLog(@"Delta upgrade available for %@", sharedData.upgradeDeltaReqVer);
				
				sharedData.updateCanBeInstalled = 2;
				sharedData.upgradeUseDelta = YES;
				
				if(!sharedData.bootlaceUpgradeAvailable) {
					[[UIApplication sharedApplication] setApplicationBadgeString:@"1"];
				}
			} else if([sharedData.upgradeDeltaReqVer compare:sharedData.installedVer options:NSNumericSearch] == NSOrderedAscending) {
				DLog(@"Combo upgrade available for %@ and later", sharedData.upgradeComboReqVer);
				
				sharedData.updateCanBeInstalled = 2;
				sharedData.upgradeUseDelta = NO;
				
				if(!sharedData.bootlaceUpgradeAvailable) {
					[[UIApplication sharedApplication] setApplicationBadgeString:@"1"];
				}
			} else {
				DLog(@"No valid upgrade path available. This is some seriously old sh*t.");
				
				sharedData.updateCanBeInstalled = -3;
				
				if(!sharedData.bootlaceUpgradeAvailable) {
					[[UIApplication sharedApplication] setApplicationBadgeString:@"1"];
				}
			}
		} else {
			sharedData.updateCanBeInstalled = 0;
		}
	}
}

- (void)checkInstalled {
	int success;
	commonData* sharedData = [commonData sharedData];
	
	NSString *installedPlistPath = [sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:installedPlistPath];
	
	DLog(@"%d", fileExists);
	
	if(!fileExists) { 
		sharedData.installed = NO;
	} else {
		sharedData.installed = YES;
		success = [self parseInstalledPlist];
		
		if(success<0) {
			sharedData.installed = NO;
			[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:@"installed.plist"] error:nil];
			
			ALog(@"Installed plist could not be parsed");
		}
	}
}

- (int)createDirectories:(NSArray *)directoryList {
	int i, count;
	NSError *error;
	
	count = [directoryList count];
	
	for (i=0; i<count; i++) {
		DLog(@"Creating directory at path: %@", [directoryList objectAtIndex:i]);
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:[directoryList objectAtIndex:i]]) {
			if(![[NSFileManager defaultManager] createDirectoryAtPath:[directoryList objectAtIndex:i] withIntermediateDirectories:YES attributes:nil error:&error]) {
				DLog(@"%@", [error localizedDescription]);
			
				return -1;
			}
		}
	}
	
	return 0;
}

- (int)addFiles {
	int i, count;
	NSError *error;
	commonData* sharedData = [commonData sharedData];
	
	count = [sharedData.updateFiles count];
	
	for (i=0; i<count; i++) {
		NSString *key = [NSString stringWithFormat:@"%d", i];
		NSArray *fileDetails = [sharedData.updateFiles objectForKey:key];
		
		NSString *sourcePath = [[sharedData.workingDirectory stringByAppendingPathComponent:[fileDetails objectAtIndex:0]] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]];
		NSString *destPath = [[fileDetails objectAtIndex:1] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]];
		
		DLog(@"Adding file from %@ to %@", sourcePath, destPath);
		
		if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:destPath error:&error]) {
				DLog(@"%@", [error localizedDescription]);
			}
		}
		
		if(![[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destPath error:&error]) {
			DLog(@"%@", [error localizedDescription]);
			return -1;
		}
	}
	
	return 0;
}

- (int)moveFiles:(NSDictionary *)fileList {
	int i, count;
	NSError *error;
	
	count = [fileList count];
	
	for (i=0; i<count; i++) {
		NSString *key = [NSString stringWithFormat:@"%d", i];
		NSArray *fileDetails = [fileList objectForKey:key];
		
		NSString *sourcePath = [fileDetails objectAtIndex:0];		
		NSString *destPath = [fileDetails objectAtIndex:1];
		
		DLog(@"Moving file from %@ to %@", sourcePath, destPath);
		
		if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:destPath error:&error]) {
				DLog(@"%@", [error localizedDescription]);
			}
		}
		
		if(![[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destPath error:&error]) {
			DLog(@"%@", [error localizedDescription]);
			return -1;
		}
	}
	
	return 0;
}
	
- (int)removeFiles:(NSArray *)fileList {
	int i, count;
	NSError *error;
	
	count = [fileList count];
	
	for (i=0; i<count; i++) {
		DLog(@"Removing item at path: %@", [fileList objectAtIndex:i]);
		
		if(![[NSFileManager defaultManager] removeItemAtPath:[fileList objectAtIndex:i] error:&error]) {
			DLog(@"%@", [error localizedDescription]);
			
			return -1;
		}
	}
	
	return 0;
}

- (int)cherryPickFiles:(NSArray *)fileList {
	int i, count;
	NSError *error;
	commonData* sharedData = [commonData sharedData];
	
	count = [fileList count];
	
	for (i=0; i<count; i++) {
		NSString *key = [fileList objectAtIndex:i];
		NSArray *fileDetails = [sharedData.updateFiles objectForKey:key];
		
		NSString *sourcePath = [[sharedData.workingDirectory stringByAppendingPathComponent:[fileDetails objectAtIndex:0]] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]];
		NSString *destPath = [[fileDetails objectAtIndex:1] stringByAppendingPathComponent:[fileDetails objectAtIndex:2]];
		
		DLog(@"Cherry picking file at %@ and moving to %@ - pretty neat huh?", sourcePath, destPath);
		
		if([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
			if(![[NSFileManager defaultManager] removeItemAtPath:destPath error:&error]) {
				DLog(@"%@", [error localizedDescription]);
			}
		}
		
		if(![[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destPath error:&error]) {
			DLog(@"%@", [error localizedDescription]);
			return -1;
		}
	}
	
	return 0;
}

- (int)runPostInstall:(NSString *)URL {
	DLog(@"Post install triggered.");
	
	return 0;
}

- (int)dumpMultitouch {
	commonData* sharedData = [commonData sharedData];
	
	if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F52,1"]) {	
		if(![[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"]]) {
			DLog(@"Dumping zephyr2 multitouch.");
		
			NSString *match = @"share*";
			NSString *stashPath = @"/private/var/stash";
			
			NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/private/var/stash" error:nil];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
			NSArray *results = [dirContents filteredArrayUsingPredicate:predicate];
			
			stashPath = [stashPath stringByAppendingPathComponent:[results objectAtIndex:0]];
			NSDictionary *mtprops = [NSDictionary dictionaryWithContentsOfFile:[stashPath stringByAppendingPathComponent:@"firmware/multitouch/iPhone.mtprops"]];
			
			DLog(@"Stash path: %@", stashPath);
			
			NSDictionary *z2dict = [mtprops objectForKey:@"Z2F52,1"];
			NSData *z2bin = [z2dict objectForKey:@"Constructed Firmware"];
		
			if(![z2bin writeToFile:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"] atomically:YES]) {
				return -1;
			}
		}
	} else if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z1F50,1"]) {
		NSString *match = @"share*";
		NSString *stashPath = @"/private/var/stash";
		
		NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/private/var/stash" error:nil];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
		NSArray *results = [dirContents filteredArrayUsingPredicate:predicate];
		
		stashPath = [stashPath stringByAppendingPathComponent:[results objectAtIndex:0]];
		NSDictionary *mtprops = [NSDictionary dictionaryWithContentsOfFile:[stashPath stringByAppendingPathComponent:@"firmware/multitouch/iPhone.mtprops"]];
		
		NSDictionary *z1dict = [mtprops objectForKey:@"Z1F50,1"];
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_main.bin"]]) {
			DLog(@"Dumping zephyr main multitouch.");
			
			NSData *z1main = [z1dict objectForKey:@"Firmware"];
			
			if(![z1main writeToFile:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_main.bin"] atomically:YES]) {
				return -2;
			}
		}
		if(![[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_aspeed.bin"]]) {
			DLog(@"Dumping zephyr aspeed multitouch.");
			
			NSData *z1aspeed = [z1dict objectForKey:@"A-Speed Firmware"];
			
			if(![z1aspeed writeToFile:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_aspeed.bin"] atomically:YES]) {
				return -3;
			}
		}			
	} else if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F51,1"]) {
		if(![[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"]]) {
			DLog(@"Dumping zephyr2 multitouch.");
			
			NSString *match = @"share*";
			NSString *stashPath = @"/private/var/stash";
			
			NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/private/var/stash" error:nil];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
			NSArray *results = [dirContents filteredArrayUsingPredicate:predicate];
			
			stashPath = [stashPath stringByAppendingPathComponent:[results objectAtIndex:0]];
			NSDictionary *mtprops = [NSDictionary dictionaryWithContentsOfFile:[stashPath stringByAppendingPathComponent:@"firmware/multitouch/iPod.mtprops"]];
			
			NSDictionary *z2dict = [mtprops objectForKey:@"Z2F51,1"];
			NSData *z2bin = [z2dict objectForKey:@"Constructed Firmware"];
			
			if(![z2bin writeToFile:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"] atomically:YES]) {
				return -1;
			}
		}
	}
	
	return 0;
}

- (int)dumpWiFi {
	commonData* sharedData = [commonData sharedData];
	NSDictionary *wifiDict = [sharedData.updateDependencies objectForKey:@"WiFi"];
	int i;
	int count = [wifiDict count];
	
	DLog(@"File items: %d", count);
	
	for (i=0; i<count; i++) {
		NSString *key = [NSString stringWithFormat:@"%d", i];
		NSArray *fileDetails = [wifiDict objectForKey:key];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		//Download from URL
		getFileInstance = [[getFile alloc] initWithUrl:[fileDetails objectAtIndex:1] directory:sharedData.updateFirmwarePath];
		
		// Start downloading the image with self as delegate receiver
		[getFileInstance getFileDownload:self];
		
		BOOL keepAlive = YES;
		
		do {        
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
			//Check NSURLConnection for activity
			if (getFileInstance.getFileWorking == NO) {
				keepAlive = NO;
			}
		} while (keepAlive);
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	return 0;
}

@end
