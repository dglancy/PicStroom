//
//  PicStroomUserHappinessViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 27/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PicStroomSettingsViewController;
@class PicStroomUserHappinessView;

@interface PicStroomUserHappinessViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UITextViewDelegate> {
    IBOutlet UITableView *happinessTableView;
    UserHappiness userHappiness;
    PicStroomUserHappinessView *happinessView;
    PicStroomSettingsViewController *settingsController;
}
@property (nonatomic, retain) IBOutlet UITableView *happinessTableView;
@property (assign) UserHappiness userHappiness;
@property (nonatomic, retain) PicStroomUserHappinessView *happinessView;
@property (nonatomic, assign) PicStroomSettingsViewController *settingsController;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) weatherIconOneWasPressed:(id)sender;
- (void) weatherIconTwoWasPressed:(id)sender;
- (void) weatherIconThreeWasPressed:(id)sender;
- (void) weatherIconFourWasPressed:(id)sender;

@end
