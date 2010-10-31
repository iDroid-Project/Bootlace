//
//  DroidViewController.h
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright Nick Dawson 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <UIKit/UIGlassButton.h>
#import "DroidAdvancedViewController.h"
#import "commonData.h"
#import "commonFunctions.h"
#import "installClass.h"

@class installClass;
@class commonFunctions;

@interface DroidViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>  {
	installClass *installInstance;
	commonFunctions *commonInstance;
	
	UIBarButtonItem *flipButton;
	UITableView *tableView;
	NSMutableArray *tableRows;
	NSOperationQueue *viewInitQueue;
	UIActivityIndicatorView *cfuSpinner;
	UIProgressView *installOverallProgress;
	UIProgressView *installCurrentProgress;
	UILabel *installStageLabel;
	UIProgressView *upgradeOverallProgress;
	UIProgressView *upgradeCurrentProgress;
	UILabel *upgradeStageLabel;
	UIButton *latestVersionButton;
	UIGlassButton *installIdroidButton;
	UIGlassButton *removeIdroidButton;
	UIButton *installIdroidImage;
	UIButton *removeIdroidImage;
}

@property (nonatomic, retain) installClass *installInstance;
@property (nonatomic, retain) commonFunctions *commonInstance;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *flipButton;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *tableRows;
@property (nonatomic, retain) NSOperationQueue *viewInitQueue;
@property (nonatomic, retain) UIActivityIndicatorView *cfuSpinner;
@property (nonatomic, retain) UIProgressView *installOverallProgress;
@property (nonatomic, retain) UIProgressView *installCurrentProgress;
@property (nonatomic, retain) UILabel *installStageLabel;
@property (nonatomic, retain) UIProgressView *upgradeOverallProgress;
@property (nonatomic, retain) UIProgressView *upgradeCurrentProgress;
@property (nonatomic, retain) UILabel *upgradeStageLabel;
@property (nonatomic, retain) UIGlassButton *installIdroidButton;
@property (nonatomic, retain) UIGlassButton *removeIdroidButton;
@property (nonatomic, retain) IBOutlet UIButton *latestVersionButton;
@property (nonatomic, retain) IBOutlet UIButton *installIdroidImage;
@property (nonatomic, retain) IBOutlet UIButton *removeIdroidImage;

- (IBAction)checkForUpdatesManual:(id)sender;
- (IBAction)installPress:(id)sender;
- (IBAction)upgradePress:(id)sender;
- (IBAction)removePress:(id)sender;
- (void)loadAdvanced:(id)sender;
- (void)installIdroid;
- (void)upgradeIdroid;
- (void)removeIdroid;
- (void)callUpdate;
- (void)callInstall;
- (void)callUpgrade;
- (void)callRemove;
- (void)refreshUpdate;
- (void)refreshStatus;

@end
