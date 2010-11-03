//
//  commonFunctions.m
//  Bootlace
//
//  Created by Neonkoala on 12/05/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "commonFunctions.h"

@implementation commonFunctions

- (BOOL)checkMains {
	BOOL mains = NO;
	
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	
	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging || [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateFull) {
		mains = YES;
		DLog(@"Device is charging.");
	}
	
	return mains;
}

- (void)toggleAirplaneMode {
	commonData* sharedData = [commonData sharedData];
	
	if(![sharedData.systemVersion isEqualToString:@"3.1.3"] && ![sharedData.systemVersion isEqualToString:@"3.1.2"]) {
		void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
	    int (*AirplaneMode)() = dlsym(libHandle, "CTPowerGetAirplaneMode");
		int (*enable)(int mode) = dlsym(libHandle, "CTPowerSetAirplaneMode");
	
		int status = AirplaneMode();
	
		if(status) {
			enable(0);
		} else {
			enable(1);
		}
	}
}

- (float)getFreeSpace {
	struct statfs stats;
	
	statfs("/private/var", &stats);
	
	DLog(@"Free space: %1.0f", (float) stats.f_bsize * stats.f_bavail);
	
	return((float) stats.f_bsize * stats.f_bavail);
}

- (NSString *)fileMD5:(NSString *)path {
	installInstance = [[installClass alloc] init];
	int i = 0;
	int read = 0;	
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
	int fileSize = [attr fileSize];
	
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
	if(handle==nil) {
		return @"NOFILE";
	}
	
	CC_MD5_CTX md5;
	CC_MD5_Init(&md5);
	
	BOOL done = NO;
	while(!done)
	{
		NSAutoreleasePool *tempPool = [[NSAutoreleasePool alloc] init]; //Create our own autorelease pool as the system is too slow to drain otherwise
		NSData *fileData = [handle readDataOfLength: 1048576];
		CC_MD5_Update(&md5, [fileData bytes], [fileData length]);
		if( [fileData length] == 0 ) done = YES;
		read += [fileData length];
		float progress = (float) read/fileSize;
		[installInstance updateProgress:[NSNumber numberWithFloat:progress] nextStage:NO];
		[tempPool drain]; //Drain it or we'll run out of memory
	}
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5_Final(digest, &md5);
	NSString* s = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
				   digest[0], digest[1],
				   digest[2], digest[3],
				   digest[4], digest[5],
				   digest[6], digest[7],
				   digest[8], digest[9],
				   digest[10], digest[11],
				   digest[12], digest[13],
				   digest[14], digest[15]];
	return s;
}

- (void)getPlatform {
	commonData* sharedData = [commonData sharedData];
	
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	sharedData.platform = platform;
    free(machine);
	
	DLog(@"Platform: %@", sharedData.platform);
	
	/**********   iPhone Simulator debug code, remove me!    *****************************/
	if ([sharedData.platform isEqualToString:@"x86_64"] || [sharedData.platform isEqualToString:@"i386"]) {
		sharedData.platform = @"iPhone1,2";
	}
	/*************************************************************************************/
	
	if([sharedData.platform isEqualToString:@"iPhone1,1"]) {
		sharedData.deviceName = @"iPhone 2G";
	} else if([sharedData.platform isEqualToString:@"iPhone1,2"]) {
		sharedData.deviceName = @"iPhone 3G";
	} else if([sharedData.platform isEqualToString:@"iPod1,1"]) {
		sharedData.deviceName = @"iPod 1G";
	} else {
		sharedData.deviceName = @"Unknown";
	}
}

- (void)getSystemVersion {
	commonData* sharedData = [commonData sharedData];
	
	sharedData.systemVersion = [[UIDevice currentDevice] systemVersion];
	
	DLog(@"iOS Version: %@", sharedData.systemVersion);
}

