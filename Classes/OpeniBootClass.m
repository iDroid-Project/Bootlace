//
//  OpeniBootClass.m
//  BootlaceV2
//
//  Created by Neonkoala on 25/09/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import "OpeniBootClass.h"


@implementation OpeniBootClass

@synthesize llbPath, iBootPath, openibootPath, deviceDict, iBootPatches, LLBPatches, kernelPatches;

char endianness = 1;

//Opib Install stuffs

- (void)opibOperation:(NSNumber *)operation {
	int status;
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	[UIApplication sharedApplication].idleTimerDisabled = YES; //Stop autolock
	
	//Reset vars
	sharedData.opibUpdateFail = 0;
	sharedData.opibUpdateStage = 0;
	sharedData.updateOverallProgress = 0;
	
	//Stage 1
	sharedData.opibUpdateStage = 1;
	
	[self opibUpdateProgress:0];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	status = [self opibGetNORFromManifest];
	
	if(status < 0) {
		DLog(@"opibGetNORFromManifest returned: %d", status);
		sharedData.opibUpdateFail = 1;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		return;
	}
	
	if([operation intValue] != 3) {
		status = [self opibGetOpeniBoot];
	
		if(status < 0) {
			DLog(@"opibGetOpeniBoot returned: %d", status);
			sharedData.opibUpdateFail = 4;
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
			return;
		}
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self opibUpdateProgress:1];
	
	//Stage 2
	sharedData.opibUpdateStage = 2;
	
	if([operation intValue] == 3) {
		status = [self opibPatchNORFiles:NO];
	} else {
		status = [self opibPatchNORFiles:YES];
	}
	
	if(status < 0) {
		DLog(@"opibPatchNORFiles returned: %d", status);
		sharedData.opibUpdateFail = 3;
		return;
	}
	
	if([operation intValue] != 3) {
		status = [self opibEncryptIMG3:openibootPath to:[sharedData.workingDirectory stringByAppendingPathComponent:@"openiboot.img3"] with:iBootPath key:[iBootPatches objectForKey:@"Key"] iv:[iBootPatches objectForKey:@"IV"] type:NO];
	
		if(status < 0) {
			DLog(@"opibEncryptIMG3 returned: %d", status);
			sharedData.opibUpdateFail = 5;
			return;
		}
	}
	
	//Remove orig iBoot
	if(![[NSFileManager defaultManager] removeItemAtPath:iBootPath error:nil] || ![[NSFileManager defaultManager] removeItemAtPath:llbPath error:nil]) {
		DLog(@"Could not remove vanilla iBoot/LLB ready for replacement");
		sharedData.opibUpdateFail = 6;
		return;
	}
	
	if(![[NSFileManager defaultManager] moveItemAtPath:[iBootPath stringByAppendingPathExtension:@"encrypted"] toPath:iBootPath error:nil] || ![[NSFileManager defaultManager] moveItemAtPath:[llbPath stringByAppendingPathExtension:@"encrypted"] toPath:llbPath error:nil]) {
		DLog(@"Could not move files to original filename");
		sharedData.opibUpdateFail = 7;
		return;
	}
	
	[self opibUpdateProgress:1];
	
	//Stage 3
	sharedData.opibUpdateStage = 3;
	
	[commonInstance toggleAirplaneMode];
	
	if([operation intValue] == 3) {
		status = [self opibFlashManifest:YES];
	} else {
		status = [self opibFlashManifest:NO];
	}
	
	[commonInstance toggleAirplaneMode];
	 
	if(status < 0) {
		DLog(@"opibFlashManifest returned: %d", status);
		sharedData.opibUpdateFail = 8;
		return;
	}
	
	//Stage 4 - Config
	sharedData.opibUpdateStage = 4;
	
	[self opibUpdateProgress:0];
	
	if([operation intValue] != 3) {
		status = [self opibSetVersion:sharedData.opibUpdateVersion];
	
		if(status < 0) {
			DLog(@"opibSetVersion returned: %d", status);
			sharedData.opibUpdateFail = 9;
		}
	} else {
		if(![[NSFileManager defaultManager] removeItemAtPath:@"/openiboot" error:nil]) {
			DLog(@"Could not remove installed flag.");
			sharedData.opibUpdateFail = 9;
		}
	}
	
	[self opibUpdateProgress:0.333];
	
	status = [self opibResetConfig];
	
	if(status < 0) {
		DLog(@"opibResetConfig returned: %d", status);
		sharedData.opibUpdateFail = 10;
		return;
	}
	
	[self opibUpdateProgress:0.666];
	
	if([operation intValue] == 2) {
		[self opibCheckInstalled];
	}
	
	[self opibCleanUp];
	
	[UIApplication sharedApplication].idleTimerDisabled = NO; //Re-enable autolock
	
	[self opibUpdateProgress:1];
}

- (int)opibParseUpdatePlist {
	commonData* sharedData = [commonData sharedData];
	DLog(@"Parsing OpeniBoot update plist");
	
	if([deviceDict count]==0) {
		DLog(@"OpeniBoot plist invalid");
		return -1;
	}
	
	sharedData.opibUpdateBootlaceRequired = [deviceDict objectForKey:@"BootlaceRequired"];
	sharedData.opibUpdateReleaseDate = [deviceDict objectForKey:@"ReleaseDate"];
	sharedData.opibUpdateURL = [deviceDict objectForKey:@"URL"];
	sharedData.opibUpdateVersion = [deviceDict objectForKey:@"Version"];
	sharedData.opibUpdateCompatibleFirmware = [deviceDict objectForKey:@"CompatibleFirmware"];
	
	return 0;
}

