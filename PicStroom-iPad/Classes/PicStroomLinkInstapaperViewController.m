//
//  PicStroomLinkInstapaperViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomLinkInstapaperViewController.h"
#import "PicStroomLinkInstapaperHeaderView.h"
#import "PicStroomLinkInstapaperFooterView.h"
#import "PicStroomLinkInstapaperViewController.h"
#import "PicStroomViewController.h"

#import "SFHFKeychainUtils.h"

@implementation PicStroomLinkInstapaperViewController
@synthesize instapaperLoginTableView;
@synthesize instapaperKit;
@synthesize directlyLoaded;
@synthesize loadFromSettings;
@synthesize loadFromFullScreenPhotoView;
@synthesize translucentView;
@synthesize av;

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
    self.title = @"Link Instapaper";
    
    self.instapaperKit = [[[IKEngine alloc] initWithDelegate:self] autorelease];
    
    PicStroomLinkInstapaperHeaderView *tableHeaderViewController = [[[PicStroomLinkInstapaperHeaderView alloc] initWithNibName:@"PicStroomLinkInstapaperHeaderView" bundle:nil] autorelease];
    self.instapaperLoginTableView.tableHeaderView = tableHeaderViewController.view;
    
    PicStroomLinkInstapaperFooterView *tableFooterViewController = [[[PicStroomLinkInstapaperFooterView alloc] initWithNibName:@"PicStroomLinkInstapaperFooterView" bundle:nil] autorelease];
    self.instapaperLoginTableView.tableFooterView = tableFooterViewController.view;
    
    UIBarButtonItem *doneBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    self.navigationItem.rightBarButtonItem = doneBtn;
    
    if (directlyLoaded) {
        UIBarButtonItem *cancelBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressCancel)] autorelease];
        self.navigationItem.leftBarButtonItem = cancelBtn;
    }
}

- (void)viewDidUnload {
    [self setInstapaperLoginTableView:nil];
    [super viewDidUnload];
    self.instapaperKit = nil;
}

- (BOOL) disablesAutomaticKeyboardDismissal {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [instapaperLoginTableView release];
    [instapaperKit release];
    [super dealloc];
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

- (void) errorWithTitle:(NSString *)title message:(NSString *)message {
    [[[[UIAlertView alloc]
       initWithTitle:title message:message delegate:nil
       cancelButtonTitle:@"OK" otherButtonTitles:nil]
      autorelease]
     show];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone {
    // link to instapaper
    if ([emailField.text length] == 0) {
        [self errorWithTitle:@"Username Required" message:@"Please enter your Instapaper username (it may be your email address)."];
        [emailField becomeFirstResponder];
        return;
    }
    
    self.translucentView = [[[UIView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width / 2) - 100 / 2), ((self.view.frame.size.height / 2) - 100 / 2), 100, 100)] autorelease];
    self.av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    self.av.frame = CGRectMake(((self.translucentView.frame.size.width / 2) - 36 / 2), ((self.translucentView.frame.size.height / 2) - 36 / 2), 36, 36);
    self.translucentView.backgroundColor = [UIColor blackColor];
    self.translucentView.alpha = 0.7;
    self.translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(23, 68, 80, 20)];
    label.text = @"Linking";
    label.font = [UIFont fontWithName:BOLD_FONT size:14.0f];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [self.translucentView addSubview:label];
    [label release];
    
    [self.translucentView addSubview:self.av];
    [self.view addSubview:self.translucentView];
    [self.av startAnimating];
    
    if ([passwordField.text length] == 0) {
        [instapaperKit authTokenForUsername:emailField.text password:BLANK_STRING userInfo:nil];
    } else {
        [instapaperKit authTokenForUsername:emailField.text password:passwordField.text userInfo:nil];
    }
}

- (void) didPressCancel {
    [self dismissModalViewControllerAnimated:YES];
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
            emailField.placeholder = @"your username (it may be your email address)";
            emailField.textColor = [UIColor colorWithRed:60.0f / 255 green:109.0f / 255 blue:181.0f / 255 alpha:1.0f];
            emailField.keyboardType = UIKeyboardTypeURL;
            emailField.returnKeyType = UIReturnKeyDone;
            emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            emailField.autocorrectionType = UITextAutocorrectionTypeNo;
            emailField.enablesReturnKeyAutomatically = YES;
            emailField.delegate = self;
            emailCell = [self newCellWithTitle:@"Username" textField:emailField];
            [emailField becomeFirstResponder];
        }
        return emailCell;
    } else if ([indexPath row] == 1) {
        if (!passwordCell) {
            passwordField = [UITextField new];
            passwordField.placeholder = @"your instapaper password (if you have one)";
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

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextFieldDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self didPressDone];
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - InstapaperKit delegate functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)engine:(IKEngine *)engine connection:(IKURLConnection *)connection didReceiveAuthToken:(NSString *)token andTokenSecret:(NSString *)secret {
    if (([token length] > 0) && ([secret length] > 0)) {
        [FlurryAPI logEvent:FLURRY_LINK_INSTAPAPER];
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:USER_DEFAULTS_INSTAPAPER_USER_OAUTH_TOKEN];
        
        NSError *error;
        [SFHFKeychainUtils storeUsername:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY andPassword:secret forServiceName:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY updateExisting:YES error:&error];
        
        engine.OAuthToken = token;
        engine.OAuthTokenSecret = secret;
    }
}

- (void)engine:(IKEngine *)engine didFinishConnection:(IKURLConnection *)connection {
    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;
    
    
    if (loadFromFullScreenPhotoView) {
        [self dismissModalViewControllerAnimated:YES];
        PicStroomFullScreenPhotoViewController *controller = (PicStroomFullScreenPhotoViewController *)self.navigationController.parentViewController;
        [controller instapaperBtnPressed:nil];
        return;
    }
    
    if (loadFromSettings) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }    
}
        
- (void)engine:(IKEngine *)engine didFailConnection:(IKURLConnection *)connection error:(NSError *)error {
    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;
    
    [self errorWithTitle:@"Incorrect Instapaper Account Credentials" message:@"You have not entered the correct Instapaper credentials for your account."];
}

- (void)engine:(IKEngine *)engine didCancelConnection:(IKURLConnection *)connection {
    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;
}

@end
