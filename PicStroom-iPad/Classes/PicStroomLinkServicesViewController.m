//
//  PicStroomLinkServicesViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomLinkServicesViewController.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomUnlinkDropboxViewController.h"
#import "PicStroomSetDropboxSaveFolderViewController.h"
#import "PicStroomLinkInstapaperViewController.h"
#import "PicStroomUnlinkInstapaperViewController.h"
#import "DBSession.h"
#import "PicStroomInstapaperManager.h"

@implementation PicStroomLinkServicesViewController
@synthesize linkServicesTableView;

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
    self.title = @"Link/Unlink Services";
}

- (void)viewDidUnload {
    [self setLinkServicesTableView:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.linkServicesTableView reloadData];
    DebugLog(@"view will appear");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [linkServicesTableView release];
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return 1;
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Dropbox";
    } else if (section == 1) {
        return @"Instapaper";
    } else {
        return @"";
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    
    if ([indexPath section] == 0 && [indexPath row] == 0) {
        if ([[DBSession sharedSession] isLinked]) {
            cell.textLabel.text = @"Unlink from Dropbox";
        } else {
            cell.textLabel.text = @"Link to Dropbox";
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (appDelegate.currentNetworkStatus == NotReachable) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
    } else if ([indexPath section] == 0 && [indexPath row] == 1) {
        cell.textLabel.text = @"Set Dropbox save folder";
        if (![[DBSession sharedSession] isLinked]) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (appDelegate.currentNetworkStatus == NotReachable) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
    } else if ([indexPath section] == 1 && [indexPath row] == 0) {
        if(![PicStroomInstapaperManager isInstapaperLinked]) {
            cell.textLabel.text = @"Link to Instapaper";
            if (appDelegate.currentNetworkStatus == NotReachable) { //unlinking does not require network access
                cell.textLabel.textColor = [UIColor lightGrayColor];
            }
        } else {
           cell.textLabel.text = @"Unlink from Instapaper"; 
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    
    if (([indexPath section] == 0) && ([indexPath row] == 0)) {
        // link/unlink dropbox
        
        if (appDelegate.currentNetworkStatus == NotReachable) {
            return;
        }
        
        if ([[DBSession sharedSession] isLinked]) {
            PicStroomUnlinkDropboxViewController *unlinkDropboxController = [[PicStroomUnlinkDropboxViewController alloc] initWithNibName:@"PicStroomUnlinkDropboxViewController" bundle:nil];
            [self.navigationController pushViewController:unlinkDropboxController animated:YES];
            [unlinkDropboxController release];
        } else {
            PicStroomLinkDropboxViewController *linkDropboxController = [[PicStroomLinkDropboxViewController alloc] initWithNibName:@"PicStroomLinkDropboxViewController" bundle:nil];
            linkDropboxController.loadFromSettings = YES;
            [self.navigationController pushViewController:linkDropboxController animated:YES];
            [linkDropboxController release];
        }
    } else if (([indexPath section] == 0) && ([indexPath row] == 1)) {
        if (appDelegate.currentNetworkStatus == NotReachable) {
            return;
        }
        
        if ([[DBSession sharedSession] isLinked]) {
            PicStroomSetDropboxSaveFolderViewController *setDropboxSaveFolderController = [[PicStroomSetDropboxSaveFolderViewController alloc] initWithNibName:@"PicStroomSetDropboxSaveFolderViewController" bundle:nil];
            [self.navigationController pushViewController:setDropboxSaveFolderController animated:YES];
            [setDropboxSaveFolderController release];
        } else {
            return;
        }
    } else if (([indexPath section] == 1) && ([indexPath row] == 0)) {
        if(![PicStroomInstapaperManager isInstapaperLinked]) {
            if (appDelegate.currentNetworkStatus == NotReachable) {
                return;
            }
            
            PicStroomLinkInstapaperViewController *linkInstapaperViewController = [[PicStroomLinkInstapaperViewController alloc] initWithNibName:@"PicStroomLinkInstapaperViewController" bundle:nil];
            linkInstapaperViewController.loadFromSettings = YES;
            [self.navigationController pushViewController:linkInstapaperViewController animated:YES];
            [linkInstapaperViewController release];
        } else {
            PicStroomUnlinkInstapaperViewController *unlinkInstapaperViewController = [[PicStroomUnlinkInstapaperViewController alloc] initWithNibName:@"PicStroomUnlinkInstapaperViewController" bundle:nil];
            [self.navigationController pushViewController:unlinkInstapaperViewController animated:YES];
            [unlinkInstapaperViewController release];
        }
    }
}

@end