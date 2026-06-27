//
//  PicStroomDetailsViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Stroom;
@class PicStroomSupervisor;
@class PicStroomViewController;
@protocol PicStroomDetailsViewControllerDelegate;

@interface PicStroomDetailsViewController : UITableViewController <UITextFieldDelegate> {
    IBOutlet UITableView *detailsTableView;
    Stroom *stroom;
    NSIndexPath *indexPathToDelete;

    UITextField *titleField;
}
@property (nonatomic, assign) id <PicStroomDetailsViewControllerDelegate> delegate;
@property (nonatomic, retain) UITextField *titleField;
@property (nonatomic, retain) IBOutlet UITableView *detailsTableView;
@property (nonatomic, retain) Stroom *stroom;
@property (nonatomic, retain) NSIndexPath *indexPathToDelete;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveStroom;
- (void) deleteStroom;

@end

@protocol PicStroomDetailsViewControllerDelegate
- (void) picStroomDetailsViewControllerDidFinishWithDelete:(PicStroomDetailsViewController *)controller;
@end