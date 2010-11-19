//
//  DroidAdvancedViewController.m
//  BootlaceV2
//
//  Created by Neonkoala on 23/08/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import "DroidAdvancedViewController.h"


@implementation DroidAdvancedViewController

@synthesize commonInstance, installInstance, extractionInstance, multitouchInstall, resetUserDataButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	commonData* sharedData = [commonData sharedData];
	
	[multitouchInstall setTitle:@"Extract Multitouch Firmware" forState:UIControlStateNormal];
	multitouchInstall.tintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.000];
	
	[resetUserDataButton setTitle:@"Reset iDroid User Data" forState:UIControlStateNormal];
	resetUserDataButton.tintColor = [UIColor colorWithRed:0.556 green:0.000 blue:0.000 alpha:1.000];
	
	if(sharedData.updateDependencies == nil) {
		multitouchInstall.enabled = NO;
	}
}

- (IBAction)extractMultitouch:(id)sender {
	UIActionSheet *confirmExtract = [[UIActionSheet alloc] initWithTitle:@"Extracting multitouch firmware will overwrite any existing firmware. Continue?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Extract" otherButtonTitles:nil];
	confirmExtract.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	confirmExtract.tag = 10;
	[confirmExtract showInView:self.tabBarController.view];
	[confirmExtract release];
}

- (IBAction)resetUserData:(id)sender {
	UIActionSheet *confirmReset = [[UIActionSheet alloc] initWithTitle:@"WARNING: This will reset the userdata.img! Are you sure you wish to continue?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Reset" otherButtonTitles:nil];
	confirmReset.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	confirmReset.tag = 30;
	[confirmReset showInView:self.tabBarController.view];
	[confirmReset release];	
}

- (void)dumpZephyr {
	commonData* sharedData = [commonData sharedData];
	
	commonInstance = [[commonFunctions alloc] init];
	installInstance = [[installClass alloc] init];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:sharedData.updateFirmwarePath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:sharedData.updateFirmwarePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F52,1"] || [[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z2F51,1"]) {
		if([[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"]]) {
			DLog(@"Removing existing zephyr2 firmware file");
			[[NSFileManager defaultManager] removeItemAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr2.bin"] error:nil];
		}
	} else if([[sharedData.updateDependencies objectForKey:@"Multitouch"] isEqual:@"Z1F50,1"]) {
		if([[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_main.bin"]] || [[NSFileManager defaultManager] fileExistsAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_aspeed.bin"]]) {
			DLog(@"Removing existing zephyr1 firmware files");
			[[NSFileManager defaultManager] removeItemAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_main.bin"] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:[sharedData.updateFirmwarePath stringByAppendingPathComponent:@"zephyr_aspeed.bin"] error:nil];
		}
	}

	int success = [installInstance dumpMultitouch];

	switch (success) {
		case 0:
			[commonInstance sendSuccess:@"Zephyr multitouch firmware succesfully extracted."];
			break;
		case -1:
			[commonInstance sendError:@"Zephyr2 extraction failed."];
			break;
		case -2:
			[commonInstance sendError:@"Zephyr1 extraction failed on zephyr_main.bin"];
			break;
		case -3:
			[commonInstance sendError:@"Zephyr1 extraction failed on zephyr_aspeed.bin"];
			break;
		default:
			break;
	}
}

- (void)doReset {
	int success;
	commonData* sharedData = [commonData sharedData];
	
	commonInstance = [[commonFunctions alloc] init];
	extractionInstance = [[extractionClass alloc] init];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:sharedData.restoreUserDataPath]) {
		DLog(@"Userdata.img not found..");
		[commonInstance sendError:@"Userdata.img not found. This can only be used if iDroid is already installed."];
		return;
	}
	
	UIAlertView *progressView;
	progressView = [[[UIAlertView alloc] initWithTitle:@"Downloading" message:@"\r\n" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
	[progressView show];
	
	UIActivityIndicatorView *progressSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[progressSpinner setCenter:CGPointMake(140, 80)];
	[progressSpinner startAnimating];
	[progressView addSubview:progressSpinner];
	[progressSpinner release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	getFileInstance = [[getFile alloc] initWithUrl:sharedData.restoreUserDataURL directory:sharedData.workingDirectory];
	DLog(@"DEBUG: updateURL = %@", sharedData.restoreUserDataURL);
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
			DLog(@"DEBUG: Failed to get replacement userdata.img.");
			
			[commonInstance sendError:@"Could not download the replacement userdata.img. You're boned."];
			return;
		}
	} while (keepAlive);
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[[NSFileManager defaultManager] removeItemAtPath:sharedData.restoreUserDataPath error:nil];
	
	[progressView setTitle:@"Decompressing"];
	
	NSString *tempPath = getFileInstance.getFilePath;
	
	[[NSFileManager defaultManager] createFileAtPath:sharedData.restoreUserDataPath contents:nil attributes:nil];
	
	success = [extractionInstance inflateGzip:tempPath toDest:sharedData.restoreUserDataPath];
	
	if(success < 0) {
		ALog(@"GZip extraction returned: %d", success);
		
		[commonInstance sendError:@"An error occurred while decompressing the replacement userdata.img."];
		return;
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
	
	[progressView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSLog(@"index: %d", buttonIndex);
	switch (actionSheet.tag) {
		case 10:
			if(buttonIndex == 0) {
				[self performSelectorOnMainThread:@selector(dumpZephyr) withObject:nil waitUntilDone:NO];
			}
			break;
		case 30:
			if(buttonIndex == 0) {
				[self performSelectorOnMainThread:@selector(doReset) withObject:nil waitUntilDone:NO];
			}
			break;
		default:
			break;
	}
}
	 
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