- (void)firstLaunch {
	UIAlertView *launchAlert;
	launchAlert = [[[UIAlertView alloc] initWithTitle:@"Welcome" message:@"Welcome to Bootlace.\r\n\r\nThe iDroid tab will allow you to install iDroid on your device.\r\n\r\nQuickBoot allows you to reboot your device into the selected OS.\r\n\r\nFinally the OpeniBoot tab allows install and configuration of OpeniBoot." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[launchAlert show];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunTwice"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)sendError:(NSString *)alertMsg {
	UIAlertView *errorAlert;
	errorAlert = [[[UIAlertView alloc] initWithTitle:@"Error" message:alertMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[errorAlert show];
}

- (void)sendWarning:(NSString *)alertMsg {
	commonData* sharedData = [commonData sharedData];
	
	UIAlertView *warningAlert;
	warningAlert = [[[UIAlertView alloc] initWithTitle:@"Warning" message:alertMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[warningAlert setTag:10];
	[warningAlert show];
	
	sharedData.warningLive = YES;
}

- (void)sendTerminalError:(NSString *)alertMsg {
	UIAlertView *errorAlert;
	errorAlert = [[[UIAlertView alloc] initWithTitle:@"Error" message:alertMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[errorAlert setTag:1];
	[errorAlert show];
}

- (void)sendConfirmation:(NSString *)alertMsg withTag:(int)tag {
	UIAlertView *confirmAlert;
	confirmAlert = [[[UIAlertView alloc] initWithTitle:@"Warning" message:alertMsg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil] autorelease];
	[confirmAlert setTag:tag];
	[confirmAlert show];
}

- (void)sendSuccess:(NSString *)alertMsg {
	UIAlertView *successAlert;
	successAlert = [[[UIAlertView alloc] initWithTitle:@"Success" message:alertMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[successAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	opibInstance = [[OpeniBootClass alloc] init];
	
	switch (alertView.tag) {
		//Fatal error terminate app
		case 1:
			exit(0);
			break;
		
		//Confirm reboot, call android setter
		case 2:
			if(buttonIndex==1) {
				int success = [opibInstance opibRebootAndroid];
				
				switch (success) {
					case 0:
						reboot(0);
						break;
					case -1:
						[self sendError:@"NVRAM could not be accessed.\r\nReboot failed."];
						break;
					case -2:
						[self sendError:@"Attempted to write invalid data to NVRAM.\r\nReboot failed."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Confirm reboot, call console setter
		case 3:
			if(buttonIndex==1){
				int success = [opibInstance opibRebootConsole];
				
				switch (success) {
					case 0:
						reboot(0);
						break;
					case -1:
						[self sendError:@"NVRAM could not be accessed.\r\nReboot failed."];
						break;
					case -2:
						[self sendError:@"Attempted to write invalid data to NVRAM.\r\nReboot failed."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Confirm backup, create it
		case 4:
			if(buttonIndex==1){
				int success = [opibInstance opibBackupConfig];
				
				switch (success) {
					case 0:
						[self sendSuccess:@"NVRAM configuration successfully backed up."];
						break;
					case -1:
						[self sendError:@"Backup failed.\r\nNVRAM could not be accessed."];
						break;
					case -2:
						[self sendError:@"Backup failed.\r\nExisting backup could not be removed."];
						break;
					case -3:
						[self sendError:@"Backup failed.\r\nBackup could not be saved."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Confirm restore, restore it
		case 5:
			if(buttonIndex==1){
				int success = [opibInstance opibRestoreConfig];
				
				switch (success) {
					case 0:
						[self sendSuccess:@"NVRAM configuration successfully restored."];
						break;
					case -1:
						[self sendError:@"Restore failed.\r\nNVRAM could not be accessed."];
						break;
					case -2:
						[self sendError:@"Restore failed.\r\nNVRAM backup could not be read."];
						break;
					case -3:
						[self sendTerminalError:@"NVRAM restored but reloading settings failed. Try relaunching the app."];
						break;
					case -4:
						[self sendTerminalError:@"NVRAM restored but reloading settings failed. Try relaunching the app."];
						break;
					case -5:
						[self sendTerminalError:@"NVRAM restored but reloading settings failed. Try relaunching the app."];
						break;
					case -6:
						[self sendTerminalError:@"NVRAM restored but reloading settings failed. Try relaunching the app."];
						break;
					case -7:
						[self sendTerminalError:@"NVRAM restored but reloading settings failed. Try relaunching the app."];
						break;
					case -8:
						[self sendTerminalError:@"NVRAM restored but an unknown error occurred."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Confirm reset, apply
		case 6:
			if(buttonIndex==1){
				int success = [opibInstance opibResetConfig];
				
				switch (success) {
					case 0:
						[self sendSuccess:@"OpeniBoot settings successfully reset to defaults."];
						break;
					case -1:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nNVRAM could not be accessed."];
						break;
					case -2:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nInvalid NVRAM configuration."];
						break;
					case -3:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nExisting NVRAM backup could not be removed."];
						break;	
					case -4:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -5:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -6:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -7:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -8:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -9:
						[self sendTerminalError:@"OpeniBoot settings reset but an unknown error occurred."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Resetting Oib settings due to corruption
		case 8:
			if(buttonIndex==0) {
				exit(0);
			} else if(buttonIndex==1) {
				int success = [opibInstance opibResetConfig];
				
				switch (success) {
					case 0:
						[self sendSuccess:@"OpeniBoot settings successfully reset to defaults."];
						break;
					case -1:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nNVRAM could not be accessed."];
						break;
					case -2:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nInvalid NVRAM configuration."];
						break;
					case -3:
						[self sendError:@"OpeniBoot settings could not be reset.\r\nExisting NVRAM backup could not be removed."];
						break;	
					case -4:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -5:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -6:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -7:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -8:
						[self sendTerminalError:@"OpeniBoot settings reset but reloading failed. Try relaunching the app."];
						break;
					case -9:
						[self sendTerminalError:@"OpeniBoot settings reset but an unknown error occurred."];
						break;
					default:
						break;
				}
			}
			break;
			
		//Warning, set trigger for loops
		case 10:
			if(buttonIndex==0) {
				commonData* sharedData = [commonData sharedData];
				sharedData.warningLive = NO;
			}
			
			//Default
		default:
			DLog(@"Unknown UIAlertView tag: %d", alertView.tag);
	}		
}


@end
