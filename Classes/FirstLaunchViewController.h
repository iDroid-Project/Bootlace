//
//  FirstLaunchViewController.h
//  BootlaceV2
//
//  Created by Neonkoala on 29/10/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIProgressHUD.h>
#import <sys/reboot.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "OpeniBootClass.h"


@interface FirstLaunchViewController : UIViewController <UIAlertViewDelegate> {
	commonFunctions *commonInstance;
	OpeniBootClass *opibInstance;
	
	UIProgressHUD *patchingProgress;
	NSTimer	*guiLoop;
}

@property (nonatomic, retain) UIProgressHUD *patchingProgress;
@property (nonatomic, retain) NSTimer *guiLoop;

- (void)updateGUI:(NSTimer *)theTimer;

@end
