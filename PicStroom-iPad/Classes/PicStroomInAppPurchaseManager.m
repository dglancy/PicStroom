//
//  InAppPurchaseManager.m
//  PicStroom
//
//  Created by Damien Glancy on 16/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomInAppPurchaseManager.h"
#import "PicStroomManager.h"

#import "SFHFKeychainUtils.h"


@implementation PicStroomInAppPurchaseManager
@synthesize unlimitedStrooms;
@synthesize request;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Memory management
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [unlimitedStrooms release];
    if (request) {
        [request cancel];
    }
    [request release];
    [super dealloc];
    DebugLog(@"PicStroomInAppPurchaseManager dealloc()");
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - call this method once on startup
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) loadStore {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self]; // restarts any purchases if they were interrupted last time the app was open
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Check if in-app purchases are allowed
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) canMakePurchases {
    return [SKPaymentQueue canMakePayments];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Keychain Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) isLicensedForUnlimitedStrooms {
    if (PICSTROOM_PRO_VERSION) {
        return YES;
    }

    NSError *error;
    NSString *response = [SFHFKeychainUtils getPasswordForUsername:UNLIMITED_STROOMS_KEYCHAIN_KEY andServiceName:UNLIMITED_STROOMS_KEYCHAIN_KEY error:&error];

    if (error) {
        DebugLog(@"An issue reading license key from keystore");
        return NO;
    } else {
        if ([response isEqualToString:UNLIMITED_STROOMS_KEYCHAIN_VALUE]) {
            return YES;
        }
    }
    return NO;
}

+ (void) licenseForUnlimitedStrooms {
    NSError *error;

    [SFHFKeychainUtils storeUsername:UNLIMITED_STROOMS_KEYCHAIN_KEY andPassword:UNLIMITED_STROOMS_KEYCHAIN_VALUE forServiceName:UNLIMITED_STROOMS_KEYCHAIN_KEY updateExisting:YES error:&error];
    if (error) {
        DebugLog(@"An issue inserting licenese key into keystore");
    }
}

+ (void) unLicenseForUnlimitedStrooms {
    NSError *error;

    [SFHFKeychainUtils deleteItemForUsername:UNLIMITED_STROOMS_KEYCHAIN_KEY andServiceName:UNLIMITED_STROOMS_KEYCHAIN_KEY error:&error];
    if (error) {
        DebugLog(@"An issue deleting licenese key from keystore");
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get Product List
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) requestProductData {
    self.request = [[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:UNLIMITED_STROOMS_PRODUCT_ID]] autorelease];
    self.request.delegate = self;
    [self.request start];
}

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if ([response.products count] > 0) {
        self.unlimitedStrooms = [response.products objectAtIndex:0];
    }
    for (NSString *invalidProductId in response.invalidProductIdentifiers) {
        DebugLog(@"Invalid product id: %@", invalidProductId);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_APP_STORE_PRODUCT_LIST_FETCHED object:self];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Purchase product
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) purchaseUnlimitedStrooms {
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:UNLIMITED_STROOMS_PRODUCT_ID];

    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Purchase Helpers
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// saves a record of the transaction by storing the receipt to disk
- (void) recordTransaction:(SKPaymentTransaction *)transaction {
    if ([transaction.payment.productIdentifier isEqualToString:UNLIMITED_STROOMS_PRODUCT_ID]) {
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:@"unlimitedStroomsTransactionReceipt" ];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (void) provideContent:(NSString *)productId {
    if ([productId isEqualToString:UNLIMITED_STROOMS_PRODUCT_ID]) {
        [PicStroomInAppPurchaseManager licenseForUnlimitedStrooms];
    }
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void) finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful {
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction", nil];
    if (wasSuccessful) {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_IN_APP_PURCHASE_TX_SUCCESS object:self userInfo:userInfo];
    } else {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_IN_APP_PURCHASE_TX_FAIL object:self userInfo:userInfo];
    }
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

- (void) restoreTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled) {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    } else {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_IN_APP_PURCHASE_TX_CANCELLED object:self userInfo:nil];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - SKPaymentTransactionObserver methods
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

@end