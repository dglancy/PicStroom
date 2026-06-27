//
//  PicStroomListStroomsViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PicStroomDetailsViewController.h"

@class PicStroomViewController;

@interface PicStroomListStroomsViewController : UIViewController <PicStroomDetailsViewControllerDelegate> {
    IBOutlet UITableView *listStroomsTableView;
    PicStroomViewController *mainViewController;

    UIView *translucentView;
    UIActivityIndicatorView *av;
    
    NSNumber *currentRowBeingDeleted;
}
@property (nonatomic, retain) IBOutlet UITableView *listStroomsTableView;
@property (nonatomic, retain) PicStroomViewController *mainViewController;
@property (nonatomic, retain) UIView *translucentView;
@property (nonatomic, retain) UIActivityIndicatorView *av;
@property (nonatomic, retain) NSNumber *currentRowBeingDeleted;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressAddStroom;
- (void) activateEditing;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomListStroomsViewController delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) picStroomDetailsViewControllerDidFinishWithDelete:(PicStroomDetailsViewController *)controller;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Delete stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleCancelSyncNotification:(NSNotification *)notification;
- (void) deleteStroom:(NSNumber *)row;
- (void) executePhysicalDelete:(NSNumber *)row;

@end
