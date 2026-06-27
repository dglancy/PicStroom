//
//  PicStroomSettingsViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PicStroomSettingsViewControllerDelegate;
@class PicStroomUserHappinessView;

@interface PicStroomSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    id <PicStroomSettingsViewControllerDelegate> delegate;
    
    UITableView *settingsTableView;

    BOOL happinessUpdated;

    // :-)
    UserHappiness userHappiness;
    PicStroomUserHappinessView *happinessView;
    NSString *comment;
}
@property (nonatomic, assign) id <PicStroomSettingsViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL happinessUpdated;
@property (nonatomic, retain) UITableView *settingsTableView;
@property (nonatomic, retain) NSString *comment;
@property (assign) UserHappiness userHappiness;
@property (nonatomic, retain) PicStroomUserHappinessView *happinessView;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;
- (void) weatherIconOneWasPressed:(id)sender;
- (void) weatherIconTwoWasPressed:(id)sender;
- (void) weatherIconThreeWasPressed:(id)sender;
- (void) weatherIconFourWasPressed:(id)sender;

@end

@protocol PicStroomSettingsViewControllerDelegate
@optional
- (void) settingsDialogDidClose:(PicStroomSettingsViewController *)sender;
@end