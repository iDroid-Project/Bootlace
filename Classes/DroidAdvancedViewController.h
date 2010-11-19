//
//  DroidAdvancedViewController.h
//  BootlaceV2
//
//  Created by Neonkoala on 23/08/2010.
//  Copyright 2010 Neonkoala.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "commonData.h"
#import "commonFunctions.h"
#import "installClass.h"
#import "getFile.h"
#import "extractionClass.h"

@class commonFunctions;
@class installClass;
@class extractionClass;

@interface DroidAdvancedViewController : UIViewController <UIActionSheetDelegate> {
	installClass *installInstance;
	commonFunctions *commonInstance;
	extractionClass *extractionInstance;
	getFile *getFileInstance;
	
	UIGlassButton *multitouchInstall;
	UIGlassButton *resetUserDataButton;
}

@property (nonatomic, retain) installClass *installInstance;
@property (nonatomic, retain) commonFunctions *commonInstance;
@property (nonatomic, retain) extractionClass *extractionInstance;

@property (nonatomic, retain) IBOutlet UIGlassButton *multitouchInstall;
@property (nonatomic, retain) IBOutlet UIGlassButton *resetUserDataButton;

- (IBAction)extractMultitouch:(id)sender;
- (IBAction)resetUserData:(id)sender;
- (void)dumpZephyr;
- (void)doReset;

@end