- (int)opibGetNORFromManifest {
	int i, items;
	float progress;
	unsigned char* data;
	commonData* sharedData = [commonData sharedData];
	
	DLog(@"Getting NOR files from Apple servers. IPSW: %@", sharedData.opibUpdateIPSWURL);
	
	ZipInfo* info = PartialZipInit([sharedData.opibUpdateIPSWURL cStringUsingEncoding:NSUTF8StringEncoding]);
	if(!info)
	{
		DLog(@"Cannot retrieve IPSW from: %@", sharedData.opibUpdateIPSWURL);
		return -1;
	}
	
	items = [sharedData.opibUpdateManifest count];
	
	for(i=0; i<items; i++) {
		//Skip openiboot from manifest as Apple doesn't include it - gits
		if(i!=1) {
			NSString *itemPath = [sharedData.opibUpdateFirmwarePath stringByAppendingPathComponent:[sharedData.opibUpdateManifest objectAtIndex:i]];
			NSString *destPath = [sharedData.workingDirectory stringByAppendingPathComponent:[sharedData.opibUpdateManifest objectAtIndex:i]];
		
			DLog(@"Grabbing firmware at path: %@", itemPath);
	
			CDFile* file = PartialZipFindFile(info, [itemPath cStringUsingEncoding:NSUTF8StringEncoding]);
			if(!file)
			{
				DLog(@"Cannot find firmware.");
				return -2;
			}
		
			data = PartialZipGetFile(info, file);
			int dataLen = file->size; 
			
			NSLog(@"dataLen: %d", dataLen);
		
			NSData *itemBin = [NSData dataWithBytes:data length:dataLen];
	
			if([itemBin length]>0) {
				NSLog(@"Got NOR file %d", i);
			}
			
			if(![itemBin writeToFile:destPath atomically:YES]) {
				DLog(@"Could not write IMG3 to file.");
				return -3;
			}
			
			progress = (float)(i+1)/(items+3);
			[self opibUpdateProgress:progress];
	
			free(data);
		}
	}
	
	PartialZipRelease(info);
	
	return 0;
}

- (int)opibGetFirmwareBundle {
	commonData* sharedData = [commonData sharedData];
	NSError *error;
	int statusCode;
	
	NSString *bundleURL = [sharedData.opibUpdateCompatibleFirmware objectForKey:sharedData.systemVersion];
	
	DLog(@"Grabbing firmware bundle %@", bundleURL);
	
	NSDictionary *bundleInfo = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[bundleURL stringByAppendingPathComponent:@"Info.plist"]]];
	if([bundleInfo count] < 1) {
		return -1;
	}
	
	sharedData.opibUpdateFirmwarePath = [bundleInfo objectForKey:@"FirmwarePath"];
	sharedData.opibUpdateIPSWURL = [bundleInfo objectForKey:@"URL"];
	sharedData.opibUpdateVerifyMD5 = [bundleInfo objectForKey:@"VerifyMD5"];
	sharedData.opibUpdateManifest = [bundleInfo objectForKey:@"Manifest"];
	sharedData.opibUpdateKernelPath = [bundleInfo objectForKey:@"KernelPath"];
	
	NSDictionary *firmwarePatches = [bundleInfo objectForKey:@"FirmwarePatches"];
	
	LLBPatches = [firmwarePatches objectForKey:@"LLB"];
	iBootPatches = [firmwarePatches objectForKey:@"iBoot"];
	
	//Get files
	NSString *urlString = [NSString stringWithFormat:@"%@/%@", bundleURL, [LLBPatches objectForKey:@"Patch"]];
	NSURL *URL = [NSURL URLWithString:urlString];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:URL];
	[request setDownloadDestinationPath:[sharedData.workingDirectory stringByAppendingPathComponent:[LLBPatches objectForKey:@"Patch"]]];
	[request startSynchronous];
	
	error = [request error];
	statusCode = [request responseStatusCode];
	
	if(statusCode >= 400) {
		DLog(@"HTTP bad response: %d", statusCode);
		return -2;
	} else if(error) {
		DLog(@"Grabbing LLB Patch failed. NSError: %@", [error localizedDescription]);
		return -2;
	}
	
	[self opibUpdateProgress:0.875];
	
	urlString = [NSString stringWithFormat:@"%@/%@", bundleURL, [iBootPatches objectForKey:@"Patch"]];
	URL = [NSURL URLWithString:urlString];
	
	request = [ASIHTTPRequest requestWithURL:URL];
	[request setDownloadDestinationPath:[sharedData.workingDirectory stringByAppendingPathComponent:[iBootPatches objectForKey:@"Patch"]]];
	[request startSynchronous];
	
	error = [request error];
	statusCode = [request responseStatusCode];
	
	if(statusCode >= 400) {
		DLog(@"HTTP bad response: %d", statusCode);
		return -3;
	} else if(error) {
		DLog(@"Grabbing LLB Patch failed. NSError: %@", [error localizedDescription]);
		return -3;
	}
	
	[self opibUpdateProgress:0.9375];
	
	return 0;
}

