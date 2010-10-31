//
//  DroidViewController.m
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright Nick Dawson 2010. All rights reserved.
//

#import "DroidViewController.h"

@implementation DroidViewController

@synthesize installInstance, commonInstance, flipButton, tableView, tableRows, viewInitQueue, cfuSpinner, installOverallProgress, installCurrentProgress, installStageLabel, upgradeOverallProgress, upgradeCurrentProgress, upgradeStageLabel, latestVersionButton, installIdroidImage, removeIdroidImage, installIdroidButton, removeIdroidButton;

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */

- (void)viewDidLoad {
	[super viewDidLoad];
	
	Class $UIGlassButton = objc_getClass("UIGlassButton");
	
	installInstance = [[installClass alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	//Setup table and contents	
	CGRect tableFrame = CGRectMake(0, 0, 320, 180);
	
	self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:tableView];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	self.tableView.scrollEnabled = NO;
	
	//Fix button appearance and make some nice JB only ones
	[[latestVersionButton layer] setCornerRadius:8.0f];
	
	//Install Button
	installIdroidButton = [[$UIGlassButton alloc] initWithFrame:CGRectMake(90, 242, 220, 50)];
	[installIdroidButton setTitle:@"Install" forState:UIControlStateNormal];
	installIdroidButton.tintColor = [UIColor colorWithRed:0.024 green:0.197 blue:0.419 alpha:1.000];
	[installIdroidButton addTarget:self action:@selector(installPress:) forControlEvents:UIControlEventTouchUpInside];
	[installIdroidButton setEnabled:NO];
	[self.view addSubview:installIdroidButton];
	
	//Remove Button
	removeIdroidButton = [[$UIGlassButton alloc] initWithFrame:CGRectMake(90, 305, 220, 50)];
	[removeIdroidButton setTitle:@"Remove" forState:UIControlStateNormal];
	removeIdroidButton.tintColor = [UIColor colorWithRed:0.556 green:0.000 blue:0.000 alpha:1.000];
	[removeIdroidButton addTarget:self action:@selector(removePress:) forControlEvents:UIControlEventTouchUpInside];
	[removeIdroidButton setHidden:YES];
	[self.view addSubview:removeIdroidButton];
	
	//Advanced Button
	
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(loadAdvanced:) forControlEvents:UIControlEventTouchUpInside];
	flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	self.navigationItem.rightBarButtonItem = flipButton;
	
	//Setup
	
	[installInstance checkInstalled];
	
	tableRows = [[NSMutableArray alloc] init];
	
	if(sharedData.installed) {
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:@"dd-MM-yyyy"];
		NSString *dateString = [dateFormat stringFromDate:sharedData.installedDate];
		
		NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																			 [NSMutableArray arrayWithObjects:@"iDroid Version:", sharedData.installedVer, nil],
																			 [NSMutableArray arrayWithObjects:@"Android Version:", sharedData.installedAndroidVer, nil],
																			 [NSMutableArray arrayWithObjects:@"Date Installed:", dateString, nil],
																			 nil]
																	 forKey:@"Installed"];
		[tableRows addObject:installedSection];
		
		//Set button titles and unhide remove
		[installIdroidButton setTitle:@"Upgrade" forState:UIControlStateNormal];
		[installIdroidButton removeTarget:self action:@selector(installPress:) forControlEvents:UIControlEventTouchUpInside];
		[installIdroidButton addTarget:self action:@selector(upgradePress:) forControlEvents:UIControlEventTouchUpInside];
		[removeIdroidButton setHidden:NO];
		[removeIdroidImage setHidden:NO];
	} else {
		NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																			 [NSMutableArray arrayWithObjects:@"iDroid Version:", @"N/A", nil],
																			 [NSMutableArray arrayWithObjects:@"Android Version:", @"N/A", nil],
																			 [NSMutableArray arrayWithObjects:@"Date Installed:", @"N/A", nil],
																			 nil]
																			forKey:@"Installed"];
		[tableRows addObject:installedSection];
	}
	
	//Make update button spin like it's on LSD
	cfuSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[cfuSpinner setCenter:CGPointMake(140, 18)];
	[cfuSpinner startAnimating];
	[latestVersionButton addSubview:cfuSpinner];
	
	viewInitQueue = [NSOperationQueue new];
	NSInvocationOperation *getUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(callUpdate) object:nil];
	
	[viewInitQueue addOperation:getUpdate];
    [getUpdate release];
}

