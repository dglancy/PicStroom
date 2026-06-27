//
//  PicStroomListFeedsViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 30/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomListFeedsViewController.h"
#import "PicStroomFeedSummary.h"
#import "PicStroomListFeedTableCell.h"
#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomInAppPurchaseAlertViewController.h"
#import "PicStroomManager.h"
#import "PicStroomViewController.h"
#import "Stroom.h"

#import "NSNotificationCenter+NSNotificationCenterAdditions.h"

@implementation PicStroomListFeedsViewController
@synthesize delegate;
@synthesize feedSummaries;
@synthesize selectedIdx;
@synthesize listFeedsTableView;
@synthesize doneBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    [listFeedsTableView release];
    [feedSummaries release];
    [selectedIdx release];
    [doneBtn release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    DebugLog(@"PicStroomListFeedsViewController dealloc()");
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(siteImageScanFinished:) name:NOTIF_SiteImageScan object:nil];

    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.listFeedsTableView.frame.size.width, 38)] autorelease];
    headerView.backgroundColor = [UIColor clearColor];
    headerView.contentMode = UIViewContentModeCenter;
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.listFeedsTableView.frame.size.width, 38)] autorelease];
    label.text = @"Select Streams to add to your overview";
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor darkTextColor];
    label.font = [UIFont fontWithName:STANDARD_FONT size:12.0];
    [headerView addSubview:label];

    self.listFeedsTableView.tableHeaderView = headerView;
    self.selectedIdx = [[[NSMutableArray alloc] init] autorelease];
}

- (void) viewDidUnload {
    self.listFeedsTableView = nil;
    self.feedSummaries = nil;
    self.selectedIdx = nil;
    [doneBtn release];
    doneBtn = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    DebugLog(@"PicStroomListFeedsViewController viewDidUnload");
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.feedSummaries count];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    PicStroomListFeedTableCell *cell = (PicStroomListFeedTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[[PicStroomListFeedTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.cellView = [[[UIView alloc] initWithFrame:CGRectMake(5, 3, listFeedsTableView.frame.size.width, 50)] autorelease];
        cell.cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.cellView.backgroundColor = [UIColor clearColor];
        cell.cellView.opaque = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 28, 28)] autorelease];
        [cell.cellView addSubview:cell.imageView];

        cell.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 3, 260, 25)] autorelease];
        cell.titleLabel.backgroundColor = [UIColor clearColor];
        cell.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:16.0];
        [cell.cellView addSubview:cell.titleLabel];

        cell.feedSummaryLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 28, 250, 15)] autorelease];
        cell.feedSummaryLabel.backgroundColor = [UIColor clearColor];
        cell.feedSummaryLabel.font = [UIFont fontWithName:STANDARD_FONT size:12.0];
        cell.feedSummaryLabel.textColor = [UIColor lightGrayColor];
        [cell.cellView addSubview:cell.feedSummaryLabel];

        [[cell contentView] addSubview:cell.cellView];
    }

    // Configure the cell...
    if ([self.feedSummaries count] >= ([indexPath row] + 1)) {
        PicStroomFeedSummary *summary = (PicStroomFeedSummary *)[self.feedSummaries objectAtIndex:[indexPath row]];

        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        Stroom *stroom = [stroomManager getStroomFromURL:[summary.url absoluteString]];
        [stroomManager release];

        if (stroom) {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_green" ofType:@"png"]];
            [selectedIdx addObject:[NSNumber numberWithUnsignedInt:[indexPath row]]];
        } else if (summary.numberOfImages <= 0) {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_delete" ofType:@"png"]];
        } else {
            if (![self isFeedChecked:[indexPath row]]) {
                cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
            } else {
                cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_plus_green" ofType:@"png"]];
            }
        }

        if (!summary.name || [summary.name length] == 0) {
            summary.name = @"Unknown";
        }
        cell.titleLabel.text = summary.name;

        NSString *feedType = nil;
        if (summary.feedType == FeedTypeRSS1) {
            feedType = @"RSS1";
        } else if (summary.feedType == FeedTypeRSS) {
            feedType = @"RSS2";
        } else if (summary.feedType == FeedTypeAtom) {
            feedType = @"Atom";
        }

        NSString *numberOfImages = nil;
        if (summary.numberOfImages == 0) {
            numberOfImages = @"No images";
        } else {
            numberOfImages = [NSString stringWithFormat:@"%d images", summary.numberOfImages];
        }

        if (feedType == nil) {
            feedType = @"Unknown Feed Format";
        }
        cell.feedSummaryLabel.text = [NSString stringWithFormat:@"%@ - %@", numberOfImages, feedType];
    }
    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isFeedChecked:[indexPath row]]) {
        [selectedIdx removeObject:[NSNumber numberWithUnsignedInt:[indexPath row]]];
    } else {
        if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
            PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
            NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
            [stroomManager release];

            if ((count + [selectedIdx count]) >= UNLIMITED_STROOMS_THRESHOLD) {
                [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
                return;
            }
        }

        PicStroomFeedSummary *summary = (PicStroomFeedSummary *)[self.feedSummaries objectAtIndex:[indexPath row]];
        if (summary.numberOfImages > 0) {
            [selectedIdx addObject:[NSNumber numberWithUnsignedInt:[indexPath row]]];
        }
    }
    [tableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Util function
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) isFeedChecked:(NSInteger)index {
    if ([selectedIdx count] == 0) {
        return NO;
    }
    return [selectedIdx containsObject:[NSNumber numberWithUnsignedInt:index]];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction) doneBtnPressed:(id)sender {
    DebugLog(@"Done button pressed");
    [delegate didPressDoneBtn:self];
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

        PicStroomInAppPurchaseAlertViewController *inAppPurchaseController = [[PicStroomInAppPurchaseAlertViewController alloc] initWithNibName:@"PicStroomInAppPurchaseAlertViewController" bundle:nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inAppPurchaseController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [inAppPurchaseController release];
        [navigationController release];
    }
}

@end
