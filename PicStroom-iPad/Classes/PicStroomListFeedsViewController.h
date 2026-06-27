//
//  PicStroomListFeedsViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 30/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PicStroomListFeedsViewControllerDelegate;

@interface PicStroomListFeedsViewController : UIViewController <UIAlertViewDelegate> {
    id <PicStroomListFeedsViewControllerDelegate> delegate;
    NSMutableArray *feedSummaries;
    NSMutableArray *selectedIdx;
    IBOutlet UITableView *listFeedsTableView;
    IBOutlet UIBarButtonItem *doneBtn;
}
@property (nonatomic, assign) id <PicStroomListFeedsViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *feedSummaries;
@property (nonatomic, retain) NSMutableArray *selectedIdx;
@property (nonatomic, retain) IBOutlet UITableView *listFeedsTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Util function
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) isFeedChecked:(NSInteger)index;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction) doneBtnPressed:(id)sender;

@end

@protocol PicStroomListFeedsViewControllerDelegate
@optional
- (void) didPressDoneBtn:(PicStroomListFeedsViewController *)sender;
@end
