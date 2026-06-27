//
//  PicStroomLinkDropboxViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomAddDropboxStroomViewController.h"
#import "PicStroomFullScreenPhotoViewController.h"
#import "PicStroomLinkDropboxHeaderView.h"
#import "PicStroomLinkDropboxFooterView.h"
#import "DBRestClient.h"

@implementation PicStroomLinkDropboxViewController
@synthesize linkDropboxTableView;
@synthesize directlyLoaded;
@synthesize loadFromSettings;
@synthesize loadFromFullScreenPhotoView;
@synthesize translucentView;
@synthesize av;

- (void) dealloc {
    [linkDropboxTableView release];
    if (restClient != nil) {
        [restClient release];
    }
    DebugLog(@"link dropbox view controller dealloc()");
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Link Dropbox";

    PicStroomLinkDropboxHeaderView *tableHeaderViewController = [[[PicStroomLinkDropboxHeaderView alloc] initWithNibName:@"PicStroomLinkDropboxHeaderView" bundle:nil] autorelease];
    self.linkDropboxTableView.tableHeaderView = tableHeaderViewController.view;

    PicStroomLinkDropboxFooterView *tableFooterViewController = [[[PicStroomLinkDropboxFooterView alloc] initWithNibName:@"PicStroomLinkDropboxFooterView" bundle:nil] autorelease];
    self.linkDropboxTableView.tableFooterView = tableFooterViewController.view;

    UIBarButtonItem *doneBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    self.navigationItem.rightBarButtonItem = doneBtn;

    if (directlyLoaded) {
        UIBarButtonItem *cancelBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressCancel)] autorelease];
        self.navigationItem.leftBarButtonItem = cancelBtn;
    }
}

- (BOOL) disablesAutomaticKeyboardDismissal {
    return YES;
}

- (void) viewDidUnload {
    [self setLinkDropboxTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) didPressDone {
    // link to dropbox
    if ([emailField.text length] == 0) {
        [self errorWithTitle:@"Email Required" message:@"Please enter your email."];
        [emailField becomeFirstResponder];
        return;
    } else if ([passwordField.text length] == 0) {
        [self errorWithTitle:@"Password Required" message:@"Please enter you password."];
        [passwordField becomeFirstResponder];
        return;
    }

    self.translucentView = [[[UIView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width / 2) - 100 / 2), ((self.view.frame.size.height / 2) - 100 / 2), 100, 100)] autorelease];
    self.av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    self.av.frame = CGRectMake(((self.translucentView.frame.size.width / 2) - 36 / 2), ((self.translucentView.frame.size.height / 2) - 36 / 2), 36, 36);
    self.translucentView.backgroundColor = [UIColor blackColor];
    self.translucentView.alpha = 0.7;
    self.translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;
    [self.translucentView addSubview:self.av];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(23, 68, 80, 20)];
    label.text = @"Linking";
    label.font = [UIFont fontWithName:BOLD_FONT size:14.0f];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [self.translucentView addSubview:label];
    [label release];
    
    [self.view addSubview:self.translucentView];
    [self.av startAnimating];

    [self.restClient loginWithEmail:emailField.text password:passwordField.text];
}

- (void) didPressCancel {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark DBRestClient methods

- (void) restClientDidLogin:(DBRestClient *)client {
    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;

    [FlurryAPI logEvent:FLURRY_EVENT_LINK_DROPBOX];
    [[NSUserDefaults standardUserDefaults] setObject:emailField.text forKey:USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE];
    [[NSUserDefaults standardUserDefaults] setObject:@"/Photos" forKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER];
    DebugLog(@"Setting dropbox save folder to default of /Phtotos");

    if (loadFromFullScreenPhotoView) {
        [self dismissModalViewControllerAnimated:YES];
        PicStroomFullScreenPhotoViewController *controller = (PicStroomFullScreenPhotoViewController *)self.navigationController.parentViewController;
        [controller saveDropBoxBtnPressed:nil];
        return;
    }

    if (loadFromSettings) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    PicStroomAddDropboxStroomViewController *addDropboxStroomViewController = [[PicStroomAddDropboxStroomViewController alloc] initWithNibName:@"PicStroomAddDropboxStroomViewController" bundle:nil];
    [self.navigationController pushViewController:addDropboxStroomViewController animated:YES];
    [addDropboxStroomViewController release];
}

- (void) restClient:(DBRestClient *)client loginFailedWithError:(NSError *)error {
    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;

    NSString *message;
    if ([error.domain isEqual:NSURLErrorDomain]) {
        message = @"There was an error connecting to Dropbox.";
    } else {
        NSObject *errorResponse = [[error userInfo] objectForKey:@"error"];
        if ([errorResponse isKindOfClass:[NSString class]]) {
            message = (NSString *)errorResponse;
        } else if ([errorResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary *errorDict = (NSDictionary *)errorResponse;
            message = [errorDict objectForKey:[[errorDict allKeys] objectAtIndex:0]];
        } else {
            message = @"An unknown error has occurred.";
        }
    }
    [self errorWithTitle:@"Unable to login to your Dropbox account" message:message];

    [emailField becomeFirstResponder];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (UITableViewCell *) newCellWithTitle:(NSString *)title textField:(UITextField *)textField {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    cell.textLabel.text = title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    cell.opaque = YES;

    UIView *cellView = [[UIView alloc] initWithFrame:CGRectMake(50, 11, 410, 24)];

    textField.frame = CGRectMake(60, 0, 380, 24);
    textField.borderStyle = UITextBorderStyleNone;
    textField.font = [UIFont fontWithName:STANDARD_FONT size:16.0];
    textField.opaque = YES;
    textField.backgroundColor = [UIColor clearColor];
    [cellView addSubview:textField];

    [cell.contentView addSubview:cellView];
    [cellView release];
    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell...
    if ([indexPath row] == 0) {
        if (!emailCell) {
            emailField = [UITextField new];
            emailField.placeholder = @"your email address";
            emailField.textColor = [UIColor colorWithRed:60.0f / 255 green:109.0f / 255 blue:181.0f / 255 alpha:1.0f];
            emailField.keyboardType = UIKeyboardTypeURL;
            emailField.returnKeyType = UIReturnKeyDone;
            emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            emailField.autocorrectionType = UITextAutocorrectionTypeNo;
            emailField.enablesReturnKeyAutomatically = YES;
            emailField.delegate = self;
            emailCell = [self newCellWithTitle:@"Email" textField:emailField];
            [emailField becomeFirstResponder];
        }
        return emailCell;
    } else if ([indexPath row] == 1) {
        if (!passwordCell) {
            passwordField = [UITextField new];
            passwordField.placeholder = @"your dropbox password";
            passwordField.textColor = [UIColor colorWithRed:60.0f / 255 green:109.0f / 255 blue:181.0f / 255 alpha:1.0f];
            passwordField.keyboardType = UIKeyboardTypeDefault;
            passwordField.returnKeyType = UIReturnKeyDone;
            passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
            passwordField.enablesReturnKeyAutomatically = YES;
            passwordField.secureTextEntry = YES;
            passwordField.delegate = self;
            passwordCell = [self newCellWithTitle:@"Password" textField:passwordField];
        }
        return passwordCell;
    } else {
        return nil; // won't reach here
    }
}

- (void) errorWithTitle:(NSString *)title message:(NSString *)message {
    [[[[UIAlertView alloc]
           initWithTitle:title message:message delegate:nil
       cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextFieldDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self didPressDone];
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox SDK
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (DBRestClient *) restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end