//
//  HomeViewController.h
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright Nick Dawson 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication2.h>
#import "commonData.h"
#import "commonFunctions.h"


@interface HomeViewController : UIViewController <UIWebViewDelegate> {
	commonFunctions *commonInstance;
	
	UIWebView *homePage;
	UIWebView *aboutPage;
	UIView *homeAboutView;
	UIBarButtonItem *doneButton;
	UIBarButtonItem *aboutButton;
	UIBarButtonItem *refreshButton;
	UIBarButtonItem *stopButton;
	UIBarButtonItem *backButton;
	
	BOOL initialLoad;
}

@property (nonatomic, retain) commonFunctions *commonInstance;

@property (nonatomic, retain) IBOutlet UIWebView *homePage;
@property (nonatomic, retain) IBOutlet UIWebView *aboutPage;
@property (nonatomic, retain) IBOutlet UIView *homeAboutView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *aboutButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *stopButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;

@property (nonatomic, assign) BOOL initialLoad;

- (void)checkUpdates;
- (void)flipAction:(id)sender;
- (IBAction)refreshHome:(id)sender;
- (IBAction)stopLoading:(id)sender;
- (IBAction)goBack:(id)sender;
- (void)showWebView;
- (void)loadingWebView;

@end
