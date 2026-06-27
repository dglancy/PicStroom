//
//  PicStroomInAppPurchaseAlertViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 16/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomInAppPurchaseAlertViewController.h"

#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomListStroomsViewController.h"
#import "PicStroomViewController.h"

@implementation PicStroomInAppPurchaseAlertViewController
@synthesize inAppPurchaseManager;
@synthesize productName;
@synthesize purchaseBtn;
@synthesize manageStroomsTable;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void) dealloc {
    [productName release];
    [purchaseBtn release];
    [manageStroomsTable release];
    [inAppPurchaseManager release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_APP_STORE_PRODUCT_LIST_FETCHED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_FAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_CANCELLED object:nil];
    DebugLog(@"PicStroomInAppPurchaseAlertViewController dealloc()");
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [FlurryAPI logEvent:FLURRY_STATS_IN_APP_PURCHASE_DIALOG_SHOWN];
    
    self.title = @"Add unlimited Streams";

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];

    self.purchaseBtn.enabled = NO;
    self.inAppPurchaseManager = [[[PicStroomInAppPurchaseManager alloc] init] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productListReturnedFromAppStore) name:NOTIF_APP_STORE_PRODUCT_LIST_FETCHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPressDone) name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseFailed:) name:NOTIF_IN_APP_PURCHASE_TX_FAIL object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseCancelled:) name:NOTIF_IN_APP_PURCHASE_TX_CANCELLED object:nil];
    [self.inAppPurchaseManager requestProductData];
}

- (void) viewDidUnload {
    [manageStroomsTable release];
    manageStroomsTable = nil;
    [productName release];
    productName = nil;
    [purchaseBtn release];
    purchaseBtn = nil;
    [manageStroomsTable release];
    manageStroomsTable = nil;
    [inAppPurchaseManager release];
    inAppPurchaseManager = nil;
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - In-App Purchases
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void) productListReturnedFromAppStore {
    if (inAppPurchaseManager.unlimitedStrooms) {
        self.purchaseBtn.enabled = YES;
        self.productName.text = inAppPurchaseManager.unlimitedStrooms.localizedTitle;
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:inAppPurchaseManager.unlimitedStrooms.priceLocale];
        self.purchaseBtn.titleLabel.textAlignment = UITextAlignmentCenter;
        [self.purchaseBtn setTitle:[numberFormatter stringFromNumber:inAppPurchaseManager.unlimitedStrooms.price] forState:UIControlStateNormal];
        [numberFormatter release];
    }
}

- (IBAction) purchaseProduct:(id)sender {
    DebugLog(@"Purchase product");
    [self.purchaseBtn setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"in-app-button-green" ofType:@"png"]] forState:UIControlStateNormal];
    [inAppPurchaseManager purchaseUnlimitedStrooms];
}

- (void) purchaseFailed:(id)sender {
    [self.purchaseBtn setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"in-app-button-grey" ofType:@"png"]] forState:UIControlStateNormal];
}

- (void) purchaseCancelled:(id)sender {
    [self.purchaseBtn setBackgroundImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"in-app-button-grey" ofType:@"png"]] forState:UIControlStateNormal];
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
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ManageStroomCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = @"Edit/Order/Delete Streams";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
    if ([mainViewController.stroomSupervisors count] == 0) {
        return;
    }
    PicStroomListStroomsViewController *listStroomsController = [[PicStroomListStroomsViewController alloc] initWithNibName:@"PicStroomListStroomsViewController" bundle:nil];
    [self.navigationController pushViewController:listStroomsController animated:YES];
    [listStroomsController release];
}

@end
