//
//  PicStroomViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 01/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#import "PicStroomAppDelegate.h"
#import "PicStroomViewController.h"
#import "PicStroomThumbnailButton.h"
#import "PicStroomSupervisor.h"
#import "PicStroomSettingsViewController.h"
#import "PicStroomManager.h"
#import "PicStroomAddStroomManager.h"
#import "PicStroomSyncStroomManager.h"
#import "PicStroomWebStroomLinkView.h"
#import "PicStroomDropboxStroomLinkView.h"
#import "PicStroomUnlimitedLinkView.h"
#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomAddDropboxStroomViewController.h"
#import "PicStroomInAppPurchaseViewController.h"
#import "PicStroomImageProcessor.h"
#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomInAppPurchaseAlertViewController.h"
#import "PicStroomEmbeddedBrowserViewController.h"
#import "PicStroomOrderStroomManager.h"
#import "PicStroomStatusLabel.h"
#import "PicStroomMetadataManager.h"

#import "Stroom.h"

#import "NSOperationQueue+CWSharedQueue.h"
#import "DBSession.h"
#import "Reachability.h"

#import "PicStroomUINavigationController.h"

static PicStroomViewController *controller;

@implementation PicStroomViewController
@synthesize firstAppLoad;
@synthesize controlBarView;
@synthesize stroomTableView;
@synthesize addStroomBtn;
@synthesize preferencesBtn;
@synthesize syncBtn;
@synthesize prefsViewController;
@synthesize webStroomLinkView;
@synthesize dropboxStroomLinkView;
@synthesize unlimitedLinkView;
@synthesize stroomSupervisors;
@synthesize starredStroomSupervisor;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static reference
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomViewController *) getCurrentController {
    return controller;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];

    [controlBarView release];
    [stroomTableView release];
    [addStroomBtn release];
    [preferencesBtn release];
    [syncBtn release];
    [prefsViewController release];
    [webStroomLinkView release];
    [dropboxStroomLinkView release];
    [unlimitedLinkView release];
    [stroomSupervisors release];
    [starredStroomSupervisor release];

    [super dealloc];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    controller = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseSuccess:) name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];

    self.starredStroomSupervisor = [[[PicStroomSupervisor alloc] init] autorelease];
    self.starredStroomSupervisor.stroom = [PicStroomManager getStarredStroom];

    if (self.firstAppLoad) {
        NSDictionary *initialStrooms = [[NSDictionary alloc] initWithContentsOfURL:[NSURL URLWithString:INITIAL_STROOMS_URL]];
        if ([initialStrooms count] > 0) {
            [FlurryAPI logEvent:FLURRY_ADDING_SYSTEM_STROOMS];
            DebugLog(@"First time application is run: Adding %d system strooms.", [initialStrooms count]);
            for (int i = 1; i <= [initialStrooms count]; i++) {
                NSDictionary *initialStroom = [initialStrooms objectForKey:[NSString stringWithFormat:@"%d", i]];
                PicStroomAddStroomManager *addStroomManager = [[PicStroomAddStroomManager alloc] init];
                [addStroomManager addSystemStroomRSS:[NSURL URLWithString:[initialStroom objectForKey:@"url"]]];
                [addStroomManager release];
            }
        }
        [initialStrooms release];
    }

    NSUInteger pictureCount = 0;

    if (!self.stroomSupervisors) {
        self.stroomSupervisors = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        NSArray *strooms = [stroomManager getAllStrooms];

        NSInteger countForOrder = 1;
        for (Stroom *stroom in strooms) {

            if(stroom.order == nil || stroom.order == 0) {
                // migration
                PicStroomOrderStroomManager *updateManager = [[PicStroomOrderStroomManager alloc] init];
                [updateManager updateOrder:countForOrder onStroom:stroom];
                [updateManager release];
            }
            
            countForOrder++;
            
            PicStroomSupervisor *stroomSupervisor = [[PicStroomSupervisor alloc] init];
            stroomSupervisor.stroom = stroom;
            stroom.stroomSupervisor = stroomSupervisor;

            NSDateFormatter *dayFormat = [[[NSDateFormatter alloc] init] autorelease];
            [dayFormat setDateFormat:@"dd"];
            NSDateFormatter *monthFormat = [[[NSDateFormatter alloc] init] autorelease];
            [monthFormat setDateFormat:@"MMM"];
            NSDateFormatter *yearFormat = [[[NSDateFormatter alloc] init] autorelease];
            [yearFormat setDateFormat:@"YYYY"];

            NSArray *pictures = [stroomManager getAllPicturesForStroom:[stroom objectID]];
            for (Picture *picture in pictures) {
                [stroomSupervisor.currentThumbnailUUIDs addObject:picture.thumbnailUUID];
                [stroomSupervisor.currentRawPictureUUIDs addObject:picture.rawPictureUUID];
                [stroomSupervisor.currentThumbnailWidths addObject:picture.thumbWidth];

                if (picture.date) {
                    NSString *potentialUniqueDate = [NSString stringWithFormat:@"%@$%@$%@", [[dayFormat stringFromDate:picture.date] lowercaseString], [[monthFormat stringFromDate:picture.date] lowercaseString], [[yearFormat stringFromDate:picture.date] lowercaseString]];
                    if (![stroomSupervisor.uniqueDateRegister containsObject:potentialUniqueDate]) {
                        [stroomSupervisor.dateMarkerUUIDs addObject:picture.thumbnailUUID];
                        [stroomSupervisor.uniqueDateRegister addObject:potentialUniqueDate];
                    }
                }

                stroomSupervisor.currentEntireThumbnaiLength += [picture.thumbWidth intValue];
                pictureCount++;
            }
        
            if (firstAppLoad) {
                stroomSupervisor.currentState = StroomStateNew;
            } else {
                stroomSupervisor.currentState = StroomStateUptodate;
            }
            [self.stroomSupervisors addObject:stroomSupervisor];
            [stroomSupervisor release];
        }
        [stroomManager release];
    }

    self.firstAppLoad = NO;

    NSDictionary *dictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", pictureCount], @"NUM_OF_PIX_ON_STARTUP", nil];
    [FlurryAPI logEvent:FLURRY_STATS_NUMBER_OF_PICS_ON_STARTUP withParameters:dictionary1];

    NSDictionary *dictionary2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [self.stroomSupervisors count]], @"NUM_OF_STREAMS_ON_STARTUP", nil];
    [FlurryAPI logEvent:FLURRY_STATS_NUMBER_OF_STREAMS_ON_STARTUP withParameters:dictionary2];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreDataChanged:) name:NSManagedObjectContextDidSaveNotification object:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]];

    // Assume POTRAIT starting orientation
    self.controlBarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"banner-portrait-no-buttons" ofType:@"png"]]];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration       {
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.controlBarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"banner-portrait-no-buttons" ofType:@"png"]]];
    } else {
        self.controlBarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"banner-landscape-no-buttons" ofType:@"png"]]];
    }

    // tell any supervisors about rotation
    [self.starredStroomSupervisor refreshDisplay:CGRectMake(0, 1, stroomTableView.frame.size.width, 120)];
    for (PicStroomSupervisor *stroomSupervisor in stroomSupervisors) {
        [stroomSupervisor refreshDisplay:CGRectMake(0, 1, stroomTableView.frame.size.width, 120)];
    }
    [stroomTableView reloadData];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];

    controller = nil;
    [controlBarView release], controlBarView = nil;
    [stroomTableView release], stroomTableView = nil;
    [addStroomBtn release], addStroomBtn = nil;
    [preferencesBtn release], preferencesBtn = nil;
    [syncBtn release], syncBtn = nil;
    [prefsViewController release], prefsViewController = nil;
    [webStroomLinkView release], webStroomLinkView = nil;
    [dropboxStroomLinkView release], dropboxStroomLinkView = nil;
    [unlimitedLinkView release], unlimitedLinkView = nil;
    [stroomSupervisors release], stroomSupervisors = nil;
    [starredStroomSupervisor release], starredStroomSupervisor = nil;
    DebugLog(@"PicStroom Strooms View Controller did unload");
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [stroomTableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stroom Table lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if([PicStroomMetadataManager isThereAnyStarredPictures]) {
            return 1;
        } else {
            return 0;
        }
    } else if (section == 1) {
        return [stroomSupervisors count];
    } else if (section == 2) {
        return 1;
    } else {
        return [self calculateSpareStroomCells];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *starsCellIdentifier = @"StarsCell";
    static NSString *stroomCellIdentifier = @"StroomCell";
    static NSString *spacerStroomCellIdentifier = @"SpacerButtonCell";
    static NSString *buttonStroomCellIdentifier = @"ButtonStroomCell";

    UITableViewCell *cell = nil;
    
    if ([indexPath section] == 0) {
        //starred stroom
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:starsCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:starsCellIdentifier] autorelease];
            cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            cell.opaque = YES;
            cell.backgroundColor = [UIColor colorWithRed:64.0f / 255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0f];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        self.starredStroomSupervisor.frame = CGRectMake(0, 1, tableView.frame.size.width, 120);
        [self.starredStroomSupervisor getLatestPictures];
        self.starredStroomSupervisor.currentState = StroomStateUptodate;
        [[cell contentView] addSubview:self.starredStroomSupervisor.view];
    } else if ([indexPath section] == 1) {
        // picture stroom
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:stroomCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:stroomCellIdentifier] autorelease];
            cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            cell.opaque = YES;
            cell.backgroundColor = [UIColor colorWithRed:64.0f / 255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0f];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        PicStroomSupervisor *stroomSupervisor = [stroomSupervisors objectAtIndex:[indexPath row]];
        stroomSupervisor.frame = CGRectMake(0, 1, tableView.frame.size.width, 120);
        if (stroomSupervisor.currentState == StroomStateUpdatesAvailable) {
            DebugLog(@"updates available");
            [stroomSupervisor getLatestPictures];
        }
        [[cell contentView] addSubview:stroomSupervisor.view];
    } else if ([indexPath section] == 2) {
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:buttonStroomCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonStroomCellIdentifier] autorelease];
            cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            cell.opaque = YES;
            cell.backgroundColor = [UIColor colorWithRed:64.0f / 255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0f];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 120)];
            buttonView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            buttonView.backgroundColor = [UIColor colorWithRed:45.0f / 255.0f green:44.0f / 255.0f blue:44.0f / 255.0f alpha:1.0f];

            self.webStroomLinkView = [[[PicStroomWebStroomLinkView alloc] initWithFrame:CGRectMake(10, 10, 145, 50)] autorelease];
            self.webStroomLinkView.backgroundColor = [UIColor clearColor];
            UITapGestureRecognizer *tapRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addWebStroomDirectBtnPressed:)];
            [tapRecognizer1 setNumberOfTapsRequired:1];
            [self.webStroomLinkView addGestureRecognizer:tapRecognizer1];
            [tapRecognizer1 release];
            [buttonView addSubview:self.webStroomLinkView];

            self.dropboxStroomLinkView = [[[PicStroomDropboxStroomLinkView alloc] initWithFrame:CGRectMake(170, 10, 145, 50)] autorelease];
            UITapGestureRecognizer *tapRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addDropboxStroomDirectBtnPressed:)];
            [tapRecognizer2 setNumberOfTapsRequired:1];
            [self.dropboxStroomLinkView addGestureRecognizer:tapRecognizer2];
            [buttonView addSubview:self.dropboxStroomLinkView];
            [tapRecognizer2 release];

            self.unlimitedLinkView = [[[PicStroomUnlimitedLinkView alloc] initWithFrame:CGRectMake(360, 10, 145, 50)] autorelease];
            UITapGestureRecognizer *tapRecognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(getUnlimitedDirectBtnPressed:)];
            [tapRecognizer3 setNumberOfTapsRequired:1];
            [self.unlimitedLinkView addGestureRecognizer:tapRecognizer3];
            [tapRecognizer3 release];

            if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
                [buttonView addSubview:self.unlimitedLinkView];
            }

            [[cell contentView] addSubview:buttonView];
            [buttonView release];
        }
    } else {
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:spacerStroomCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:spacerStroomCellIdentifier] autorelease];
            cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            cell.opaque = YES;
            cell.backgroundColor = [UIColor colorWithRed:64.0f / 255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0f];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 120)];
            spacerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            spacerView.backgroundColor = [UIColor colorWithRed:45.0f / 255.0f green:44.0f / 255.0f blue:44.0f / 255.0f alpha:1.0f];
            [[cell contentView] addSubview:spacerView];
            [spacerView release];
        }
    }

    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 1=read more
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

