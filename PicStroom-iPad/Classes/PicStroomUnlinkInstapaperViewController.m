//
//  PicStroomUnlinkInstapaperViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomUnlinkInstapaperViewController.h"
#import "PicStroomViewController.h"

#import "SFHFKeychainUtils.h"

@implementation PicStroomUnlinkInstapaperViewController
@synthesize unlinkInstapaperTableView;

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
    self.title = @"Unlink from Instapaper";
}

- (void)viewDidUnload {
    [self setUnlinkInstapaperTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [unlinkInstapaperTableView release];
    [super dealloc];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source & delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    
    cell.textLabel.text = @"Unlink from Instapaper";
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, unlinkInstapaperTableView.frame.size.width, 38)];
        footerView.backgroundColor = [UIColor clearColor];
        footerView.contentMode = UIViewContentModeCenter;
        
        UILabel *instapaperAccountLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 425, 38)];
        instapaperAccountLabel.backgroundColor = [UIColor clearColor];
        instapaperAccountLabel.textAlignment = UITextAlignmentLeft;
        instapaperAccountLabel.textColor = [UIColor lightGrayColor];
        instapaperAccountLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
        instapaperAccountLabel.text = @"PicStroom is linked to your Instapaper account";
        
        [footerView addSubview:instapaperAccountLabel];
        [instapaperAccountLabel release];
        return [footerView autorelease];
    } else {
        return nil;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm unlinking Instapaper" message:@"Please confirm that you want to unlink this application from your Instapaper account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlink", nil];
    [alertView show];
    [alertView release];
}

- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 1) {
        NSError *error;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE];
        [SFHFKeychainUtils deleteItemForUsername:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY andServiceName:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY error:&error];
        
        [FlurryAPI logEvent:FLURRY_UNLINK_INSTAPAPER];
        
        PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
        [mainViewController.stroomTableView reloadData];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


@end