- (int)opibGetOpeniBoot {
	commonData* sharedData = [commonData sharedData];
	
	NSURL *URL = [NSURL URLWithString:sharedData.opibUpdateURL];
	openibootPath = [sharedData.workingDirectory stringByAppendingPathComponent:@"openiboot.bin"];
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:URL];
	[request setDownloadDestinationPath:openibootPath];
	[request startSynchronous];
	
	NSError *error = [request error];
	int statusCode = [request responseStatusCode];
	
	if(statusCode >= 400) {
		DLog(@"HTTP bad response: %d", statusCode);
		return -2;
	} else if(error) {
		DLog(@"Grabbing LLB Patch failed. NSError: %@", [error localizedDescription]);
		return -2;
	}
	
	return 0;
}

- (int)opibSetVersion:(NSString *)version {
	if([[NSFileManager defaultManager] fileExistsAtPath:@"/openiboot"]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:@"/openiboot" error:nil]) {
			DLog(@"Could not remove old OpeniBoot versioning file");
			return -1;
		}
	}
	
	if(![version writeToFile:@"/openiboot" atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
		DLog(@"Could not write OpeniBoot versioning information");
		return -2;
	}
	
	return 0;
}

- (int)opibFlashManifest:(BOOL)remove {
	int i, items, success;
	float progress;
	mach_port_t masterPort;
	kern_return_t k_result;
	io_service_t norService;
	io_connect_t norServiceConnection;
	
	commonData* sharedData = [commonData sharedData];
	
	items = [sharedData.opibUpdateManifest count];
	
	if(items < 1) {
		DLog(@"Haha, thought you could trick me with an empty Manifest? Not this time bitch.");
		return -1;
	}
	
	k_result = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if (k_result) {
		DLog(@"IOMasterPort failed: 0x%X\n", k_result);
		return -2;
	}
	
	norService = [self opibGetIOService:@"AppleImage3NORAccess"];
	
	if (norService == 0) {
		DLog(@"opibGetIOService failed!");
		return -3;
	}
	
	k_result = IOServiceOpen(norService, mach_task_self_, 0, &norServiceConnection);
	if (k_result != KERN_SUCCESS) {
		DLog(@"IOServiceOpen failed: 0x%X\n", k_result);
		return -4;		
	}
	
	//Check all files exist first
	for(i=0; i<items; i++) {
		if(remove && i==1) {
			DLog(@"Skipping over OpeniBoot");
		} else {
			NSString *img3Path = [sharedData.workingDirectory stringByAppendingPathComponent:[sharedData.opibUpdateManifest objectAtIndex:i]];
		
			if(![[NSFileManager defaultManager] fileExistsAtPath:img3Path]) {
				DLog(@"IMG3 doesn't exist at path %@! Aborting before flash!");
				return -5;
			}
		}
	}
	
	//Lets flash them before that damn cat of mine eats them
	for(i=0; i<items; i++) {
		if(remove && i==1) {
			DLog(@"Skipping over OpeniBoot");
		} else {
			NSString *img3Path = [sharedData.workingDirectory stringByAppendingPathComponent:[sharedData.opibUpdateManifest objectAtIndex:i]];
		
			if(i==0) {
				success = [self opibFlashIMG3:img3Path usingService:norServiceConnection type:YES];
			} else {
				success = [self opibFlashIMG3:img3Path usingService:norServiceConnection type:NO];
			}
		
			if(success < 0) {
				DLog(@"Flashing IMG3 failed with: %d", success);
				return -6;
			}
		
			progress = (float)(i+1)/items;
			[self opibUpdateProgress:progress];
		}
	}
	
	return 0;
}

- (int)opibFlashIMG3:(NSString *)path usingService:(io_connect_t)norServiceConnection type:(BOOL)isLLB {
	NSFileHandle *norHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	NSLog(@"Flashing %@ %@ image", path, (isLLB ? @"LLB" : @"NOR"));
	
	int fd = [norHandle fileDescriptor];
	size_t imgLen = lseek(fd, 0, SEEK_END);
	NSLog(@"Image length = %lu", imgLen);
	lseek(fd, 0, SEEK_SET);
	
	void *mappedImage = mmap(NULL, imgLen, PROT_READ | PROT_WRITE, MAP_ANON | VM_FLAGS_PURGABLE, -1, 0);
	if(mappedImage == MAP_FAILED) {
		int err = errno;
		NSLog(@"mmap (size = %ld) failed: %s", imgLen, strerror(err));
		return err;
	}
	
	int cbRead = read(fd, mappedImage, imgLen);
	if (cbRead != imgLen) {
		int err = errno;
		NSLog(@"cbRead(%u) != imgLen(%lu); err 0x%x", cbRead, imgLen, err);
		return err;
	}
	
	kern_return_t result = IOConnectCallStructMethod(norServiceConnection, isLLB ? 0 : 1, mappedImage, imgLen, NULL, 0);
	if(result != KERN_SUCCESS) {
		NSLog(@"IOConnectCallStructMethod failed: 0x%x\n", result);
	}
	
	munmap(mappedImage, imgLen);
	
	return result;
}