- (void) launchFullScreenPhotoView:(id)sender {
    PicStroomFullScreenPhotoViewController *fullscreenPhotoViewController = [[PicStroomFullScreenPhotoViewController alloc] initWithNibName:@"PicStroomFullScreenPhotoViewController" bundle:nil];
    PicStroomThumbnailButton *thumbnailBtn = (PicStroomThumbnailButton *)sender;

    PicStroomStatusLabel *statusLabel = thumbnailBtn.stroomSupervisor.statusLabel;
   if (statusLabel != nil && [statusLabel isSet]) {
        [statusLabel clearStatus];
    }

    fullscreenPhotoViewController.currentRawPictureUUIDs = thumbnailBtn.stroomSupervisor.currentRawPictureUUIDs;
    fullscreenPhotoViewController.startIdx = thumbnailBtn.index;
    fullscreenPhotoViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:fullscreenPhotoViewController animated:NO];

    [fullscreenPhotoViewController release];
}

- (IBAction) addWebStroomDirectBtnPressed:(id)sender {
    [self highlightWebStroomDirectBtn];

    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        [[[[UIAlertView alloc] initWithTitle:@"No Network available" message:@"You need an active network connection to be able to add up a Stroom." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    }

    if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
        [stroomManager release];

        if (count >= UNLIMITED_STROOMS_THRESHOLD) {
            [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
            return;
        }
    }

    PicStroomEmbeddedBrowserViewController *browserController = [[PicStroomEmbeddedBrowserViewController alloc] initWithNibName:@"PicStroomEmbeddedBrowserViewController" bundle:nil];
    browserController.url = nil;
    browserController.toolbarPosition = ToolbarBottom;
    browserController.delegate = self;
    browserController.basicModeEnabled = YES;
    browserController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:browserController animated:YES];
    [browserController release];
}

- (IBAction) addDropboxStroomDirectBtnPressed:(id)sender {
    [self highlightDropboxStroomDirectBtn];

    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        [[[[UIAlertView alloc] initWithTitle:@"No Network available" message:@"You need an active network connection to be able to add up a Stroom." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    }

    if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
        [stroomManager release];

        if (count >= UNLIMITED_STROOMS_THRESHOLD) {
            [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
            return;
        }
    }

    if ([[DBSession sharedSession] isLinked]) {
        PicStroomAddDropboxStroomViewController *addDropboxStroomViewController = [[PicStroomAddDropboxStroomViewController alloc] initWithNibName:@"PicStroomAddDropboxStroomViewController" bundle:nil];
        addDropboxStroomViewController.directlyLoaded = YES;
        PicStroomUINavigationController *navigationController = [[PicStroomUINavigationController alloc] initWithRootViewController:addDropboxStroomViewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [addDropboxStroomViewController release];
        [navigationController release];
    } else {
        PicStroomLinkDropboxViewController *linkDropboxViewController = [[PicStroomLinkDropboxViewController alloc] initWithNibName:@"PicStroomLinkDropboxViewController" bundle:nil];
        linkDropboxViewController.directlyLoaded = YES;
        PicStroomUINavigationController *navigationController = [[PicStroomUINavigationController alloc] initWithRootViewController:linkDropboxViewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [linkDropboxViewController release];
        [navigationController release];
    }
}

- (IBAction) getUnlimitedDirectBtnPressed:(id)sender {
    [self highlightUnlimitedStroomDirectBtn];

    if (![PicStroomInAppPurchaseManager canMakePurchases]) {
        [[[[UIAlertView alloc] initWithTitle:@"In-App Purchases Disabled" message:@"You have disabled In-App purchases on this device. To purchase unlimited Streams you need to re-enable In-App purchases in your settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    }

    PicStroomInAppPurchaseViewController *inAppPurchaseController = [[PicStroomInAppPurchaseViewController alloc] initWithNibName:@"PicStroomInAppPurchaseViewController" bundle:nil];
    inAppPurchaseController.directlyLoaded = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inAppPurchaseController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
    [inAppPurchaseController release];
    [navigationController release];
}

- (IBAction) addBtnPressed:(id)sender {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        [[[[UIAlertView alloc] initWithTitle:@"No Network available" message:@"You need an active network connection to be able to add up a Stream." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    }

    if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
        [stroomManager release];

        if (count >= UNLIMITED_STROOMS_THRESHOLD) {
            [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
            return;
        }
    }

    PicStroomAddStroomsViewController *addStroomsController = [[PicStroomAddStroomsViewController alloc] initWithNibName:@"PicStroomAddStroomsViewController" bundle:nil];
    addStroomsController.delegate = self;
    PicStroomUINavigationController *navigationController = [[PicStroomUINavigationController alloc] initWithRootViewController:addStroomsController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
    [addStroomsController release];
    [navigationController release];
}

- (IBAction) preferencesBtnPressed:(id)sender {
    PicStroomSettingsViewController *settingsController = [[PicStroomSettingsViewController alloc] init];
    settingsController.delegate = self;
    PicStroomUINavigationController *navigationController = [[PicStroomUINavigationController alloc] initWithRootViewController:settingsController];

    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
    [settingsController release];
    [navigationController release];
}

- (IBAction) syncBtnPressed:(id)sender {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"No network available, therefore user sync request is cancelled.");
        [[[[UIAlertView alloc] initWithTitle:@"No network available" message:@"It's not possible to sync your Streams at the moment because there is no network available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
    } else {
        NSNumber *bytesAvailable = [[PicStroomImageProcessor currentProcessor] calculateAvailableDiskSpace];
        if ([bytesAvailable floatValue] < MIN_FREE_DISK_STORAGE_IN_BYTES) {
            [FlurryAPI logEvent:FLURRY_NO_DISK_STORAGE_WARNING_SHOWN];
            [[[[UIAlertView alloc] initWithTitle:@"No space available" message:@"It's not possible to sync your Streams at the moment because your iPad does not have enough free storage space." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        } else {
            DebugLog(@"User sync request started.");
            for (PicStroomSupervisor *stroomSupervisor in stroomSupervisors) {
                [stroomSupervisor startSyncInBackgroundQueue];
            }
        }
    }
}

- (void) highlightWebStroomDirectBtn {
    self.webStroomLinkView.lbl1.textColor = [UIColor whiteColor];
    self.webStroomLinkView.lbl2.textColor = [UIColor whiteColor];
    self.webStroomLinkView.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_stroom" ofType:@"png"]];
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(unhighlightWebStroomDirectBtn) userInfo:nil repeats:NO];
}

- (void) unhighlightWebStroomDirectBtn {
    self.webStroomLinkView.lbl1.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
    self.webStroomLinkView.lbl2.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
    self.webStroomLinkView.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_stroom_50p" ofType:@"png"]];
}

- (void) highlightDropboxStroomDirectBtn {
    self.dropboxStroomLinkView.lbl1.textColor = [UIColor whiteColor];
    self.dropboxStroomLinkView.lbl2.textColor = [UIColor whiteColor];
    self.dropboxStroomLinkView.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_dropbox" ofType:@"png"]];
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(unhighlightDropboxStroomDirectBtn) userInfo:nil repeats:NO];
}

- (void) unhighlightDropboxStroomDirectBtn {
    self.dropboxStroomLinkView.lbl1.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
    self.dropboxStroomLinkView.lbl2.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
    self.dropboxStroomLinkView.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_dropbox_50p" ofType:@"png"]];
}

- (void) highlightUnlimitedStroomDirectBtn {
    self.unlimitedLinkView.lbl1.textColor = [UIColor whiteColor];
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(unhighlightUnlimitedStroomDirectBtn) userInfo:nil repeats:NO];
}

- (void) unhighlightUnlimitedStroomDirectBtn {
    self.unlimitedLinkView.lbl1.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomSettingsViewController delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) settingsDialogDidClose:(PicStroomSettingsViewController *)sender {
    DebugLog(@"Settings dialog closed");
    [self.stroomTableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomAddStroomsViewController delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didMakeRequestToLaunchBrowser:(PicStroomAddStroomsViewController *)controller {
    [self dismissModalViewControllerAnimated:NO];
    PicStroomEmbeddedBrowserViewController *browserController = [[PicStroomEmbeddedBrowserViewController alloc] initWithNibName:@"PicStroomEmbeddedBrowserViewController" bundle:nil];
    browserController.url = nil;
    browserController.toolbarPosition = ToolbarBottom;
    browserController.delegate = self;
    browserController.basicModeEnabled = YES;
    browserController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:browserController animated:YES];
    [browserController release];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync & Store (Core Data)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) coreDataChanged:(NSNotification *)notif {
    NSSet *deletedObjects = [[notif userInfo] objectForKey:NSDeletedObjectsKey];

    if ([deletedObjects count] > 0) {
        UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        for (NSManagedObject *mo in deletedObjects) {
            if ([mo isKindOfClass:[Picture class]]) {
                Picture *picture = (Picture *)mo;
                if ([picture.entry.stroom.type intValue] != StroomTypeStarred) {
                  [[PicStroomImageProcessor currentProcessor] deleteImageFromDisk:picture.rawPictureUUID];
                  [[PicStroomImageProcessor currentProcessor] deleteThumbnailFromDisk:picture.thumbnailUUID];
                }
            }
        }
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *)notice {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];

    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"Network status: No network");
        [self.syncBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"progress-2" ofType:@"png"]] forState:UIControlStateNormal];
    } else if (appDelegate.currentNetworkStatus == ReachableViaWiFi) {
        DebugLog(@"Network status: WiFi");
        [self.syncBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"progress-1" ofType:@"png"]] forState:UIControlStateNormal];
    } else if (appDelegate.currentNetworkStatus == ReachableViaWWAN) {
        DebugLog(@"Network status: 3G");
        [self.syncBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"progress-1" ofType:@"png"]] forState:UIControlStateNormal];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - In-app purchases
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) purchaseSuccess:(id)sender {
    [FlurryAPI logEvent:FLURRY_IN_APP_PURCHASE_UNLIMITED_STROOMS];
    [self.unlimitedLinkView removeFromSuperview];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local Utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) calculateSpareStroomCells {
    NSInteger numOfRows = [stroomSupervisors count];

    if (numOfRows > TARGET_NUM_OF_STROOMS_ON_SCREEN) {
        return 0;
    } else {
        return (TARGET_NUM_OF_STROOMS_ON_SCREEN - numOfRows);
    }
}

@end