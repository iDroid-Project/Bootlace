//
//  OpeniBootConfigureViewController.h
//  Bootlace
//
//  Created by Neonkoala on 07/06/2010.
//  Copyright 2010 Nick Dawson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "OpeniBootClass.h"
#import "AdvancedViewController.h"


@interface OpeniBootConfigureViewController : UITableViewController {
	commonFunctions *commonInstance;
	OpeniBootClass *opibInstance;
	
	NSMutableArray *tableRows;
	
	UIBarButtonItem *applyButton;
	
	UILabel *iphoneosLabel;
	UIButton *iphoneosImage;
	UILabel *androidLabel;
	UIButton *androidImage;
	UILabel *consoleLabel;
	UIButton *consoleImage;
	
	UISwitch *switchCtl;
	UILabel *labelWithVar;
	UISlider *sliderCtl;
	UIButton *linkButton;
	UIView *osPicker;
}

@property (nonatomic, retain) commonFunctions *commonInstance;

@property (nonatomic, retain) NSMutableArray *tableRows;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *applyButton;

@property (nonatomic, retain) IBOutlet UILabel *iphoneosLabel;
@property (nonatomic, retain) IBOutlet UIButton *iphoneosImage;
@property (nonatomic, retain) IBOutlet UILabel *androidLabel;
@property (nonatomic, retain) IBOutlet UIButton *androidImage;
@property (nonatomic, retain) IBOutlet UILabel *consoleLabel;
@property (nonatomic, retain) IBOutlet UIButton *consoleImage;

@property (nonatomic, retain, readonly) UISwitch *switchCtl;
@property (nonatomic, retain, readonly) UILabel *labelWithVar;
@property (nonatomic, retain, readonly) UISlider *sliderCtl;
@property (nonatomic, retain, readonly) UIButton *linkButton;
@property (nonatomic, retain) IBOutlet UIView *osPicker;

- (void)switchAction:(id)sender;
- (void)sliderAction:(id)sender;
- (void)applyAction:(id)sender;
- (void)disableOpibSettings;
- (IBAction)tapIphoneos:(id)sender;
- (IBAction)tapAndroid:(id)sender;
- (IBAction)tapConsole:(id)sender;

@end
