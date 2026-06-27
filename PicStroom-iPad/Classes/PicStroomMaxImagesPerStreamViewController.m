//
//  PicStroomMaxImagesPerStreamViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 27/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomMaxImagesPerStreamViewController.h"

@implementation PicStroomMaxImagesPerStreamViewController
@synthesize maxImagesTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload {
    [self setMaxImagesTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [maxImagesTableView release];
    [super dealloc];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, maxImagesTableView.frame.size.width, 60)];
        footerView.backgroundColor = [UIColor clearColor];
        footerView.contentMode = UIViewContentModeCenter;
        
        UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 0, 425, 38)];
        helpLabel.backgroundColor = [UIColor clearColor];
        helpLabel.textAlignment = UITextAlignmentLeft;
        helpLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
        helpLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
        helpLabel.text = @"Dropbox folders and starred images are not affected.";
        
        UILabel *helpLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(180, 22, 425, 38)];
        helpLabel2.backgroundColor = [UIColor clearColor];
        helpLabel2.textAlignment = UITextAlignmentLeft;
        helpLabel2.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
        helpLabel2.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
        helpLabel2.text = @"Oldest images will be purged.";
        
        //// 
        [footerView addSubview:helpLabel];
        [footerView addSubview:helpLabel2];
        [helpLabel release];
        [helpLabel2 release];
        return [footerView autorelease];
    } else {
        return nil;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone; // reset if cached
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = BLANK_STRING;
    
    NSUInteger userDefaultMaxImagesPerStroom = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM] intValue];   
    
    if ([indexPath row] == 0) {
        cell.textLabel.text = @"50";
        if (userDefaultMaxImagesPerStroom == 50) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if ([indexPath row] == 1) {
        cell.textLabel.text = @"100";
        if (userDefaultMaxImagesPerStroom == 100) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if ([indexPath row] == 2) {
        cell.textLabel.text = @"250";
        if (userDefaultMaxImagesPerStroom == 250) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if ([indexPath row] == 3) {
        cell.textLabel.text = @"500";
        if (userDefaultMaxImagesPerStroom == 500) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if ([indexPath row] == 4) {
        cell.textLabel.text = @"1000";
        if (userDefaultMaxImagesPerStroom == 1000) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if ([indexPath row] == 5) {
        cell.textLabel.text = @"5000";
        if (userDefaultMaxImagesPerStroom == 5000) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else  {
        cell.textLabel.text = @"Unlimited";
        if (userDefaultMaxImagesPerStroom == 0) {
            cell.textLabel.textColor = [UIColor colorWithRed:56.0/255.0f green:85.0/255.0f blue:135.0/255.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } 
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if([indexPath row] == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:50] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else if ([indexPath row] == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:100] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else if ([indexPath row] == 2) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:250] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else if ([indexPath row] == 3) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:500] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else if ([indexPath row] == 4) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1000] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else if ([indexPath row] == 5) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:5000] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    } else  {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];
    }
    
    [tableView reloadData];
}



@end
