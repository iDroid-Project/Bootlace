//
//  BootViewController.m
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright Nick Dawson 2010. All rights reserved.
//

#import "BootViewController.h"

@implementation BootViewController

@synthesize commonInstance, quickBootAboutView, quickBootDisabledView, quickBootWebView, doneButton, flipButton, androidRebootButton, consoleRebootButton, androidRebootLabel, consoleRebootLabel;


- (void)flipAction:(id)sender
{
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:animationIDfinished:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.75];
	
	[UIView setAnimationTransition:([self.view superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.view cache:YES];
	
	if ([quickBootAboutView superview])
		[quickBootAboutView removeFromSuperview];
	else
		[self.view addSubview:quickBootAboutView];
	
	[UIView commitAnimations];
	
	// adjust our done/info buttons accordingly
	if ([quickBootAboutView superview] == self.view)
		self.navigationItem.rightBarButtonItem = doneButton;
	else
		self.navigationItem.rightBarButtonItem = flipButton;
}

- (IBAction)rebootToAndroid:(id)sender {
	commonInstance = [[commonFunctions alloc] init];
	
	[commonInstance sendConfirmation:@"This will reboot your device into Android immediately.\r\nAre you sure?" withTag:2];
}

- (IBAction)rebootToConsole:(id)sender {
	commonInstance = [[commonFunctions alloc] init];
	
	[commonInstance sendConfirmation:@"This will reboot your device into the console immediately.\r\nAre you sure?" withTag:3];
}

- (void)disableQuickboot {
	androidRebootButton.enabled = NO;
	consoleRebootButton.enabled = NO;
	androidRebootLabel.alpha = 0.4;
	consoleRebootLabel.alpha = 0.4;
	[self.view addSubview:quickBootDisabledView];
}

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
	 [super viewDidLoad];
	 
	 commonData *sharedData = [commonData sharedData];
	 commonInstance = [[commonFunctions alloc] init];
	 
	 // add our custom flip button as the nav bar's custom right view
	 UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	 [infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	 flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	 self.navigationItem.rightBarButtonItem = flipButton;
	 
	 switch(sharedData.opibInitStatus) {
		 case 0:
			 break;
		 case 1:
			 [commonInstance sendConfirmation:@"Some required openiboot settings are missing.\r\nWould you like to generate them now?" withTag:8];
			 [self disableQuickboot];
			 break;
		 case -1:
			 [commonInstance sendError:@"NVRAM Backup failed."];
			 [self disableQuickboot];
			 break;
		 case -2:
			 [commonInstance sendError:@"NVRAM Could not be read."];
			 [self disableQuickboot];
			 break;
		 case -3:
			 [commonInstance sendError:@"NVRAM Could not be read."];
			 [self disableQuickboot];
			 break;
		 case -4:
			 [commonInstance sendError:@"NVRAM configuration invalid."];
			 [self disableQuickboot];
			 break;
		 case -5:
			 [commonInstance sendError:@"Openiboot is not installed or is incompatible."];
			 [self disableQuickboot];
			 break;
		 default:
			 [commonInstance sendError:@"Unknown error occurred."];
			 [self disableQuickboot];
	 }
	 
	 [quickBootWebView setBackgroundColor:[UIColor clearColor]];
	 [quickBootWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"qbhelp" ofType:@"html"]isDirectory:NO]]];
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
