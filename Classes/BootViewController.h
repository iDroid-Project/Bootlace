//
//  BootViewController.h
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "commonData.h"
#import "commonFunctions.h"


@interface BootViewController : UIViewController {
	commonFunctions *commonInstance;
	
	UIView *quickBootAboutView;
	UIView *quickBootDisabledView;
	UIWebView *quickBootWebView;
	UIBarButtonItem *doneButton;
	UIBarButtonItem *flipButton;
	UIButton *androidRebootButton;
	UIButton *consoleRebootButton;
	UILabel *consoleRebootLabel;
	UILabel *androidRebootLabel;
}

@property (nonatomic, retain) commonFunctions *commonInstance;

@property (nonatomic, retain) IBOutlet UIView *quickBootAboutView;
@property (nonatomic, retain) IBOutlet UIView *quickBootDisabledView;
@property (nonatomic, retain) IBOutlet UIWebView *quickBootWebView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *flipButton;
@property (nonatomic, retain) IBOutlet UIButton *androidRebootButton;
@property (nonatomic, retain) IBOutlet UIButton *consoleRebootButton;
@property (nonatomic, retain) IBOutlet UILabel *consoleRebootLabel;
@property (nonatomic, retain) IBOutlet UILabel *androidRebootLabel;

- (void)flipAction:(id)sender;
- (IBAction)rebootToAndroid:(id)sender;
- (IBAction)rebootToConsole:(id)sender;
- (void)disableQuickboot;

@end