- (int)opibEncryptIMG3:(NSString *)srcPath to:(NSString *)dstPath with:(NSString *)templateIMG3 key:(NSString *)key iv:(NSString *)iv type:(BOOL)isLLB {
	//Sanity checks
	if(![[NSFileManager defaultManager] fileExistsAtPath:srcPath] || [[NSFileManager defaultManager] fileExistsAtPath:dstPath] || ![[NSFileManager defaultManager] fileExistsAtPath:templateIMG3]) {
		DLog(@"File missing and/or exists at destination/source. Aborting rather like your mother should have done before birth.");
		return -1;
	}
	if(!isLLB) {
		if([key length] == 0 || [iv length] == 0) {
			DLog(@"Seriously? That's gotta be an invalid key/iv. I didn't get off the last banana boat y'know...");
			return -2;
		}
	}
	
	//This is a very hacky workaround for Apple breaking NSTask waitUntilDone in 4.x - NSTask leaves zombies so never returns when done leaving us in limbo. Solution: back to basics, fork & exec
	
	pid_t pid;
	int rv;
	int	commpipe[2];
	
	pipe(commpipe);
	pid = fork();
	
	NSString *xpwnPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"xpwntool"];
	
	if(pid) {
		dup2(commpipe[1],1);
		close(commpipe[0]);
		
		setvbuf(stdout,(char*)NULL,_IONBF,0);
		
		wait(&rv);
	} else {
		dup2(commpipe[0],0);
		close(commpipe[1]);
		
		if(isLLB) {
			rv = execl([xpwnPath cStringUsingEncoding:NSUTF8StringEncoding], "xpwntool", [srcPath cStringUsingEncoding:NSUTF8StringEncoding], [dstPath cStringUsingEncoding:NSUTF8StringEncoding], "-t", [templateIMG3 cStringUsingEncoding:NSUTF8StringEncoding], NULL);
		} else {
			rv = execl([xpwnPath cStringUsingEncoding:NSUTF8StringEncoding], "xpwntool", [srcPath cStringUsingEncoding:NSUTF8StringEncoding], [dstPath cStringUsingEncoding:NSUTF8StringEncoding], "-t", [templateIMG3 cStringUsingEncoding:NSUTF8StringEncoding], "-k", [key cStringUsingEncoding:NSUTF8StringEncoding], "-iv", [iv cStringUsingEncoding:NSUTF8StringEncoding], NULL);
		}
	}
	
	if(rv!=0) {
		DLog(@"xpwntool returned: %d", rv);
		return -3;
	}
	
	return 0;
}

- (int)opibDecryptIMG3:(NSString *)srcPath to:(NSString *)dstPath key:(NSString *)key iv:(NSString *)iv type:(BOOL)isLLB {
	//Sanity checks	
	if(![[NSFileManager defaultManager] fileExistsAtPath:srcPath] || [[NSFileManager defaultManager] fileExistsAtPath:dstPath]) {
		DLog(@"File missing and/or exists at destination/source. Aborting rather like your mother should have done before birth.");
		return -1;
	}
	if(!isLLB) {
		if([key length] == 0 || [iv length] == 0) {
			DLog(@"Seriously? That's gotta be an invalid key/iv. I didn't get off the last banana boat y'know...");
			return -2;
		}
	}
	
	//This is a very hacky workaround for Apple breaking NSTask waitUntilDone in 4.x - NSTask leaves zombies so never returns when done leaving us in limbo. Solution: back to basics, fork & exec
	
	pid_t pid;
	int rv;
	int	commpipe[2];
	
	pipe(commpipe);
	pid = fork();
	
	NSString *xpwnPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"xpwntool"];
	
	if(pid) {
		dup2(commpipe[1],1);
		close(commpipe[0]);
		
		setvbuf(stdout,(char*)NULL,_IONBF,0);
		
		wait(&rv);
	} else {
		dup2(commpipe[0],0);
		close(commpipe[1]);
						
		if(isLLB) {
			rv = execl([xpwnPath cStringUsingEncoding:NSUTF8StringEncoding], "xpwntool", [srcPath cStringUsingEncoding:NSUTF8StringEncoding], [dstPath cStringUsingEncoding:NSUTF8StringEncoding], NULL);
		} else {
			rv = execl([xpwnPath cStringUsingEncoding:NSUTF8StringEncoding], "xpwntool", [srcPath cStringUsingEncoding:NSUTF8StringEncoding], [dstPath cStringUsingEncoding:NSUTF8StringEncoding], "-k", [key cStringUsingEncoding:NSUTF8StringEncoding], "-iv", [iv cStringUsingEncoding:NSUTF8StringEncoding], NULL);
		}
	}
	
	if(rv!=0) {
		DLog(@"xpwntool returned: %d", rv);
		return -3;
	}
	
	return 0;
}