- (void)loadAdvanced:(id)sender
{
	DroidAdvancedViewController *droidAdvancedView = [[DroidAdvancedViewController alloc] initWithNibName:@"DroidAdvancedViewController" bundle:nil];
	[self.navigationController pushViewController:droidAdvancedView animated:YES];
	[droidAdvancedView release];
}

- (void)callUpdate {
	installInstance = [[installClass alloc] init];
	
	[installInstance checkForUpdates];
	
	[self performSelectorOnMainThread:@selector(refreshUpdate) withObject:nil waitUntilDone:YES];
}

- (void)callInstall {
	installInstance = [[installClass alloc] init];
	
	[installInstance idroidInstall];
	
	[installInstance checkForUpdates];

	[self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(refreshUpdate) withObject:nil waitUntilDone:YES];
}

- (void)callUpgrade {
	installInstance = [[installClass alloc] init];
	
	[installInstance idroidUpgrade];
	
	[installInstance checkForUpdates];
	
	[self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(refreshUpdate) withObject:nil waitUntilDone:YES];
}

- (void)callRemove {
	installInstance = [[installClass alloc] init];
	
	[installInstance idroidRemove];
	
	[installInstance checkForUpdates];
	
	[self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(refreshUpdate) withObject:nil waitUntilDone:NO];
}

- (void)refreshStatus {
	commonData* sharedData = [commonData sharedData];
	
	if(sharedData.installed) {
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:@"dd-MM-yyyy"];
		NSString *dateString = [dateFormat stringFromDate:sharedData.installedDate];

		NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																			 [NSMutableArray arrayWithObjects:@"iDroid Version:", sharedData.installedVer, nil],
																			 [NSMutableArray arrayWithObjects:@"Android Version:", sharedData.installedAndroidVer, nil],
																			 [NSMutableArray arrayWithObjects:@"Date Installed:", dateString, nil],
																			 nil]
																	 forKey:@"Installed"];
		[tableRows replaceObjectAtIndex:0 withObject:installedSection];
		
		//Setup buttons
		[installIdroidButton setTitle:@"Upgrade" forState:UIControlStateNormal];
		[installIdroidButton removeTarget:self action:@selector(installPress:) forControlEvents:UIControlEventTouchUpInside];
		[installIdroidButton addTarget:self action:@selector(upgradePress:) forControlEvents:UIControlEventTouchUpInside];
		[installIdroidButton setEnabled:NO];
		[installIdroidImage setEnabled:NO];
		[removeIdroidButton setHidden:NO];
		[removeIdroidImage setHidden:NO];
	} else {
		NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																			 [NSMutableArray arrayWithObjects:@"iDroid Version:", @"N/A", nil],
																			 [NSMutableArray arrayWithObjects:@"Android Version:", @"N/A", nil],
																			 [NSMutableArray arrayWithObjects:@"Date Installed:", @"N/A", nil],
																			 nil]
																	 forKey:@"Installed"];
		[tableRows replaceObjectAtIndex:0 withObject:installedSection];
		
		//Setup buttons
		[installIdroidButton setTitle:@"Install" forState:UIControlStateNormal];
		[installIdroidButton removeTarget:self action:@selector(upgradePress:) forControlEvents:UIControlEventTouchUpInside];
		[installIdroidButton addTarget:self action:@selector(installPress:) forControlEvents:UIControlEventTouchUpInside];
		[installIdroidButton setEnabled:YES];
		[installIdroidImage setEnabled:YES];
		[removeIdroidButton setHidden:YES];
		[removeIdroidImage setHidden:YES];
	}
	
	[self.tableView reloadData];
}

