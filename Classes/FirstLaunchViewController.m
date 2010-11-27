//
//  FirstLaunchViewController.m
//  BootlaceV2
//
//  Created by Neonkoala on 29/10/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "FirstLaunchViewController.h"


@implementation FirstLaunchViewController

@synthesize patchingProgress, guiLoop;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)updateGUI:(NSTimer *)theTimer {
	commonData *sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	if (sharedData.kernelPatchStage == 5) {
		[patchingProgress hide];
		
		if(sharedData.kernelPatchFail==0) {	
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunOnce"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			UIAlertView *rebootPrompt = [[UIAlertView alloc] initWithTitle:@"Reboot Required" message:@"Kernel successfully patched.\r\nYour device must be rebooted." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Reboot",nil];
			[rebootPrompt setTag:1];
			[rebootPrompt show];
		}
		
		[guiLoop invalidate];
	}
	switch (sharedData.kernelPatchStage) {
		case 2:
			[patchingProgress performSelectorOnMainThread:@selector(setText:) withObject:@"Downloading Kernel..." waitUntilDone:YES];
			break;
		case 3:
			[patchingProgress performSelectorOnMainThread:@selector(setText:) withObject:@"Patching Kernel..." waitUntilDone:YES];
			break;
		case 4:
			[patchingProgress performSelectorOnMainThread:@selector(setText:) withObject:@"Replacing Kernel..." waitUntilDone:YES];
			break;
		default:
			break;
	}
	switch (sharedData.kernelPatchFail) {
		case 0:
			break;
		case -1:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Bootlace does not support this device."];
			[guiLoop invalidate];
			break;
		case -2:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Bootlace does not support this firmware."];
			[guiLoop invalidate];
			break;
		case -3:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Kernel does not match any compatible jailbreaks. Jailbreak with redsn0w or PwnageTool and try again."];
			[guiLoop invalidate];
			break;
		case -4:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Could not retrieve IPSW information from Apple.\r\nEnsure you are connected to the internet."];
			[guiLoop invalidate];
			break;
		case -5:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Could not find KernelCache in IPSW.\r\nInvalid IPSW URL?"];
			[guiLoop invalidate];
			break;
		case -6:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Invalid KernelCache."];
			[guiLoop invalidate];
			break;
		case -7:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Could not write KernelCache to file."];
			[guiLoop invalidate];
			break;
		case -8:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Decrypting KernelCache failed."];
			[guiLoop invalidate];
			break;
		case -9:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Patching KernelCache first stage failed."];
			[guiLoop invalidate];
			break;
		case -10:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Could not remove stock KernelCache."];
			[guiLoop invalidate];
			break;
		case -11:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Patching KernelCache second stage failed."];
			[guiLoop invalidate];
			break;
		case -12:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Re-encrypting KernelCache failed."];
			[guiLoop invalidate];
			break;
		case -13:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"Old KernelCache could not be backed up or removed."];
			[guiLoop invalidate];
			break;
		case -14:
			DLog(@"Error triggered. Fail code: %d", sharedData.kernelPatchFail);
			[commonInstance sendTerminalError:@"New KernelCache could not be moved into place."];
			[guiLoop invalidate];
			break;
		default:
			break;
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	if(![sharedData.platform isEqualToString:@"iPhone1,1"] && ![sharedData.platform isEqualToString:@"iPhone1,2"] && ![sharedData.platform isEqualToString:@"iPod1,1"]) {
		DLog(@"Failed platform check: %@", sharedData.platform);
		[commonInstance sendTerminalError:@"Bootlace is not compatible with this device.\r\nAborting..."];
	}
	
	opibInstance = [[OpeniBootClass alloc] init];
	
	patchingProgress = [[UIProgressHUD alloc] initWithWindow:self.view];
	[patchingProgress setText:@"Checking Compatibility..."];
	[patchingProgress showInView:self.view];
	
	NSOperationQueue *thisQ = [NSOperationQueue new];
	NSInvocationOperation *doPatch = [[NSInvocationOperation alloc] initWithTarget:opibInstance selector:@selector(opibPatchKernelCache) object:nil];
	
	[thisQ addOperation:doPatch];
    [doPatch release];
	
	guiLoop = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateGUI:) userInfo:nil repeats:YES];
}	


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if([alertView tag] == 1) {
		if(buttonIndex == 0) {
			reboot(0); 
		}
	}
}

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