- (int)opibPatchNORFiles:(BOOL)withIbox {
	int status;
	bsPatchInstance = [[BSPatch alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	DLog(@"Patching LLB first...");
	
	llbPath = [sharedData.workingDirectory stringByAppendingPathComponent:[LLBPatches objectForKey:@"File"]];
	NSString *llbPatchPath = [sharedData.workingDirectory stringByAppendingPathComponent:[LLBPatches objectForKey:@"Patch"]];
	status = [self opibDecryptIMG3:llbPath to:[llbPath stringByAppendingPathExtension:@"decrypted"] key:nil iv:nil type:YES];
	
	if(status < 0) {
		DLog(@"opibDecryptIMG3 returned %d on LLB", status);
		return -1;
	}
	
	[self opibUpdateProgress:0.125];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[llbPath stringByAppendingPathExtension:@"decrypted"]]) {
		status = [bsPatchInstance bsPatch:[llbPath stringByAppendingPathExtension:@"decrypted"] withPatch:llbPatchPath];
		if(status < 0) {
			DLog(@"Patching LLB failed with: %d", status);
			return -2;
		}
	} else {
		DLog(@"Decrypted LLB does not exist! Time to crap ourselves complaining..");
		return -3;
	}
	
	[self opibUpdateProgress:0.25];
	
	status = [self opibEncryptIMG3:[llbPath stringByAppendingPathExtension:@"decrypted.patched"] to:[llbPath stringByAppendingPathExtension:@"encrypted"] with:llbPath key:nil iv:nil type:YES];
		
	if(status < 0) {
		DLog("opibEncryptIMG3 returned %d on LLB", status);
		return -4;
	}
	
	[self opibUpdateProgress:0.375];
	
	DLog(@"Patching iBoot...");
	
	iBootPath = [sharedData.workingDirectory stringByAppendingPathComponent:[iBootPatches objectForKey:@"File"]];
	NSString *iBootPatchPath = [sharedData.workingDirectory stringByAppendingPathComponent:[iBootPatches objectForKey:@"Patch"]];
	status = [self opibDecryptIMG3:iBootPath to:[iBootPath stringByAppendingPathExtension:@"decrypted"] key:[iBootPatches objectForKey:@"Key"] iv:[iBootPatches objectForKey:@"IV"] type:NO];
	
	if(status < 0) {
		DLog(@"opibDecryptIMG3 returned %d on iBoot", status);
		return -5;
	}
	
	[self opibUpdateProgress:0.5];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[iBootPath stringByAppendingPathExtension:@"decrypted"]]) {
		status = [bsPatchInstance bsPatch:[iBootPath stringByAppendingPathExtension:@"decrypted"] withPatch:iBootPatchPath];
		if(status < 0) {
			DLog(@"Patching iBoot failed with: %d", status);
			return -6;
		}
	} else {
		DLog(@"Decrypted iBoot does not exist! Time to crap ourselves complaining..");
		return -7;
	}
	
	[self opibUpdateProgress:0.625];
	
	status = [self opibEncryptIMG3:[iBootPath stringByAppendingPathExtension:@"decrypted.patched"] to:[iBootPath stringByAppendingPathExtension:@"encrypted"] with:iBootPath key:nil iv:nil type:YES];
	
	if(status < 0) {
		DLog(@"opibEncryptIMG3 returned %d on iBoot", status);
		return -8;
	}
	
	[self opibUpdateProgress:0.75];
	
	//Patch iBoot to ibox or we haz conflicts
	if(withIbox) {
		status = [self opibPatchIbox:[iBootPath stringByAppendingPathExtension:@"encrypted"]];
	
		if(status < 0) {
			DLog(@"Failed to patch iBoot to ibox");
			sharedData.opibUpdateFail = -4;
			return -9;
		}
	}
	
	[self opibUpdateProgress:0.875];
	
	DLog(@"Patching done.");
	
	return 0;
}

- (int)opibPatchIbox:(NSString *)path {
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
	
	if(!handle) {
		DLog(@"Could not open file at %@ for writing.", path);
		return -1;
	}
	
	[handle seekToFileOffset:16];
	[handle writeData:[NSData dataWithBytes:"xobi" length:4]];
	
	[handle closeFile]; 
	
	return 0;
}

- (void)opibCheckForUpdates {
	int success;
	commonData* sharedData = [commonData sharedData];
	
	sharedData.opibCanBeInstalled = 0;
	
	DLog(@"Checking for OpeniBoot updates");
	
	NSURL *opibUpdatePlistURL;
	
	//Grab update plist	
	if(sharedData.debugMode) {
		opibUpdatePlistURL = [NSURL URLWithString:@"http://beta.neonkoala.co.uk/openiboot.plist"];
	} else {
		opibUpdatePlistURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://bootlace.me/%@/openiboot.plist", sharedData.bootlaceVersion]];
	}
	sharedData.opibDict = [NSMutableDictionary dictionaryWithContentsOfURL:opibUpdatePlistURL];
	
	if([sharedData.opibDict count] == 0) {
		sharedData.opibCanBeInstalled = -1;
		DLog(@"Could not retrieve openiboot update plist - server problem?");
		return;
	}
	
	deviceDict = [sharedData.opibDict objectForKey:sharedData.platform];
	
	//Call func to parse plist
	success = [self opibParseUpdatePlist];
	
	if(success < 0) {
		DLog(@"Update plist could not be parsed");
		sharedData.opibCanBeInstalled = -2;
	}
	
	if(sharedData.opibInstalled) {
		if([sharedData.opibUpdateVersion compare:sharedData.opibVersion options:NSNumericSearch] == NSOrderedDescending) {
			sharedData.opibCanBeInstalled = 1;
		} else if([sharedData.opibUpdateVersion isEqualToString:sharedData.opibVersion] || [sharedData.opibUpdateVersion compare:sharedData.opibVersion options:NSNumericSearch] == NSOrderedAscending) {
			sharedData.opibCanBeInstalled = 2;
		}
	}
}

