//
//  PicStroomGalleryController.m
//  PicStroom
//
//  Created by Damien Glancy on 31/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomGalleryController.h"
#import "PicStroomViewController.h"
#import "PicStroomAddStroomManager.h"
#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomInAppPurchaseAlertViewController.h"
#import "PicStroomSupervisor.h"
#import "PicStroomManager.h"
#import "Stroom.h"

#import "NSOperationQueue+CWSharedQueue.h"

@implementation PicStroomGalleryController
@synthesize delegate;
@synthesize galleryTableView;
@synthesize gallery;
@synthesize translucentView;
@synthesize av;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [galleryTableView release];
    [selectedRows release];
    [gallery release];
    [greyedOutRows release];
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isCancelled"]) {
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Gallery";

    selectedRows = [[NSMutableArray alloc] init];
    greyedOutRows = [[NSMutableArray alloc] init];
    self.gallery = [[[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:GALLERY_URL]] autorelease];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didPressDone)] autorelease];

    if (self.delegate) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressClose)] autorelease];
    }

    mainViewController = [PicStroomViewController getCurrentController];
    [FlurryAPI logEvent:FLURRY_BROWSE_GALLERY];
}

- (void) viewDidUnload {
    self.galleryTableView = nil;
    self.gallery = nil;
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // [self performSelectorInBackgroundQueue:@selector(addGalleryStroomsInBackground) withObject:nil withQueuePriority:NSOperationQueuePriorityLow];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressClose {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) didPressDone {
    if ([selectedRows count] > 0) {
        self.galleryTableView.userInteractionEnabled = NO;
        self.translucentView = [[[UIView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width / 2) - 100 / 2), ((self.view.frame.size.height / 2) - 100 / 2), 100, 100)] autorelease];
        self.av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
        self.av.frame = CGRectMake(((self.translucentView.frame.size.width / 2) - 36 / 2), (((self.translucentView.frame.size.height / 2) - 36 / 2)-10), 36, 36);
        self.translucentView.backgroundColor = [UIColor blackColor];
        self.translucentView.alpha = 0.7;
        self.translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;
        [self.translucentView addSubview:self.av];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(23, 68, 80, 20)];
        label.text = @"Adding";
        label.font = [UIFont fontWithName:BOLD_FONT size:14.0f];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [self.translucentView addSubview:label];
        [label release];
        
        [self.view addSubview:self.translucentView];
        [self.av startAnimating];
    }
    [self performSelector:@selector(addGalleryStrooms) withObject:nil afterDelay:0.5];
}

- (void) addGalleryStrooms {
    DebugLog(@"Add Gallery Strooms called in queue");
    NSMutableArray *stroomSupervisors = [[[NSMutableArray alloc] initWithCapacity:[selectedRows count]] autorelease];
    for (int i = 0; i < [selectedRows count]; i++) {
        NSString *targetString = [selectedRows objectAtIndex:i];
        NSRange delimIdx = [targetString rangeOfString:@"-"];

        NSInteger section = [[targetString substringToIndex:delimIdx.location] intValue];
        NSInteger row = [[targetString substringFromIndex:delimIdx.location + 1] intValue];

        NSDictionary *category = [gallery objectForKey:[NSString stringWithFormat:@"%d", section + 1]];
        NSDictionary *site = [category objectForKey:[NSString stringWithFormat:@"%d", row + 1]];

        PicStroomAddStroomManager *addStroomManager = [[PicStroomAddStroomManager alloc] init];
        Stroom *stroom = [addStroomManager addStroomRSS:[NSURL URLWithString:[site objectForKey:@"url"]]];
        [addStroomManager release];

        PicStroomSupervisor *stroomSupervisor = [[PicStroomSupervisor alloc] init];
        stroomSupervisor.stroom = stroom;
        stroom.stroomSupervisor = stroomSupervisor;
        [mainViewController.stroomSupervisors addObject:stroomSupervisor];

        [self updateStroomTable];
        [stroomSupervisors addObject:stroomSupervisor];
        [stroomSupervisor release];
        [FlurryAPI logEvent:FLURRY_ADD_GALLERY_WEB_STROOM];
    }

    [self performSelector:@selector(scheduleSyncOfNewStrooms:) withObject:stroomSupervisors afterDelay:2.0];

    if ([selectedRows count] > 0) {
        self.galleryTableView.userInteractionEnabled = YES;
        [self.av stopAnimating];
        [self.translucentView removeFromSuperview];
        self.translucentView = nil;
        self.av = nil;
    }

    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
    if (delegate) {
        [delegate didPressGalleryDoneBtn:self];
    }
}

