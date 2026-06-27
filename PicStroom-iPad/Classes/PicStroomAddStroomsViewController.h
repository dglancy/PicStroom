//
//  PicStroomAddStroomsViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PicStroomEmbeddedBrowserViewController.h"

@protocol PicStroomAddStroomViewControllerDelegate;

@interface PicStroomAddStroomsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, PicStroomEmbeddedBrowserViewControllerDelegate> {

    id <PicStroomAddStroomViewControllerDelegate> delegate;
    IBOutlet UITableView *addStroomsTableView;
    BOOL hideDoneBtn;
}
@property (nonatomic, assign) id <PicStroomAddStroomViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *addStroomsTableView;
@property (assign) BOOL hideDoneBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;

@end

@protocol PicStroomAddStroomViewControllerDelegate
@optional
- (void) didMakeRequestToLaunchBrowser:(PicStroomAddStroomsViewController *)controller;
@end