- (void)opibCheckInstalled {
	int status;
	commonData* sharedData = [commonData sharedData];
	nvramInstance = [[nvramFunctions alloc] init];
	
	//Check for version file
	if(![[NSFileManager defaultManager] fileExistsAtPath:@"/openiboot"]) {
		sharedData.opibInstalled = NO;
		return;
	}
	
	//Check opib version
	NSString *opibVersion = [NSString stringWithContentsOfFile:@"/openiboot" encoding:NSUTF8StringEncoding error:nil];
	
	if([opibVersion length]==0) {
		DLog(@"Could not read OpeniBoot version.");
		sharedData.opibInstalled = NO;
		return;
	}
	
	sharedData.opibInstalled = YES;
	sharedData.opibVersion = opibVersion;
	
	//Check for NVRAM backup before we do anything
	if(![[NSFileManager defaultManager] fileExistsAtPath:sharedData.opibBackupPath]) {
		status = [nvramInstance backupNVRAM];
		
		switch (status) {
			case 0:
				break;
			case -1:
				sharedData.opibInitStatus = -1;
				return;
			case -2:
				sharedData.opibInitStatus = -6;
				return;
			case -3:
				sharedData.opibInitStatus = -2;
				return;
			default:
				sharedData.opibInitStatus = -5;
				return;
		}
	}
	
	//Dump NVRAM config
	status = [nvramInstance dumpNVRAM];
	
	switch (status) {
		case 0:
			break;
		case -1:
			sharedData.opibInitStatus = -3;
			return;
		case -2:
			sharedData.opibInitStatus = -4;
			return;
		case -3:
			sharedData.opibInitStatus = 1;
			return;
		default:
			sharedData.opibInitStatus = -5;
			return;
	}
	
	sharedData.opibInitStatus = 0;
}

- (void)opibUpdateProgress:(float)subProgress {
	commonData* sharedData = [commonData sharedData];
	
	sharedData.updateOverallProgress = (subProgress/4) + ((sharedData.opibUpdateStage-1) * 0.25);
}

- (void)opibCleanUp {
	int i, items;
	commonData* sharedData = [commonData sharedData];
	
	//Remove patched/decrypted LLB & iBoot
	[[NSFileManager defaultManager] removeItemAtPath:[iBootPath stringByAppendingPathExtension:@"decrypted"] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[iBootPath stringByAppendingPathExtension:@"decrypted.patched"] error:nil];
	
	[[NSFileManager defaultManager] removeItemAtPath:[llbPath stringByAppendingPathExtension:@"decrypted"] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[llbPath stringByAppendingPathExtension:@"decrypted.patched"] error:nil];
	
	//Remove raw openiboot
	if([openibootPath length] > 0) {
		[[NSFileManager defaultManager] removeItemAtPath:openibootPath error:nil];
	}	
	
	//Remove nor files
	items = [sharedData.opibUpdateManifest count];
	
	for(i=0; i<items; i++) {
		[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:[sharedData.opibUpdateManifest objectAtIndex:i]] error:nil];
	}
	
	//Remove patches
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:[LLBPatches objectForKey:@"Patch"]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.workingDirectory stringByAppendingPathComponent:[iBootPatches objectForKey:@"Patch"]] error:nil];
	
	return;
}

- (io_service_t)opibGetIOService:(NSString *)name {
	CFMutableDictionaryRef matching;
	io_service_t service;
	
	matching = IOServiceMatching([name cStringUsingEncoding:NSUTF8StringEncoding]);
	if(matching == NULL) {
		DLog(@"Unable to create matching dictionary for class '%@'", name);
		return 0;
	}
	
	do {
		CFRetain(matching);
		service = IOServiceGetMatchingService(kIOMasterPortDefault, matching);
		if(service) {
			break;
		}
		
		DLog(@"Waiting for matching IOKit service: %@", name);
		sleep(1);
		CFRelease(matching);
	} while(!service);
	
	CFRelease(matching);
	
	return service;
}

//Kernelcache Patching stuffs

- (NSString *)opibKernelMD5:(NSString *)path {
	NSString *md5;
	u_int32_t size;
	
	commonInstance = [[commonFunctions alloc] init];
	
	NSFileHandle *kHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	[kHandle seekToFileOffset:60];
	
	NSData *rawSize = [kHandle readDataOfLength:4];
	[rawSize getBytes:&size length:4];
	
	NSData *kData = [kHandle readDataOfLength:size];	
	md5 = [commonInstance dataMD5:kData];
	
	DLog(@"Kernel MD5: %@", md5);
	
	return md5;
}

