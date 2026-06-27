//
//  PicStroomAppDelegate.h
//  PicStroom
//
//  Created by Damien Glancy on 01/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@class PicStroomViewController;
@class PicStroomInAppPurchaseManager;

@interface PicStroomAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    PicStroomViewController *viewController;
    Reachability *reachability;
    NetworkStatus currentNetworkStatus;
    NSTimer *syncTimer;
    NSDate *lastSyncTime;
    PicStroomInAppPurchaseManager *inAppPurchaseManager;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PicStroomViewController *viewController;
@property (assign) NetworkStatus currentNetworkStatus;
@property (nonatomic, retain) Reachability *reachability;
@property (nonatomic, retain) NSTimer *syncTimer;
@property (nonatomic, retain) NSDate *lastSyncTime;
@property (nonatomic, retain) PicStroomInAppPurchaseManager *inAppPurchaseManager;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sync;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data stack
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveContext;
- (NSURL *) applicationDocumentsDirectory;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Handle IAP bug (from v1.1)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)handleIAPbug:(NSString *)userId;

@end