- (void) updateStroomTable {
    DebugLog(@"Update Stroom Table");
    [mainViewController.stroomTableView beginUpdates];
    [mainViewController.stroomTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[mainViewController.stroomSupervisors count] - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
    if ([mainViewController.stroomSupervisors count] <= TARGET_NUM_OF_STROOMS_ON_SCREEN) {
        [mainViewController.stroomTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:TARGET_NUM_OF_STROOMS_ON_SCREEN - ([mainViewController.stroomSupervisors count]) inSection:3]] withRowAnimation:UITableViewRowAnimationTop];
    }
    [mainViewController.stroomTableView endUpdates];
}

- (void) scheduleSyncOfNewStrooms:(NSArray *)newStroomSupervisors {
    for (PicStroomSupervisor *s in newStroomSupervisors) {
        [s startSyncInBackgroundQueue];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.gallery count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *category = [gallery objectForKey:[NSString stringWithFormat:@"%d", section + 1]];

    return (NSString *)[category objectForKey:@"category"];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *category = [gallery objectForKey:[NSString stringWithFormat:@"%d", section + 1]];
    NSInteger count = [category count];

    if (count > 1) {
        return count - 1;
    } else if (count == 0) {
        return 1;
    } else {
        return 0;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }

    NSDictionary *category = [gallery objectForKey:[NSString stringWithFormat:@"%d", [indexPath section] + 1]];
    NSDictionary *site = [category objectForKey:[NSString stringWithFormat:@"%d", [indexPath row] + 1]];
    cell.textLabel.text = [site objectForKey:@"name"];
    cell.detailTextLabel.text = [site objectForKey:@"description"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSString *selectionIdx = [NSString stringWithFormat:@"%d-%d", [indexPath section], [indexPath row]];

    // check to see if the stroom is already added in by the user
    if ([greyedOutRows containsObject:selectionIdx]) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_grey" ofType:@"png"]];
        return cell;
    }

    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
    Stroom *stroom = [stroomManager getStroomFromURL:[site objectForKey:@"url"]];
    [stroomManager release];

    if (stroom != nil) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_grey" ofType:@"png"]];
        [greyedOutRows addObject:selectionIdx];
    } else {
        if ([selectedRows containsObject:selectionIdx]) {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_plus_green" ofType:@"png"]];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.textColor = [UIColor blackColor];
        } else {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
    }
    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectionIdx = [NSString stringWithFormat:@"%d-%d", [indexPath section], [indexPath row]];

    if ([greyedOutRows containsObject:selectionIdx]) {
        DebugLog(@"Not adding gallery as same stroom is already added");
        return;
    }

    if (![selectedRows containsObject:selectionIdx]) {
        if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
            PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
            NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
            [stroomManager release];

            if ((count + [selectedRows count]) >= UNLIMITED_STROOMS_THRESHOLD) {
                [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
                return;
            }
        }

        if ([selectedRows count] >= LIMIT_NUM_OF_STROOMS_ADDED_FROM_GALLERY_AT_ONCE) {
            [[[[UIAlertView alloc] initWithTitle:@"About adding Unlimited Streams" message:@"Gallery Streams can be added 7 at a time. Of course, you can add another 7 when you added these 7!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
            return;
        }

        [selectedRows addObject:selectionIdx];
    } else {
        [selectedRows removeObject:selectionIdx];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Read more alert box button handler
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (![PicStroomInAppPurchaseManager canMakePurchases]) {
            [[[[UIAlertView alloc] initWithTitle:@"In-App Purchases Disabled" message:@"You have disabled In-App purchases on this device. To purchase unlimited Streams you need to re-enable In-App purchases in your settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
            return;
        }

        PicStroomInAppPurchaseAlertViewController *inAppViewController = [[PicStroomInAppPurchaseAlertViewController alloc] initWithNibName:@"PicStroomInAppPurchaseAlertViewController" bundle:nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inAppViewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [inAppViewController release];
        [navigationController release];
    }
}

@end