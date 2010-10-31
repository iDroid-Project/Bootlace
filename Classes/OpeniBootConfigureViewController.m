//
//  OpeniBootConfigureViewController.m
//  BootlaceV2
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import "OpeniBootConfigureViewController.h"


@implementation OpeniBootConfigureViewController

@synthesize commonInstance, tableRows, applyButton, osPicker, androidImage, androidLabel, consoleImage, consoleLabel, iphoneosImage, iphoneosLabel;

//Switch toggle function
- (UISwitch *)switchCtl
{
    if (switchCtl == nil)
    {
        CGRect frame = CGRectMake(198.0, 9.0, 94.0, 27.0);
        switchCtl = [[UISwitch alloc] initWithFrame:frame];
        [switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        
        // in case the parent view draws with a custom color or gradient, use a transparent color
        switchCtl.backgroundColor = [UIColor clearColor];
    }
    return switchCtl;
}

//Label with corresponding variable display
- (UILabel *)labelWithVar
{
	if (labelWithVar == nil) {
		CGRect frame = CGRectMake(200.0, 8.0, 94.0, 29.0);
		labelWithVar = [[UILabel alloc] initWithFrame:frame];
	}
	labelWithVar.textAlignment = UITextAlignmentRight;
	labelWithVar.text = @"X Seconds";
	return labelWithVar;
}

//Full width slider
- (UISlider *)sliderCtl
{
    if (sliderCtl == nil) 
    {
        CGRect frame = CGRectMake(10.0, 12.0, 280.0, 7.0);
        sliderCtl = [[UISlider alloc] initWithFrame:frame];
        [sliderCtl addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        
        // in case the parent view draws with a custom color or gradient, use a transparent color
        sliderCtl.backgroundColor = [UIColor clearColor];
        
        sliderCtl.minimumValue = 3.0;
        sliderCtl.maximumValue = 30.0;
        sliderCtl.continuous = YES;
        sliderCtl.value = 10.0;
		sliderCtl.enabled = NO;
    }
    return sliderCtl;
}

//Button linking to view
- (UIButton *)linkButton
{
	if (linkButton == nil)
	{
		// create a UIButton (UIButtonTypeDetailDisclosure)
		linkButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
		linkButton.frame = CGRectMake(265.0, 8.0, 25.0, 25.0);
		[linkButton setTitle:@"Advanced" forState:UIControlStateNormal];
		linkButton.backgroundColor = [UIColor clearColor];
		[linkButton addTarget:self action:@selector(loadAdvanced:) forControlEvents:UIControlEventTouchUpInside];
	}
	return linkButton;
}

//Switch Action
- (void)switchAction:(id)sender
{
	commonData *sharedData = [commonData sharedData];
	
	if(switchCtl.on) {
		sliderCtl.enabled = YES;
		sharedData.opibTimeout = [NSString stringWithFormat:@"%1.0f", (sliderCtl.value * 1000)];
	} else {
		sliderCtl.enabled = NO;
		sharedData.opibTimeout = @"0";
	}
}

//SLider Action
- (void)sliderAction:(id)sender
{
	commonData *sharedData = [commonData sharedData];
	labelWithVar.text = [NSString stringWithFormat:@"%1.0f", sliderCtl.value];
	labelWithVar.text = [labelWithVar.text stringByAppendingString:@" Seconds"];
	sliderCtl.value = round(1.0f * sliderCtl.value);
	
	sharedData.opibTimeout = [NSString stringWithFormat:@"%1.0f", (sliderCtl.value * 1000)];
}

//Advanced Action
- (void)loadAdvanced:(id)sender
{
	AdvancedViewController *advancedView = [[AdvancedViewController alloc] initWithNibName:@"AdvancedViewController" bundle:nil];
	[self.navigationController pushViewController:advancedView animated:YES];
	[advancedView release];
}

//Apply Action
- (void)applyAction:(id)sender {
	opibInstance = [[OpeniBootClass alloc] init];
	int success = [opibInstance opibApplyConfig];
	
	switch (success) {
		case 0:
			[commonInstance sendSuccess:@"Openiboot settings successfully applied."];
			break;
		case -1:
			[commonInstance sendError:@"Your openiboot settings could not be applied.\r\nNVRAM could not be accessed."];
			break;
		case -2:
			[commonInstance sendError:@"Your openiboot settings could not be applied.\r\nNVRAM configuration invalid."];
			break;
		default:
			break;
	}
}

- (void)disableOpibSettings {
	applyButton.enabled = NO;
	iphoneosImage.enabled = NO;
	androidImage.enabled = NO;
	consoleImage.enabled = NO;
	iphoneosLabel.alpha = 0.4;
	switchCtl.enabled = NO;
	sliderCtl.enabled = NO;
	linkButton.enabled = NO;
}

- (IBAction) tapIphoneos:(id)sender {
	iphoneosImage.alpha = 1.0;
	iphoneosLabel.alpha = 1.0;
	androidImage.alpha = 0.4;
	androidLabel.alpha = 0.4;
	consoleImage.alpha = 0.4;
	consoleLabel.alpha = 0.4;
	
	commonData *sharedData = [commonData sharedData];
	sharedData.opibDefaultOS = @"1";
}

- (IBAction) tapAndroid:(id)sender {
	iphoneosImage.alpha = 0.4;
	iphoneosLabel.alpha = 0.4;
	androidImage.alpha = 1.0;
	androidLabel.alpha = 1.0;
	consoleImage.alpha = 0.4;
	consoleLabel.alpha = 0.4;
	
	commonData *sharedData = [commonData sharedData];
	sharedData.opibDefaultOS = @"2";
}

- (IBAction) tapConsole:(id)sender {
	iphoneosImage.alpha = 0.4;
	iphoneosLabel.alpha = 0.4;
	androidImage.alpha = 0.4;
	androidLabel.alpha = 0.4;
	consoleImage.alpha = 1.0;
	consoleLabel.alpha = 1.0;
	
	commonData *sharedData = [commonData sharedData];
	sharedData.opibDefaultOS = @"3";
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	commonInstance = [[commonFunctions init] alloc];
	
	self.navigationItem.rightBarButtonItem = applyButton;
	
	commonData *sharedData = [commonData sharedData];
	
	tableRows = [[NSMutableArray alloc] init];
	
	NSArray *opibSection = [NSMutableArray arrayWithObjects:
							[NSMutableArray arrayWithObjects:@"defaultOS", osPicker, @"", nil],
							[NSMutableArray arrayWithObjects:@"autoBoot", self.switchCtl, @"Boot Default OS", nil],
							[NSMutableArray arrayWithObjects:@"timeoutLabel", self.labelWithVar, @"Timeout", nil],
							[NSMutableArray arrayWithObjects:@"timeoutSlider", self.sliderCtl, @"", nil],
							[NSMutableArray arrayWithObjects:@"advanced", self.linkButton, @"Advanced", nil],
							nil];
	
	[tableRows addObject:opibSection];
	
	//NSDictionary *idroidSection = [NSMutableArray arrayWithObjects:
	//								[NSMutableArray arrayWithObjects:@"autoBoot", self.linkButton, @"Boot Default OS", nil],
	//							   nil];
	
	//[tableRows addObject:idroidSection];
	
	sliderCtl.value = [sharedData.opibTimeout intValue] / 1000;	
	labelWithVar.text = [NSString stringWithFormat:@"%d", [sharedData.opibTimeout intValue] / 1000];
	labelWithVar.text = [labelWithVar.text stringByAppendingString:@" Seconds"];
	
	switch ([sharedData.opibDefaultOS intValue]) {
		case 1:
			iphoneosImage.alpha = 1.0;
			iphoneosLabel.alpha = 1.0;
			break;
		case 2:
			androidImage.alpha = 1.0;
			androidLabel.alpha = 1.0;
			break;
		case 3:
			consoleImage.alpha = 1.0;
			consoleLabel.alpha = 1.0;
			break;
			
		default:
			iphoneosImage.alpha = 1.0;
			iphoneosLabel.alpha = 1.0;
			NSLog(@"Default OS setting invalid. Defaulting to iPhone OS.");
	}
	NSLog(@"%@", sharedData.opibTimeout);
	if(([sharedData.opibTimeout intValue]/1000)==0){
		switchCtl.on = NO;
		sliderCtl.enabled = NO;
	} else {
		switchCtl.on = YES;
		sliderCtl.enabled = YES;
	}
	
	switch(sharedData.opibInitStatus) {
		case 0:
			break;
		case 1:
			[commonInstance sendConfirmation:@"Some required openiboot settings are missing.\r\nWould you like to generate them now?" withTag:8];
			[self disableOpibSettings];
			break;
		case -1:
			[commonInstance sendError:@"NVRAM backup failed.\r\nNVRAM could not be accessed."];
			[self disableOpibSettings];
			break;
		case -2:
			[commonInstance sendError:@"NVRAM backup failed.\r\nBackup could not be saved to disk."];
			[self disableOpibSettings];
			break;
		case -3:
			[commonInstance sendError:@"NVRAM could not be accessed."];
			[self disableOpibSettings];
			break;
		case -4:
			[commonInstance sendError:@"NVRAM configuration invalid."];
			[self disableOpibSettings];
			break;
		case -5:
			[commonInstance sendError:@"OpeniBoot is not installed or is incompatible."];
			[self disableOpibSettings];
			break;
		default:
			[commonInstance sendError:@"Unknown error occurred."];
			[self disableOpibSettings];
	}
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	commonData *sharedData = [commonData sharedData];
	
	if(sharedData.opibInitStatus==0) {
		applyButton.enabled = YES;
		iphoneosImage.enabled = YES;
		androidImage.enabled = YES;
		consoleImage.enabled = YES;
		switchCtl.enabled = YES;
		sliderCtl.enabled = YES;
		linkButton.enabled = YES;
	
		sliderCtl.value = [sharedData.opibTimeout intValue] / 1000;	
		labelWithVar.text = [NSString stringWithFormat:@"%d", [sharedData.opibTimeout intValue] / 1000];
		labelWithVar.text = [labelWithVar.text stringByAppendingString:@" Seconds"];
	
		switch ([sharedData.opibDefaultOS intValue]) {
			case 1:
				iphoneosImage.alpha = 1.0;
				iphoneosLabel.alpha = 1.0;
				androidImage.alpha = 0.4;
				androidLabel.alpha = 0.4;
				consoleImage.alpha = 0.4;
				consoleLabel.alpha = 0.4;
				break;
			case 2:
				iphoneosImage.alpha = 0.4;
				iphoneosLabel.alpha = 0.4;
				androidImage.alpha = 1.0;
				androidLabel.alpha = 1.0;
				consoleImage.alpha = 0.4;
				consoleLabel.alpha = 0.4;
				break;
			case 3:
				iphoneosImage.alpha = 0.4;
				iphoneosLabel.alpha = 0.4;
				androidImage.alpha = 0.4;
				androidLabel.alpha = 0.4;
				consoleImage.alpha = 1.0;
				consoleLabel.alpha = 1.0;
				break;
				
			default:
				iphoneosImage.alpha = 1.0;
				iphoneosLabel.alpha = 1.0;
				androidImage.alpha = 0.4;
				androidLabel.alpha = 0.4;
				consoleImage.alpha = 0.4;
				consoleLabel.alpha = 0.4;
				NSLog(@"Default OS setting invalid. Defaulting to iPhone OS.");
		}
		
		if(([sharedData.opibTimeout intValue]/1000)==0){
			switchCtl.on = NO;
			sliderCtl.enabled = NO;
		} else {
			switchCtl.on = YES;
			sliderCtl.enabled = YES;
		}
	}
}

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
	
	return [tableRows count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [[tableRows objectAtIndex:section] count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	NSString *sectionHeader = nil;
	
	if(section == 0) {
		sectionHeader = @"OpeniBoot";
	}
	if(section == 1) {
		sectionHeader = @"iDroid";
	}
	
	
	return sectionHeader;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    NSArray *thisSection = [tableRows objectAtIndex:indexPath.section];
	NSArray *thisCell = [thisSection objectAtIndex:indexPath.row];
	
	//cell.backgroundColor = [UIColor clearColor];
	
	UIControl *control = [thisCell objectAtIndex:1];
	[cell.contentView addSubview:control];
	
	cell.textLabel.backgroundColor = [UIColor clearColor];
	cell.textLabel.text = [thisCell objectAtIndex:2];
	
    return cell;
}
	
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row==0 && indexPath.section==0) {
		return 130;
	} else {
		return 44;
	}
}
	


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


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

