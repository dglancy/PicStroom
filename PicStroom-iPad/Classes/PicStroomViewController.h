//
//  PicStroomViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 01/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PicStroomFullScreenPhotoViewController.h"
#import "PicStroomEmbeddedBrowserViewController.h"
#import "PicStroomAddStroomsViewController.h"
#import "PicStroomSettingsViewController.h"

#include "Reachability.h"

@class PicStroomSettingsViewController;
@class PicStroomWebStroomLinkView;
@class PicStroomDropboxStroomLinkView;
@class PicStroomUnlimitedLinkView;

@interface PicStroomViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, PicStroomEmbeddedBrowserViewControllerDelegate, PicStroomAddStroomViewControllerDelegate, PicStroomSettingsViewControllerDelegate> {
    BOOL firstAppLoad;

    IBOutlet UIView *controlBarView;
    IBOutlet UITableView *stroomTableView;
    IBOutlet UIButton *addStroomBtn;
    IBOutlet UIButton *preferencesBtn;
    IBOutlet UIButton *syncBtn;
    IBOutlet PicStroomSettingsViewController *prefsViewController;

    PicStroomWebStroomLinkView *webStroomLinkView;
    PicStroomDropboxStroomLinkView *dropboxStroomLinkView;
    PicStroomUnlimitedLinkView *unlimitedLinkView;

    NSMutableArray *stroomSupervisors;
    PicStroomSupervisor *starredStroomSupervisor;
}
@property (assign) BOOL firstAppLoad;
@property (nonatomic, retain) IBOutlet UIView *controlBarView;
@property (nonatomic, retain) IBOutlet UITableView *stroomTableView;
@property (nonatomic, retain) IBOutlet UIButton *addStroomBtn;
@property (nonatomic, retain) IBOutlet UIButton *preferencesBtn;
@property (nonatomic, retain) IBOutlet UIButton *syncBtn;
@property (nonatomic, retain) IBOutlet PicStroomSettingsViewController *prefsViewController;
@property (nonatomic, retain) PicStroomWebStroomLinkView *webStroomLinkView;
@property (nonatomic, retain) PicStroomDropboxStroomLinkView *dropboxStroomLinkView;
@property (nonatomic, retain) PicStroomUnlimitedLinkView *unlimitedLinkView;
@property (retain) NSMutableArray *stroomSupervisors;
@property (retain) PicStroomSupervisor *starredStroomSupervisor;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static reference
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomViewController *) getCurrentController;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction) addBtnPressed:(id)sender;
- (IBAction) preferencesBtnPressed:(id)sender;
- (IBAction) syncBtnPressed:(id)sender;
- (void) launchFullScreenPhotoView:(id)sender;

- (IBAction) addWebStroomDirectBtnPressed:(id)sender;
- (IBAction) addDropboxStroomDirectBtnPressed:(id)sender;
- (IBAction) getUnlimitedDirectBtnPressed:(id)sender;

- (void) highlightWebStroomDirectBtn;
- (void) unhighlightWebStroomDirectBtn;
- (void) highlightDropboxStroomDirectBtn;
- (void) unhighlightDropboxStroomDirectBtn;
- (void) highlightUnlimitedStroomDirectBtn;
- (void) unhighlightUnlimitedStroomDirectBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomAddStroomsViewController delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didMakeRequestToLaunchBrowser:(PicStroomAddStroomsViewController *)controller;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync & Store (Core Data)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) coreDataChanged:(NSNotification *)notif;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *)notice;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - In-app purchases
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) purchaseSuccess:(id)sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local Utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) calculateSpareStroomCells;

@end