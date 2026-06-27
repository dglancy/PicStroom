//
//  PicStroomGalleryController.h
//  PicStroom
//
//  Created by Damien Glancy on 31/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PicStroomViewController;
@protocol PicStroomGalleryControllerDelegate;

@interface PicStroomGalleryController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {

    id<PicStroomGalleryControllerDelegate> delegate;
    IBOutlet UITableView *galleryTableView;
    NSDictionary *gallery;
    NSMutableArray *selectedRows;
    NSMutableArray *greyedOutRows;
    PicStroomViewController *mainViewController;

    UIView *translucentView;
    UIActivityIndicatorView *av;
}
@property (nonatomic, assign) id<PicStroomGalleryControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *galleryTableView;
@property (nonatomic, retain) NSDictionary *gallery;
@property (nonatomic, retain) UIView *translucentView;
@property (nonatomic, retain) UIActivityIndicatorView *av;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressClose;
- (void) didPressDone;
- (void) addGalleryStrooms;
- (void) updateStroomTable;
- (void) scheduleSyncOfNewStrooms:(NSArray *)newStroomSupervisors;

@end

@protocol PicStroomGalleryControllerDelegate
@optional
- (void) didPressGalleryDoneBtn:(PicStroomGalleryController *)controller;
@end