- (void)opibPatchKernelCache {
	int status, jbType;
	unsigned char* data;
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	bsPatchInstance = [[BSPatch alloc] init];
	
	sharedData.kernelPatchFail = 0;
	
	[UIApplication sharedApplication].idleTimerDisabled = YES; //Stop autolock
	
	//Pre-flight checks
	DLog(@"Checking device compatibility...");
	sharedData.kernelPatchStage = 1;
	
	NSDictionary *kernelPatchesDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"KernelPatches" ofType:@"plist"]];
	NSDictionary *platformDict = [kernelPatchesDict objectForKey:sharedData.platform];
	
	if([platformDict count] < 1) {
		DLog(@"Device unsupported.");
		sharedData.kernelPatchFail = -1;
		return;
	}
	
	NSString *bundleName = [platformDict objectForKey:sharedData.systemVersion];
	
	if([bundleName length] == 0) {
		DLog(@"Firmware version %@ unsupported.", sharedData.systemVersion);
		sharedData.kernelPatchFail = -2;
		return;
	}
	
	NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"KernelPatches"];
	bundlePath = [bundlePath stringByAppendingPathComponent:bundleName];
	
	NSDictionary *kernelPatchBundleDict = [NSDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]];
	NSArray *kernelCompatibleMD5s = [kernelPatchBundleDict objectForKey:@"KernelMD5"];
	
	NSString *kernelMD5 = [self opibKernelMD5:[kernelPatchBundleDict objectForKey:@"Path"]];
	
	if([kernelMD5 isEqualToString:[kernelCompatibleMD5s objectAtIndex:0]]) {
		//PwnageTool
		jbType = 1;
		DLog(@"Device compatible: %@ on %@ jailbroken using pwnagetool.", sharedData.platform, sharedData.systemVersion);
	} else if([kernelMD5 isEqualToString:[kernelCompatibleMD5s objectAtIndex:1]]) {
		//Redsn0w
		jbType = 2;
		DLog(@"Device compatible: %@ on %@ jailbroken using redsn0w.", sharedData.platform, sharedData.systemVersion);
	} else if([sharedData.systemVersion isEqualToString:@"3.1.2"] && [[commonInstance fileMD5:[kernelPatchBundleDict objectForKey:@"Path"]] isEqualToString:[kernelCompatibleMD5s objectAtIndex:2]]) {
		//Blackra1n check
		jbType = 3;
		DLog(@"Device compatible: %@ on %@ jailbroken using blackra1n.", sharedData.platform, sharedData.systemVersion);
	} else if([sharedData.systemVersion isEqualToString:@"4.1"] && [kernelMD5 isEqualToString:[kernelCompatibleMD5s objectAtIndex:2]]) {
		//PwnageTool for new 4.1 check
		jbType = 3;
		DLog(@"Device compatible: %@ on %@ jailbroken using new PwnageTool.", sharedData.platform, sharedData.systemVersion);
	} else {
		DLog(@"No MD5 matches found, aborting...");
		sharedData.kernelPatchFail = -3;
		return;
	}
	
	DLog(@"Downloading stock kernelcache from Apple servers...");
	sharedData.kernelPatchStage = 2;
	
	NSString *ipsw = [kernelPatchBundleDict objectForKey:@"URL"];
	sharedData.kernelCachePath = [kernelPatchBundleDict objectForKey:@"File"];
	
	ZipInfo* info = PartialZipInit([ipsw cStringUsingEncoding:NSUTF8StringEncoding]);
	if(!info) {
		DLog(@"Cannot retrieve IPSW from: %@", ipsw);
		sharedData.kernelPatchFail = -4;
		return;
	}
	
	CDFile* file = PartialZipFindFile(info, [sharedData.kernelCachePath cStringUsingEncoding:NSUTF8StringEncoding]);
	if(!file) {
		DLog(@"Cannot find kernelcache.");
		sharedData.kernelPatchFail = -5;
		return;
	}
	
	DLog(@"Found it, now grabbing it.");
	data = PartialZipGetFile(info, file);
	int dataLen = file->size; 
	
	NSData *itemBin = [[NSData alloc] initWithBytes:data length:dataLen];
	
	if([itemBin length]==0) {
		DLog(@"kernelcache invalid");
		[itemBin release];
		sharedData.kernelPatchFail = -6;
		return;
	}
	
	sharedData.kernelCachePath = [sharedData.workingDirectory stringByAppendingPathComponent:sharedData.kernelCachePath];
	
	if(![itemBin writeToFile:sharedData.kernelCachePath atomically:YES]) {
		DLog(@"Could not write kernelcache to file.");
		[itemBin release];
		sharedData.kernelPatchFail = -7;
		[self opibKernelPatchCleanup];
		return;
	}
	
	free(data);
	[itemBin release];
	
	DLog(@"Patching kernelcache...");
	sharedData.kernelPatchStage = 3;
	
	//Decrypt stock kernelcache
	status = [self opibDecryptIMG3:sharedData.kernelCachePath to:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] key:[kernelPatchBundleDict objectForKey:@"Key"] iv:[kernelPatchBundleDict objectForKey:@"IV"] type:NO];
		
	if(status < 0) {
		DLog(@"Decrypting kernelcache returned: %d", status);
		sharedData.kernelPatchFail = -8;
		[self opibKernelPatchCleanup];
		return;
	}
	
	//Patch stock kernelcache with pwnage patches
	status = [bsPatchInstance bsPatch:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] withPatch:[bundlePath stringByAppendingPathComponent:@"kernelcache.release.patch"]];
	
	if(status < 0) {
		DLog(@"Patching kernelcache with pwnage patchset returned: %d", status);
		sharedData.kernelPatchFail = -9;
		[self opibKernelPatchCleanup];
		return;
	}
	
	//Rename or it gets messy
	if([[NSFileManager defaultManager] removeItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] error:nil]) {
		if(![[NSFileManager defaultManager] moveItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted.patched"] toPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] error:nil]) {
			DLog(@"Could not move kernelcache");
			sharedData.kernelPatchFail = -10;
			[self opibKernelPatchCleanup];
			return;
		}
	} else {
		DLog(@"Could not remove stock decrypted kernelcache");
		sharedData.kernelPatchFail = -10;
		[self opibKernelPatchCleanup];
		return;
	}
	
	//Patch pwned kernelcache with NOR writing patches
	status = [bsPatchInstance bsPatch:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] withPatch:[bundlePath stringByAppendingPathComponent:@"kernelcache.release.nor.patch"]];
	
	if(status < 0) {
		DLog(@"Patching kernelcache with NOR patchset returned: %d", status);
		sharedData.kernelPatchFail = -11;
		[self opibKernelPatchCleanup];
		return;
	}
	
	//Re-encrypt kernelcache into container
	if(jbType==1) {
		//PwnageTool, use stock kernelcache as template
		status = [self opibEncryptIMG3:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted.patched"] to:[sharedData.kernelCachePath stringByAppendingPathExtension:@"encrypted"] with:sharedData.kernelCachePath key:[kernelPatchBundleDict objectForKey:@"Key"] iv:[kernelPatchBundleDict objectForKey:@"IV"] type:NO];
	} else {
		//Redsn0w, use un-keyed kernelcache from disk as template
		status = [self opibEncryptIMG3:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted.patched"] to:[sharedData.kernelCachePath stringByAppendingPathExtension:@"encrypted"] with:[kernelPatchBundleDict objectForKey:@"Path"] key:nil iv:nil type:YES];
	}
	
	if(status < 0) {
		DLog(@"Encrypting kernelcache returned: %d", status);
		sharedData.kernelPatchFail = -12;
		[self opibKernelPatchCleanup];
		return;
	}
	
	DLog(@"Patching complete. Overwriting system kernelcache...");
	sharedData.kernelPatchStage = 4;
	
	//Backup old kernelcache
	if([[NSFileManager defaultManager] fileExistsAtPath:[[kernelPatchBundleDict objectForKey:@"Path"] stringByAppendingPathExtension:@"backup"]]) {
		if(![[NSFileManager defaultManager] removeItemAtPath:[kernelPatchBundleDict objectForKey:@"Path"] error:nil]) {
			DLog(@"Failed to remove old kernelcache");
			sharedData.kernelPatchFail = -13;
			[self opibKernelPatchCleanup];
			return;
		}
	} else {
		if(![[NSFileManager defaultManager] moveItemAtPath:[kernelPatchBundleDict objectForKey:@"Path"] toPath:[[kernelPatchBundleDict objectForKey:@"Path"] stringByAppendingPathExtension:@"backup"] error:nil]) {
			DLog(@"Failed to backup old kernelcache");
			sharedData.kernelPatchFail = -13;
			return;
		}
	}
	
	//Move new kernelcache into place
	if(![[NSFileManager defaultManager] moveItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"encrypted"] toPath:[kernelPatchBundleDict objectForKey:@"Path"] error:nil]) {
		DLog(@"Failed to move new kernelcache into place");
		sharedData.kernelPatchFail = -14;
		[self opibKernelPatchCleanup];
		return;
	}
	
	[self opibKernelPatchCleanup];
	
	DLog(@"Kernel patching process is complete.");
	
	[UIApplication sharedApplication].idleTimerDisabled = NO; //Re-enable autolock
	
	sharedData.kernelPatchStage = 5;
}

