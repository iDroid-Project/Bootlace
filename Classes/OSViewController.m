//
//  OSViewController.m
//  Bootlace
//
//  Created by Neonkoala on 03/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OSViewController.h"


@implementation OSViewController

@synthesize osSelector, tableView, installButton, removeButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	self.tableView.scrollEnabled = NO;
	
	osImages = [[NSArray arrayWithObjects:
			   [UIImage imageNamed:@"iphoneos.png"],[UIImage imageNamed:@"console.png"],
			   [UIImage imageNamed:@"androidos.png"],nil] retain];
	
	
	osSelector = [[TKCoverflowView alloc] initWithFrame:CGRectMake(0, 0, 320, 120)];
	osSelector.delegate = self;
	osSelector.dataSource = self;
	[self.view addSubview:osSelector];
	[osSelector setNumberOfCovers:3];
	
	installButton.tintColor = [UIColor colorWithRed:0.024 green:0.197 blue:0.419 alpha:1.000];
	removeButton.tintColor = [UIColor colorWithRed:0.556 green:0.000 blue:0.000 alpha:1.000];
	
    [super viewDidLoad];
}

- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index{
	NSLog(@"Front %d",index);
}

- (TKCoverflowCoverView*) coverflowView:(TKCoverflowView*)coverflowView coverAtIndex:(int)index{
	
	TKCoverflowCoverView *cover = [coverflowView dequeueReusableCoverView];
	
	if(cover == nil){
		cover = [[[TKCoverflowCoverView alloc] initWithFrame:CGRectMake(0, 0, 80, 100)] autorelease];
		cover.baseline = 70;
		
	}
	cover.image = [osImages objectAtIndex:index%[osImages count]];
	
	return cover;
	
}

- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasDoubleTapped:(int)index{
	NSLog(@"Index: %d",index);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //Only 1 section - just want that rounded goodness
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //3 Rows of info, more than enough for anyone and their dog
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	//None needed
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		cell.backgroundColor = [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1.0];
    }
    
    // Configure the cell...
    
    return cell;
}

- (IBAction)installTap:(id)sender {

}

- (IBAction)removeTap:(id)sender {
	
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