- (void)refreshUpdate {
	commonData* sharedData = [commonData sharedData];
	NSString *updateButtonLabel;
	
	//if statement to check latest version
	[cfuSpinner stopAnimating];
	[cfuSpinner release];
	
	switch (sharedData.updateCanBeInstalled) {
		case 0:
			[latestVersionButton setTitle:@"Latest Version Installed" forState:UIControlStateNormal];
			[installIdroidButton setEnabled:NO];
			[installIdroidImage setEnabled:NO];
			break;
		case 1:
			updateButtonLabel = @"Version available to install: ";
			updateButtonLabel = [updateButtonLabel stringByAppendingString:sharedData.updateVer];
			[latestVersionButton setTitle:updateButtonLabel forState:UIControlStateNormal];
			[installIdroidButton setEnabled:YES];
			[installIdroidImage setEnabled:YES];
			break;
		case 2:
			updateButtonLabel = @"New version available: ";
			updateButtonLabel = [updateButtonLabel stringByAppendingString:sharedData.updateVer];
			[latestVersionButton setTitle:updateButtonLabel forState:UIControlStateNormal];
			[installIdroidButton setEnabled:YES];
			[installIdroidImage setEnabled:YES];
			break;
		case -1:
			[latestVersionButton setTitle:@"iDroid unavailable for this device" forState:UIControlStateNormal];
			[installIdroidButton setEnabled:NO];
			[installIdroidImage setEnabled:NO];
			break;
		case -2:
			[latestVersionButton setTitle:@"Unable to check for updates" forState:UIControlStateNormal];
			[installIdroidButton setEnabled:NO];
			[installIdroidImage setEnabled:NO];
			break;
		case -3:
			[latestVersionButton setTitle:@"iDroid cannot be upgraded" forState:UIControlStateNormal];
			[installIdroidButton setEnabled:NO];
			[installIdroidImage setEnabled:NO];
			break;
		default:
			[latestVersionButton setTitle:@"Unable to check for updates" forState:UIControlStateNormal];
			[installIdroidButton setEnabled:NO];
			[installIdroidImage setEnabled:NO];
			break;
	}
}

- (IBAction)checkForUpdatesManual:(id)sender {
	[latestVersionButton setTitle:@"" forState:UIControlStateNormal];
	cfuSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[cfuSpinner setCenter:CGPointMake(140, 18)];
	[cfuSpinner startAnimating];
	[latestVersionButton addSubview:cfuSpinner];
	
	NSInvocationOperation *getUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(callUpdate) object:nil];
	
	[viewInitQueue addOperation:getUpdate];
    [getUpdate release];
}

