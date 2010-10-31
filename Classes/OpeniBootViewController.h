//
//  OpeniBootViewController.h
//  BootlaceV2
//
//  Created by Neonkoala on 25/09/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "OpeniBootClass.h"
#import "OpeniBootConfigureViewController.h"


@interface OpeniBootViewController : UIViewController <UIAlertViewDelegate> {
	commonFunctions *commonInstance;
	OpeniBootClass *opibInstance;
	
	NSOperationQueue *viewInitQueue;
	
	UIBarButtonItem *opibLoadingButton;
	UIBarButtonItem *opibRefreshButton;
	UILabel *opibVersionLabel;
	UILabel *opibReleaseDateLabel;
	UILabel *installStageLabel;
	UIGlassButton *opibInstall;
	UIGlassButton *opibConfigure;
	UIActivityIndicatorView *cfuSpinner;
	UIProgressView *installProgress;
}

@property (nonatomic, retain) NSOperationQueue *viewInitQueue;

@property (nonatomic, retain) UIBarButtonItem *opibLoadingButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *opibRefreshButton;
@property (nonatomic, retain) IBOutlet UILabel *opibVersionLabel;
@property (nonatomic, retain) IBOutlet UILabel *opibReleaseDateLabel;
@property (nonatomic, retain) UILabel *installStageLabel;
@property (nonatomic, retain) IBOutlet UIGlassButton *opibInstall;
@property (nonatomic, retain) IBOutlet UIGlassButton *opibConfigure;
@property (nonatomic, retain) UIActivityIndicatorView *cfuSpinner;
@property (nonatomic, retain) UIProgressView *installProgress;

- (IBAction)opibRefreshTap:(id)sender;
- (IBAction)opibInstallTap:(id)sender;
- (IBAction)opibRemoveTap:(id)sender;
- (IBAction)opibConfigureTap:(id)sender;

- (void)opibOperation:(NSNumber *)operation;
- (void)refreshView;
- (void)opibUpdateCheck;
- (void)switchButtons;

@end
