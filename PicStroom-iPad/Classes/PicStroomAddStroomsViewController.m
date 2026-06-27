//
//  PicStroomAddStroomsViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomAddStroomsViewController.h"
#import "PicStroomAddDropboxStroomViewController.h"
#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomSelectedDBResourcesManager.h"
#import "PicStroomListStroomsViewController.h"
#import "PicStroomGalleryController.h"
#import "PicStroomViewController.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomEmbeddedBrowserViewController.h"

@implementation PicStroomAddStroomsViewController
@synthesize delegate;
@synthesize addStroomsTableView;
@synthesize hideDoneBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void) dealloc {
    [addStroomsTableView release];
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add a Stream";

    if (hideDoneBtn == NO) {
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)];
        self.navigationItem.rightBarButtonItem = doneBtn;
        [doneBtn release];
    }
}

- (void) viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone {
    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else {
        return 1;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
    if ([indexPath section] == 0 && [indexPath row] == 0) {
        cell.textLabel.text = @"Add Web Stream";
        cell.detailTextLabel.text = @"Add a url or browse web sites to add web Streams";
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if ([indexPath section] == 1 && [indexPath row] == 0) {
        cell.textLabel.text = @"Add Dropbox folder";
        cell.detailTextLabel.text = @"Use Dropbox to save, order and share pictures";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([indexPath section] == 1 && [indexPath row] == 1) {
        cell.textLabel.text = @"Browse the Gallery";
        cell.detailTextLabel.text = @"Looking for inspiration? Here are some Streams that we like";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
        if (appDelegate.currentNetworkStatus == NotReachable) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    } else if ([indexPath section] == 2 && [indexPath row] == 0) {
        cell.textLabel.text = @"Edit/Order/Delete Streams";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath section] == 0 && [indexPath row] == 0) {
        [delegate didMakeRequestToLaunchBrowser:self];
    } else if ([indexPath section] == 1 && [indexPath row] == 0) {
        if ([[DBSession sharedSession] isLinked]) {
            [[PicStroomSelectedDBResourcesManager currentManager] reset];
            PicStroomAddDropboxStroomViewController *addDropboxStroomViewController = [[PicStroomAddDropboxStroomViewController alloc] initWithNibName:@"PicStroomAddDropboxStroomViewController" bundle:nil];
            [self.navigationController pushViewController:addDropboxStroomViewController animated:YES];
            [addDropboxStroomViewController release];
        } else {
            PicStroomLinkDropboxViewController *linkDropboxViewController = [[PicStroomLinkDropboxViewController alloc] initWithNibName:@"PicStroomLinkDropboxViewController" bundle:nil];
            [self.navigationController pushViewController:linkDropboxViewController animated:YES];
            [linkDropboxViewController release];
        }
    } else if ([indexPath section] == 1 && [indexPath row] == 1) {
        PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        if (appDelegate.currentNetworkStatus == NotReachable) {
            return;
        } else {
            PicStroomGalleryController *galleryViewController = [[PicStroomGalleryController alloc] initWithNibName:@"PicStroomGalleryController" bundle:nil];
            [self.navigationController pushViewController:galleryViewController animated:YES];
            [galleryViewController release];
        }
    } else if ([indexPath section] == 2 && [indexPath row] == 0) {
        PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
        if ([mainViewController.stroomSupervisors count] == 0) {
            return;
        }
        PicStroomListStroomsViewController *listStroomsController = [[PicStroomListStroomsViewController alloc] initWithNibName:@"PicStroomListStroomsViewController" bundle:nil];
        listStroomsController.mainViewController = mainViewController;
        [self.navigationController pushViewController:listStroomsController animated:YES];
        [listStroomsController release];
    }
}

@end