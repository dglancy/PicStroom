//
//  PicStroomInAppPurchaseAlertViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 16/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PicStroomInAppPurchaseManager;
@class PicStroomViewController;

@interface PicStroomInAppPurchaseAlertViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    PicStroomInAppPurchaseManager *inAppPurchaseManager;
    IBOutlet UILabel *productName;
    IBOutlet UIButton *purchaseBtn;
    IBOutlet UITableView *manageStroomsTable;
}
@property (nonatomic, retain) PicStroomInAppPurchaseManager *inAppPurchaseManager;
@property (nonatomic, retain) IBOutlet UILabel *productName;
@property (nonatomic, retain) IBOutlet UIButton *purchaseBtn;
@property (nonatomic, retain) IBOutlet UITableView *manageStroomsTable;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - In-App Purchases
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) productListReturnedFromAppStore;
- (void) purchaseProduct:(id)sender;
- (void) purchaseFailed:(id)sender;
- (void) purchaseCancelled:(id)sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;

@end
