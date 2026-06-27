//
//  PicStroomInAppPurchaseViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 08/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//


#import "PicStroomInAppPurchaseViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomInAppPurchaseManager.h"

@implementation PicStroomInAppPurchaseViewController
@synthesize directlyLoaded;
@synthesize inAppPurchaseManager;
@synthesize productName;
@synthesize purchaseBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_APP_STORE_PRODUCT_LIST_FETCHED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_FAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_IN_APP_PURCHASE_TX_CANCELLED object:nil];

    [productName release];
    [purchaseBtn release];
    [inAppPurchaseManager release];
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
    
    [FlurryAPI logEvent:FLURRY_STATS_IN_APP_PURCHASE_DIALOG_SHOWN];
    
    if (directlyLoaded) {
        self.title = @"Add unlimited Streams";
    } else {
        self.title = @"Get unlimited Streams";
    }

    if (directlyLoaded) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    }

    self.purchaseBtn.enabled = NO;
    self.inAppPurchaseManager = [[[PicStroomInAppPurchaseManager alloc] init] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productListReturnedFromAppStore) name:NOTIF_APP_STORE_PRODUCT_LIST_FETCHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPressDone) name:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseFailed:) name:NOTIF_IN_APP_PURCHASE_TX_FAIL object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseCancelled:) name:NOTIF_IN_APP_PURCHASE_TX_CANCELLED object:nil];
    [self.inAppPurchaseManager requestProductData];
}

- (void) viewDidUnload {
    self.productName = nil;
    self.purchaseBtn = nil;
    self.inAppPurchaseManager = nil;
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
    if (self.directlyLoaded) {
        [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
