//
//  PicStroomUnlinkDropboxViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PicStroomUnlinkDropboxViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomSupervisor.h"
#import "PicStroomManager.h"
#import "Stroom.h"
#import "DBSession.h"


@implementation PicStroomUnlinkDropboxViewController
@synthesize unlinkDropboxTableView;


- (void) dealloc {
    [unlinkDropboxTableView release];
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Unlink from Dropbox";

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewDidUnload {
    [self setUnlinkDropboxTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = @"Unlink from Dropbox";
    cell.textLabel.textAlignment = UITextAlignmentCenter;

    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, unlinkDropboxTableView.frame.size.width, 38)];
        footerView.backgroundColor = [UIColor clearColor];
        footerView.contentMode = UIViewContentModeCenter;

        UILabel *dropboxAccountLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 0, 425, 38)];
        dropboxAccountLabel.backgroundColor = [UIColor clearColor];
        dropboxAccountLabel.textAlignment = UITextAlignmentLeft;
        dropboxAccountLabel.textColor = [UIColor lightGrayColor];
        dropboxAccountLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
        dropboxAccountLabel.text = [NSString stringWithFormat:@"Linked to your %@ Dropbox account", [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE]];

        [footerView addSubview:dropboxAccountLabel];
        [dropboxAccountLabel release];
        return [footerView autorelease];
    } else {
        return nil;
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm unlinking Dropbox" message:@"Please confirm that you want to unlink this application from your Dropbox account. All Dropbox based Streams will be deleted on this device."
                                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlink", nil];
    [alertView show];
    [alertView release];
}

- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 1) {
        UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        [[DBSession sharedSession] unlink];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE];
        [FlurryAPI logEvent:FLURRY_EVENT_UNLINK_DROPBOX];

        PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
        NSMutableArray *dropboxSupervisors = [[NSMutableArray alloc] init];

        NSInteger count = 0;
        for (PicStroomSupervisor *stroomSupervisor in mainViewController.stroomSupervisors) {
            if ([stroomSupervisor.stroom.type intValue] == StroomTypeDropbox) {
                [dropboxSupervisors addObject:stroomSupervisor];
            }
            count++;
        }

        if (count > 0) {
            PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
            for (PicStroomSupervisor *stroomSupervisor in dropboxSupervisors) {
                [mainViewController.stroomSupervisors removeObject:stroomSupervisor];
                [stroomManager deleteStroom:stroomSupervisor.stroom];
            }
            [stroomManager release];
        }

        [dropboxSupervisors release];
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        [mainViewController.stroomTableView reloadData];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
