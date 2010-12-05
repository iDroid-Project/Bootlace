//
//  OSViewController.h
//  Bootlace
//
//  Created by Neonkoala on 03/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIGlassButton.h>
#import <UIKit/UIKit.h>
#import "TKCoverflowView.h"
#import "TKCoverflowCoverView.h"

@interface OSViewController : UIViewController <TKCoverflowViewDelegate, TKCoverflowViewDataSource, UITableViewDelegate, UITableViewDataSource> {
	TKCoverflowView *osSelector;
	UITableView *tableView;
	
	NSMutableArray *tableRows;
	NSMutableArray *osImages;
	
	UIGlassButton *installButton;
	UIGlassButton *removeButton;
}

@property (nonatomic, retain) TKCoverflowView *osSelector;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) IBOutlet UIGlassButton *installButton;
@property (nonatomic, retain) IBOutlet UIGlassButton *removeButton;

- (IBAction)installTap:(id)sender;
- (IBAction)removeTap:(id)sender;

@end