- (void)opibKernelPatchCleanup {
	commonData* sharedData = [commonData sharedData];
	
	//Cleanup
	[[NSFileManager defaultManager] removeItemAtPath:sharedData.kernelCachePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted"] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"decrypted.patched"] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[sharedData.kernelCachePath stringByAppendingPathExtension:@"encrypted"] error:nil];
}

- (void)opibRestoreKernel {
	if([[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.s5l8900x.backup"]) {
		[[NSFileManager defaultManager] removeItemAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.s5l8900x" error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.s5l8900x.backup" toPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.s5l8900x" error:nil];
	} else if([[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.backup"]) {
		[[NSFileManager defaultManager] removeItemAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache" error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache.backup" toPath:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache" error:nil];
	}
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasRunOnce"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//QuickBoot stuffs

- (int)opibRebootAndroid {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	sharedData.opibTempOS = @"2";
	
	status = [nvramInstance updateNVRAM:1];
	
	return status;
}

- (int)opibRebootConsole {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	sharedData.opibTempOS = @"3";
	
	status = [nvramInstance updateNVRAM:1];
	
	return status;
}

//OpeniBoot config stuff

- (int)opibApplyConfig {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	sharedData.opibTempOS = @"0";
	
	status = [nvramInstance updateNVRAM:0];
	
	return status;
}

- (int)opibBackupConfig {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	
	status = [nvramInstance backupNVRAM];
	
	return status;
}

- (int)opibRestoreConfig {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	status = [nvramInstance restoreNVRAM];
	
	if(status<0) {
		return status;
	}
	
	[self opibCheckInstalled];
	
	if(sharedData.opibInitStatus<0){
		return (sharedData.opibInitStatus - 2);
	}
	
	return 0;
}

- (int)opibResetConfig {
	int status;
	nvramInstance = [[nvramFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	sharedData.opibDefaultOS = @"1";
	sharedData.opibTempOS = @"0";
	sharedData.opibTimeout = @"10000";
	
	status = [nvramInstance updateNVRAM:0];
	
	if(status<0) {
		return status;
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:sharedData.opibBackupPath]) {
		if (![[NSFileManager defaultManager] removeItemAtPath:sharedData.opibBackupPath error:nil]) {
			return -3;
		}
	}
	
	[self opibCheckInstalled];
	
	if(sharedData.opibInitStatus<0){
		return (sharedData.opibInitStatus - 3);
	}
	
	return 0;
}

@end
