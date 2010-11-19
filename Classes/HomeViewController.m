//
//  HomeViewController.m
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright Nick Dawson 2010. All rights reserved.
//

#import "HomeViewController.h"


@implementation HomeViewController

@synthesize commonInstance, homePage, aboutPage, homeAboutView, doneButton, aboutButton, refreshButton, stopButton, backButton, initialLoad;

- (IBAction)refreshHome:(id)sender {
	[homePage reload];
}

- (IBAction)stopLoading:(id)sender {
	[homePage stopLoading];
}

- (IBAction)goBack:(id)sender {
	[homePage goBack];
}

- (void)flipAction:(id)sender {
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:animationIDfinished:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.75];
	
	[UIView setAnimationTransition:([self.view superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.view cache:YES];
	
	if ([homeAboutView superview])
		[homeAboutView removeFromSuperview];
	else
		[self.view addSubview:homeAboutView];
	
	[UIView commitAnimations];
	
	if ([homeAboutView superview] == self.view) {
		self.navigationItem.leftBarButtonItem = doneButton;
		self.navigationItem.rightBarButtonItem = nil;
		self.title = @"About";
	} else {
		self.navigationItem.leftBarButtonItem = aboutButton;
		self.navigationItem.rightBarButtonItem = refreshButton;
		self.title = @"Home";
	}
}

- (void)checkUpdates {
	commonData *sharedData = [commonData sharedData];
	
	NSURL *versionURL;
	
	if(sharedData.debugMode) {
		versionURL = [NSURL URLWithString:@"http://beta.neonkoala.co.uk/version.plist"];
	} else {
		versionURL = [NSURL URLWithString:@"http://bootlace.me/version.plist"];
	}
	
	NSMutableDictionary *versionDict = [NSMutableDictionary dictionaryWithContentsOfURL:versionURL];
	
	NSString *latestVersion = [versionDict objectForKey:@"Version"];
	
	if(latestVersion==nil) {
		[[UIApplication sharedApplication] setApplicationBadgeString:@""];
		return;
	} else if([latestVersion compare:sharedData.bootlaceVersion options:NSNumericSearch] == NSOrderedDescending) {
		DLog(@"Update available for Bootlace: %@", latestVersion);
		
		sharedData.bootlaceUpgradeAvailable = YES;
		
		[[UIApplication sharedApplication] setApplicationBadgeString:@"!"];
		
		NSString *updateTitle = [NSString stringWithFormat:@"Version %@ Available", latestVersion];
		
		UIAlertView *updateAlert;
		updateAlert = [[[UIAlertView alloc] initWithTitle:updateTitle message:@"An update to Bootlace is available.\r\n\r\nIt is highly recommended you use Cydia to install it immediately." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[updateAlert show];
	} else {
		DLog(@"No updates available for Bootlace currently.");
		
		[[UIApplication sharedApplication] setApplicationBadgeString:@""];
	}
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
	
	initialLoad = YES;
	
	commonData *sharedData = [commonData sharedData];
	commonInstance = [[commonFunctions alloc] init];
	
	NSString *urlAddress = @"http://app.bootlace.me/";
	
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	
	//Load the request in the UIWebView.
	[homePage setDelegate:self];
	[homePage loadRequest:requestObj];
	
	if(!sharedData.secondLaunch) {
		[commonInstance firstLaunch];
		sharedData.secondLaunch = YES;
	}
	
	//Load about page
	[aboutPage setBackgroundColor:[UIColor clearColor]];
	[aboutPage loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]isDirectory:NO]]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self performSelectorOnMainThread:@selector(loadingWebView) withObject:nil waitUntilDone:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self performSelectorOnMainThread:@selector(showWebView) withObject:nil waitUntilDone:NO];
	
	if(initialLoad) {
		DLog(@"Initial load, checking for updates");
		
		[self checkUpdates];
		
		initialLoad = NO;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self performSelectorOnMainThread:@selector(showWebView) withObject:nil waitUntilDone:NO];
}

- (void)loadingWebView {
	UIActivityIndicatorView *pageLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[pageLoading startAnimating];
	
	UIBarButtonItem *loadingButton = [[UIBarButtonItem alloc] initWithCustomView:pageLoading];
	
	self.navigationItem.rightBarButtonItem = loadingButton;
}

- (void)showWebView {
	[homePage setHidden:NO];
	
	if([homeAboutView superview] != self.view) {
		self.navigationItem.rightBarButtonItem = refreshButton;
	}
	
	if(homePage.canGoBack) {
		self.navigationItem.leftBarButtonItem = backButton;
	} else {
		self.navigationItem.leftBarButtonItem = aboutButton;
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

- (void)viewWillDisappear
{
    if ([homePage isLoading])
        [homePage stopLoading];
	[homePage release];
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