- (IBAction)installPress:(id)sender {
	float freeSpace, neededSpace;
	commonInstance = [[commonFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	BOOL mains = [commonInstance checkMains];
	
	if(!mains) {
		[commonInstance sendWarning:@"It is highly recommended you connect your device to the mains or your computer before continuing as the install process can take some time!"];
		
		do {        
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
		} while (sharedData.warningLive);
	}
	
	//Check space requirements	
	freeSpace = [commonInstance getFreeSpace];
	
	if(freeSpace < (sharedData.updateSize * 2)) {
		DLog(@"Not enough free space. %1.0f available.", freeSpace);
		
		neededSpace = (float)(((sharedData.updateSize * 2) - freeSpace) / 1048576);
		
		NSString *noSpace = [NSString stringWithFormat:@"There is not enough free space to complete the installation process.\r\n\r\nPlease free an additional %1.0fMB of space.", neededSpace];
		
		[commonInstance sendError:noSpace];
		
		return;
	}
	
	//Check Bootlace requirements
	if([sharedData.updateBootlaceRequired compare:sharedData.bootlaceVersion options:NSNumericSearch] == NSOrderedDescending) {
		DLog(@"Newer version of Bootlace required than the one installed.");
		
		NSString *tooOld = [NSString stringWithFormat:@"Installing iDroid requires a newer version of Bootlace.\r\n\r\nPlease upgrade to version %@ using Cydia.", sharedData.updateBootlaceRequired];
		
		[commonInstance sendError:tooOld];
		
		return;
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/android.img.gz"] || [[NSFileManager defaultManager] fileExistsAtPath:@"/var/zImage"] || [[NSFileManager defaultManager] fileExistsAtPath:@"/var/idroid/android.img.gz"]) {
		UIActionSheet *confirmInstall = [[UIActionSheet alloc] initWithTitle:@"Warning: this will destroy and overwrite any existing iDroid install." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Continue" otherButtonTitles:nil];
		confirmInstall.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		confirmInstall.tag = 10;
		[confirmInstall showInView:self.tabBarController.view];
		[confirmInstall release];
	} else {
		[self installIdroid];
	}
}

- (IBAction)upgradePress:(id)sender {
	float freeSpace, neededSpace;
	commonInstance = [[commonFunctions alloc] init];
	commonData* sharedData = [commonData sharedData];
	
	//Check space requirements	
	freeSpace = [commonInstance getFreeSpace];
	
	if(freeSpace < (sharedData.updateSize * 2)) {
		DLog(@"Not enough free space. %1.0f available.", freeSpace);
		
		neededSpace = (float)(((sharedData.updateSize * 2) - freeSpace) / 1048576);
		
		NSString *noSpace = [NSString stringWithFormat:@"There is not enough free space to complete the upgrade process.\r\n\r\nPlease free an additional %1.0fMB of space.", neededSpace];
		
		[commonInstance sendError:noSpace];
		
		return;
	}
	
	//Check Bootlace requirements
	if([sharedData.updateBootlaceRequired compare:sharedData.bootlaceVersion options:NSNumericSearch] == NSOrderedDescending) {
		DLog(@"Newer version of Bootlace required than the one installed.");
		
		NSString *tooOld = [NSString stringWithFormat:@"Installing iDroid requires a newer version of Bootlace.\r\n\r\nPlease upgrade to version %@ using Cydia.", sharedData.updateBootlaceRequired];
		
		[commonInstance sendError:tooOld];
		
		return;
	}
	
	//Check if a newer openiboot is needed
	if([sharedData.updateOpibRequired compare:sharedData.opibVersion options:NSNumericSearch] == NSOrderedDescending) {		
		NSString *warnTitle = [NSString stringWithFormat:@"Warning: the version of iDroid you are upgrading to requires OpeniBoot %@ but you currently have version %@ installed. Do you wish to continue?", sharedData.updateOpibRequired, sharedData.opibVersion];
		UIActionSheet *confirmUpgrade = [[UIActionSheet alloc] initWithTitle:warnTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Continue" otherButtonTitles:nil];
		confirmUpgrade.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		confirmUpgrade.tag = 30;
		[confirmUpgrade showInView:self.tabBarController.view];
		[confirmUpgrade release];
	} else {
		[self upgradeIdroid];
	}
}

- (IBAction)removePress:(id)sender {
	UIActionSheet *confirmRemove = [[UIActionSheet alloc] initWithTitle:@"Are you sure you wish to remove iDroid?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove" otherButtonTitles:nil];
	confirmRemove.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	confirmRemove.tag = 20;
	[confirmRemove showInView:self.tabBarController.view];
	[confirmRemove release];
}

- (void)installIdroid {
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	[latestVersionButton setTitle:@"" forState:UIControlStateNormal];
	cfuSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[cfuSpinner setCenter:CGPointMake(140, 18)];
	[cfuSpinner startAnimating];
	[latestVersionButton addSubview:cfuSpinner];
	
	NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																		 [NSMutableArray arrayWithObjects:@"iDroid Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Android Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Date Installed:", @"loading", nil],
																		 nil]
																 forKey:@"Installed"];
	[tableRows replaceObjectAtIndex:0 withObject:installedSection];
	
	[self.tableView reloadData];
	
	UIAlertView *installView;
	installView = [[[UIAlertView alloc] initWithTitle:@"Installing..." message:@"\r\n\r\n\r\n" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
	[installView show];
	
	UIActivityIndicatorView *installSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[installSpinner setCenter:CGPointMake(140, 62)];
	[installSpinner startAnimating];
	[installView addSubview:installSpinner];
	[installSpinner release];
	
	installOverallProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(67, 88, 150, 20)];
    [installView addSubview:installOverallProgress];
    [installOverallProgress setProgressViewStyle: UIProgressViewStyleBar];
	
	installStageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 280, 40)];
	installStageLabel.text = @"Downloading iDroid";
	installStageLabel.textColor = [UIColor whiteColor];
	installStageLabel.textAlignment = UITextAlignmentCenter;
	installStageLabel.backgroundColor = [UIColor clearColor];
	[installView addSubview:installStageLabel];
	
	installCurrentProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(22, 143, 240, 20)];
    [installView addSubview:installCurrentProgress];
    [installCurrentProgress setProgressViewStyle: UIProgressViewStyleBar];
	
	NSInvocationOperation *getInstall = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(callInstall) object:nil];
	
	[viewInitQueue addOperation:getInstall];
    [getInstall release];
	
	BOOL keepAlive = YES;
	
	do {        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, YES);
        installOverallProgress.progress = sharedData.updateOverallProgress;
		installCurrentProgress.progress = sharedData.updateCurrentProgress;
		if (sharedData.updateOverallProgress == 1) {
			keepAlive = NO;
		}
		switch (sharedData.updateStage) {
			case 1:
				installStageLabel.text = @"Downloading iDroid";
				break;
			case 2:
				installStageLabel.text = @"Verifying iDroid";
				break;
			case 3:
				installStageLabel.text = @"Decompressing Files";
				break;
			case 4:
				installStageLabel.text = @"Extracting Files";
				break;
			case 5:
				installStageLabel.text = @"Resolving Dependencies";
				break;
			default:
				break;
		}
		switch (sharedData.updateFail) {
			case 0:
				break;
			case 1:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\niDroid could not be downloaded."];
				keepAlive = NO;
				break;
			case 2:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nFile decompression failed."];
				keepAlive = NO;
				break;
			case 3:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nArchive extraction failed."];
				keepAlive = NO;
				break;
			case 4:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nFiles could not be moved."];
				keepAlive = NO;
				break;
			case 5:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nMultitouch firmware could not be acquired."];
				keepAlive = NO;
				break;
			case 6:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nWiFi firmware could not be retrieved."];
				keepAlive = NO;
				break;
			case 7:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nInstallation manifest could not be generated."];
				keepAlive = NO;
				break;
			case 8:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\nDirectories could no be created."];
				keepAlive = NO;
				break;
			case 9:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Install failed.\niDroid package MD5 checksum does not match."];
				keepAlive = NO;
				break;
			default:
				break;
		}
    } while (keepAlive);

	[installView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)upgradeIdroid {
	commonData* sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	[latestVersionButton setTitle:@"" forState:UIControlStateNormal];
	cfuSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[cfuSpinner setCenter:CGPointMake(140, 18)];
	[cfuSpinner startAnimating];
	[latestVersionButton addSubview:cfuSpinner];
	
	NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																		 [NSMutableArray arrayWithObjects:@"iDroid Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Android Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Date Installed:", @"loading", nil],
																		 nil]
																 forKey:@"Installed"];
	[tableRows replaceObjectAtIndex:0 withObject:installedSection];
	
	[self.tableView reloadData];
	
	UIAlertView *upgradeView;
	upgradeView = [[[UIAlertView alloc] initWithTitle:@"Upgrading..." message:@"\r\n\r\n\r\n" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
	[upgradeView show];
	
	UIActivityIndicatorView *upgradeSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[upgradeSpinner setCenter:CGPointMake(140, 62)];
	[upgradeSpinner startAnimating];
	[upgradeView addSubview:upgradeSpinner];
	[upgradeSpinner release];
	
	upgradeOverallProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(67, 88, 150, 20)];
    [upgradeView addSubview:upgradeOverallProgress];
    [upgradeOverallProgress setProgressViewStyle: UIProgressViewStyleBar];
	
	upgradeStageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 280, 40)];
	upgradeStageLabel.text = @"Downloading update";
	upgradeStageLabel.textColor = [UIColor whiteColor];
	upgradeStageLabel.textAlignment = UITextAlignmentCenter;
	upgradeStageLabel.backgroundColor = [UIColor clearColor];
	[upgradeView addSubview:upgradeStageLabel];
	
	upgradeCurrentProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(22, 143, 240, 20)];
    [upgradeView addSubview:upgradeCurrentProgress];
    [upgradeCurrentProgress setProgressViewStyle: UIProgressViewStyleBar];
	
	NSInvocationOperation *getUpgrade = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(callUpgrade) object:nil];
	
	[viewInitQueue addOperation:getUpgrade];
    [getUpgrade release];
	
	BOOL keepAlive = YES;
	
	do {        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, YES);
        upgradeOverallProgress.progress = sharedData.updateOverallProgress;
		upgradeCurrentProgress.progress = sharedData.updateCurrentProgress;
		if (sharedData.updateOverallProgress == 1) {
			keepAlive = NO;
		}
		switch (sharedData.updateStage) {
			case 1:
				upgradeStageLabel.text = @"Downloading update";
				break;
			case 2:
				upgradeStageLabel.text = @"Verifying update";
				break;
			case 3:
				upgradeStageLabel.text = @"Decompressing update";
				break;
			case 4:
				upgradeStageLabel.text = @"Extracting update";
				break;
			case 5:
				upgradeStageLabel.text = @"Updating files";
				break;
			default:
				break;
		}
		switch (sharedData.updateFail) {
			case 0:
				break;
			case 1:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nUpdate could not be downloaded."];
				keepAlive = NO;
				break;
			case 2:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nFile decompression failed."];
				keepAlive = NO;
				break;
			case 3:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nArchive extraction failed."];
				keepAlive = NO;
				break;
			case 4:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nDirectories could not be created."];
				keepAlive = NO;
				break;
			case 5:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nFiles could not be removed."];
				keepAlive = NO;
				break;
			case 6:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nFiles could not be moved."];
				keepAlive = NO;
				break;
			case 7:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nCherry picking files failed."];
				keepAlive = NO;
				break;
			case 8:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nPost install script failed."];
				keepAlive = NO;
				break;
			case 9:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nUpdating the installed plist failed."];
				keepAlive = NO;
				break;
			case 10:
				DLog(@"Error triggered. Fail code: %d", sharedData.updateFail);
				[commonInstance sendError:@"Upgrade failed.\nUpdate package does not match MD5 checksum."];
				keepAlive = NO;
				break;
			default:
				keepAlive = NO;
				break;
		}
    } while (keepAlive);
	
	[upgradeView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)removeIdroid {
	commonData* sharedData = [commonData sharedData];
	
	[latestVersionButton setTitle:@"" forState:UIControlStateNormal];
	cfuSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[cfuSpinner setCenter:CGPointMake(140, 18)];
	[cfuSpinner startAnimating];
	[latestVersionButton addSubview:cfuSpinner];
	
	NSDictionary *installedSection = [NSDictionary dictionaryWithObject:[NSMutableArray arrayWithObjects:
																		 [NSMutableArray arrayWithObjects:@"iDroid Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Android Version:", @"loading", nil],
																		 [NSMutableArray arrayWithObjects:@"Date Installed:", @"loading", nil],
																		 nil]
																 forKey:@"Installed"];
	[tableRows replaceObjectAtIndex:0 withObject:installedSection];
	
	[self.tableView reloadData];
	
	UIAlertView *removeView;
	removeView = [[[UIAlertView alloc] initWithTitle:@"Removing..." message:@"\n\rUninstalling iDroid" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
	[removeView show];
	
	UIActivityIndicatorView *removeSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[removeSpinner setCenter:CGPointMake(140, 63)];
	[removeSpinner startAnimating];
	[removeView addSubview:removeSpinner];
	[removeSpinner release];
	
	NSInvocationOperation *getRemove = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(callRemove) object:nil];
	
	[viewInitQueue addOperation:getRemove];
    [getRemove release];
	
	do {        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
	} while (sharedData.installed);
	
	[removeView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (actionSheet.tag) {
		case 10:
			if(buttonIndex==0) {
				[self performSelectorOnMainThread:@selector(installIdroid) withObject:nil waitUntilDone:NO];
			}
			break;
		case 20:
			if(buttonIndex==0) {
				[self performSelectorOnMainThread:@selector(removeIdroid) withObject:nil waitUntilDone:NO];
			}
			break;
		case 30:
			if(buttonIndex==0) {
				[self performSelectorOnMainThread:@selector(upgradeIdroid) withObject:nil waitUntilDone:NO];
			}
		default:
			break;
	}
}

/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */
/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *installedSection = [tableRows objectAtIndex:section];
	NSArray *installedRows = [installedSection objectForKey:@"Installed"];
	return [installedRows count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	NSString *sectionHeader = nil;
	
	if(section == 0) {
		sectionHeader = @"Currently Installed:";
	}	
	
	return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self tableView:self.tableView titleForHeaderInSection:section] != nil) {
        return 40;
    }
    else {
        // If no section header title, no section header needed
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:self.tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
	
    // Create label with section title
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.frame = CGRectMake(20, 0, 300, 40);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = sectionTitle;
	
    // Create header view and add label as a subview
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [headerView autorelease];
    [headerView addSubview:label];
	
    return headerView;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	
	cell.opaque = NO;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3];
	
	cell.textLabel.backgroundColor = [UIColor clearColor];
	cell.textLabel.textColor = [UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1];
	
	//cell.textLabel.text = [[tableRows objectAtIndex: indexPath.row] valueForKey:labelKey];
	
	NSDictionary *installedSection = [tableRows objectAtIndex:indexPath.section];
	NSArray *installedRows = [installedSection objectForKey:@"Installed"];
	NSArray *cellArray = [installedRows objectAtIndex:indexPath.row];
	NSString *cellTitle = [cellArray objectAtIndex:0];
	NSString *cellValue = [cellArray objectAtIndex:1];
	cell.textLabel.text = cellTitle;
	
	if([cellValue isEqualToString:@"loading"]) {
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[spinner setCenter:CGPointMake(277, 22)];
		[spinner startAnimating];
		[cell.contentView addSubview:spinner];
		[spinner release];
	} else {
		UILabel *varLabel;
		CGRect frame = CGRectMake(190.0, 8.0, 94.0, 29.0);
		varLabel = [[UILabel alloc] initWithFrame:frame];
		varLabel.backgroundColor = [UIColor clearColor];
		varLabel.textAlignment = UITextAlignmentRight;
		varLabel.text = cellValue;
		varLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
	
		[cell.contentView addSubview:varLabel];
		[varLabel release];
    }
	
	return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}
*/

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


- (void)dealloc {
    [super dealloc];
}


@end
