//
//  PicStroomSettingsViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>

#import "PicStroomSettingsViewController.h"
#import "PicStroomListStroomsViewController.h"
#import "PicStroomAboutBoxViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomUserHappinessView.h"
#import "PicStroomUserHappinessViewController.h"
#import "PicStroomInAppPurchaseViewController.h"
#import "PicStroomManager.h"
#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomAppDelegate.h"
#import "DBSession.h"
#import "PicStroomLinkServicesViewController.h"

@implementation PicStroomSettingsViewController
@synthesize delegate;
@synthesize happinessUpdated;
@synthesize settingsTableView;
@synthesize userHappiness;
@synthesize comment;
@synthesize happinessView;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [comment release];
    [settingsTableView release];
    [happinessView release];
    DebugLog(@"prefs dealloc()");
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *doneItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    self.title = @"Settings";
    self.navigationItem.rightBarButtonItem = doneItem;

    self.userHappiness = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULTS_USER_HAPPY_LEVEL];

    CGRect tableFrame = self.view.bounds;
    tableFrame.size.width = 540;
    tableFrame.origin.x = floor(self.view.bounds.size.width / 2 - tableFrame.size.width / 2);
    self.settingsTableView = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped] autorelease];
    self.settingsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.settingsTableView.backgroundColor = [UIColor clearColor];
    self.settingsTableView.scrollEnabled = NO;
    self.settingsTableView.delegate = self;
    self.settingsTableView.dataSource = self;
    [self.view addSubview:self.settingsTableView];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (BOOL) disablesAutomaticKeyboardDismissal {
    return YES;
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.settingsTableView = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
    [delegate settingsDialogDidClose:self];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [settingsTableView reloadData];
    DebugLog(@"view will appear");
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
        return 3;
    } else {
        if ([comment length] > 0) {
            return 2;
        } else {
            return 1;
        }
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 33;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 2) {
        return nil;
    } else {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"           Your Happiness Report";
        label.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
        label.backgroundColor = [UIColor clearColor];
        return [label autorelease];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 2 && [indexPath row] == 1) {
        return 75;
    }
    if ([indexPath section] == 2) {
        if ((!self.happinessView) && (happinessView.userLeftComment)) {
            return 255;
        } else if ((!self.happinessView) && (!happinessView.userLeftComment)) {
            return 165;
        } else {
            return 165;
        }
    }
    return 45;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];

    if ([indexPath section] == 0 && [indexPath row] == 0) {
        PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
        if ([mainViewController.stroomSupervisors count] == 0) {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"Edit/Order/Delete Streams";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([indexPath section] == 1 && [indexPath row] == 0) {
        cell.textLabel.text = @"Link/Unlink Services";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([indexPath section] == 1 && [indexPath row] == 1) {
        // check in-app purchase status
        if ([PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms] ) {
            cell.textLabel.text = @"You are licensed for unlimited Streams";
            cell.textLabel.textColor = [UIColor lightGrayColor];
        } else {
            cell.textLabel.text = @"Buy Unlimited Streams";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (appDelegate.currentNetworkStatus == NotReachable) {
                cell.textLabel.textColor = [UIColor lightGrayColor];
            }
        }
    } else if ([indexPath section] == 1 && [indexPath row] == 2) {
        // check in-app purchase status
        cell.textLabel.text = @"About PicStroom";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([indexPath section] == 2 && [indexPath row] == 0) {
        // control uiview goes here
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (!self.happinessView) {
            self.happinessView = [[[PicStroomUserHappinessView alloc] initWithFrame:CGRectMake(0, 0, 465, 260)] autorelease];
            [self.happinessView.btn1 addTarget:self action:@selector(weatherIconOneWasPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.happinessView.btn2 addTarget:self action:@selector(weatherIconTwoWasPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.happinessView.btn3 addTarget:self action:@selector(weatherIconThreeWasPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self.happinessView.btn4 addTarget:self action:@selector(weatherIconFourWasPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:self.happinessView];
        }

        if (self.userHappiness == UserHappyOutstanding) {
            self.happinessView.btn1.selected = YES;
            self.happinessView.btn2.selected = NO;
            self.happinessView.btn3.selected = NO;
            self.happinessView.btn4.selected = NO;
        } else if (self.userHappiness == UserHappyILikeIt) {
            self.happinessView.btn2.selected = YES;
            self.happinessView.btn1.selected = NO;
            self.happinessView.btn3.selected = NO;
            self.happinessView.btn4.selected = NO;
        } else if (self.userHappiness == UserHappyCanBeBetter) {
            self.happinessView.btn3.selected = YES;
            self.happinessView.btn1.selected = NO;
            self.happinessView.btn2.selected = NO;
            self.happinessView.btn4.selected = NO;
        } else if (self.userHappiness == UserHappyIWontReturn) {
            self.happinessView.btn4.selected = YES;
            self.happinessView.btn1.selected = NO;
            self.happinessView.btn2.selected = NO;
            self.happinessView.btn3.selected = NO;
        }
    } else if ([indexPath section] == 2 && [indexPath row] == 1) {
        UIView *commentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 465, 70)];
        UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 450, 15)];
        headingLabel.font = [UIFont fontWithName:BOLD_FONT size:14.0];
        headingLabel.textColor = [UIColor darkGrayColor];
        headingLabel.backgroundColor = [UIColor clearColor];
        headingLabel.text = @"What you said...";
        [commentView addSubview:headingLabel];
        [headingLabel release];

        UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 450, 65)];
        commentLabel.font = [UIFont fontWithName:STANDARD_FONT size:14.0];
        commentLabel.textColor = [UIColor lightGrayColor];
        commentLabel.backgroundColor = [UIColor clearColor];
        commentLabel.text = comment;
        [commentView addSubview:commentLabel];
        [commentLabel release];

        [[cell contentView] addSubview:commentView];
        [commentView release];
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
        PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
        if ([mainViewController.stroomSupervisors count] == 0) {
            return;
        }
        PicStroomListStroomsViewController *listStroomsController = [[PicStroomListStroomsViewController alloc] initWithNibName:@"PicStroomListStroomsViewController" bundle:nil];
        listStroomsController.mainViewController = mainViewController;
        [self.navigationController pushViewController:listStroomsController animated:YES];
        [listStroomsController release];
    } else if (([indexPath section] == 1) && ([indexPath row] == 0)) {
        // link/unlink services
        PicStroomLinkServicesViewController *linkServicesViewController = [[PicStroomLinkServicesViewController alloc] initWithNibName:@"PicStroomLinkServicesViewController" bundle:nil];
        [self.navigationController pushViewController:linkServicesViewController animated:YES];
        [linkServicesViewController release];
    } else if (([indexPath section] == 1) && ([indexPath row] == 1)) {
        // in-app
        if ([PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms] ) {
            return;
        } else if (![PicStroomInAppPurchaseManager canMakePurchases]) {
            [[[[UIAlertView alloc] initWithTitle:@"In-App Purchases Disabled" message:@"You have disabled In-App purchases on this device. To purchase unlimited Streams you need to re-enable In-App purchases in your settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
            return;
        }
        PicStroomInAppPurchaseViewController *inAppPurchaseViewController = [[PicStroomInAppPurchaseViewController alloc] initWithNibName:@"PicStroomInAppPurchaseViewController" bundle:nil];
        [self.navigationController pushViewController:inAppPurchaseViewController animated:YES];
        [inAppPurchaseViewController release];

    } else if (([indexPath section] == 1) && ([indexPath row] == 2)) {
        // about box
        PicStroomAboutBoxViewController *aboutBoxViewController = [[PicStroomAboutBoxViewController alloc] initWithNibName:@"PicStroomAboutBoxViewController" bundle:nil];
        [self.navigationController pushViewController:aboutBoxViewController animated:YES];
        [aboutBoxViewController release];
    }

}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone {
    if (userHappiness != [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULTS_USER_HAPPY_LEVEL]) {
        [[NSUserDefaults standardUserDefaults] setInteger:userHappiness forKey:USER_DEFAULTS_USER_HAPPY_LEVEL];
    }

    // if comment made the set it in dictonary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", userHappiness], @"LVL", [comment length] > 0 ? comment:@"None", @"USER_COMMENTS", nil];

    if (self.happinessUpdated) {
        DebugLog(@"Happiness updated!");
        [FlurryAPI logEvent:FLURRY_HAPPY_LEVEL withParameters:dictionary];
    }

    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void) weatherIconOneWasPressed:(id)sender {
    self.happinessUpdated = YES;
    userHappiness = UserHappyOutstanding;
    PicStroomUserHappinessViewController *userHappinessViewController = [[PicStroomUserHappinessViewController alloc] initWithNibName:@"PicStroomUserHappinessViewController" bundle:nil];
    userHappinessViewController.settingsController = self;
    userHappinessViewController.userHappiness = userHappiness;
    [self.navigationController pushViewController:userHappinessViewController animated:YES];
    [userHappinessViewController release];
}

- (void) weatherIconTwoWasPressed:(id)sender {
    self.happinessUpdated = YES;
    userHappiness = UserHappyILikeIt;
    PicStroomUserHappinessViewController *userHappinessViewController = [[PicStroomUserHappinessViewController alloc] initWithNibName:@"PicStroomUserHappinessViewController" bundle:nil];
    userHappinessViewController.settingsController = self;
    userHappinessViewController.userHappiness = userHappiness;
    [self.navigationController pushViewController:userHappinessViewController animated:YES];
    [userHappinessViewController release];
}

- (void) weatherIconThreeWasPressed:(id)sender {
    self.happinessUpdated = YES;
    userHappiness = UserHappyCanBeBetter;
    PicStroomUserHappinessViewController *userHappinessViewController = [[PicStroomUserHappinessViewController alloc] initWithNibName:@"PicStroomUserHappinessViewController" bundle:nil];
    userHappinessViewController.settingsController = self;
    userHappinessViewController.userHappiness = userHappiness;
    [self.navigationController pushViewController:userHappinessViewController animated:YES];
    [userHappinessViewController release];
}

- (void) weatherIconFourWasPressed:(id)sender {
    self.happinessUpdated = YES;
    userHappiness = UserHappyIWontReturn;
    PicStroomUserHappinessViewController *userHappinessViewController = [[PicStroomUserHappinessViewController alloc] initWithNibName:@"PicStroomUserHappinessViewController" bundle:nil];
    userHappinessViewController.settingsController = self;
    userHappinessViewController.userHappiness = userHappiness;
    [self.navigationController pushViewController:userHappinessViewController animated:YES];
    [userHappinessViewController release];
}

@end
