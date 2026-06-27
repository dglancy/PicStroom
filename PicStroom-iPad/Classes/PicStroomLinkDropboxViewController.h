//
//  PicStroomLinkDropboxViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBRestClient.h"


@interface PicStroomLinkDropboxViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, DBRestClientDelegate> {
    UITableView *linkDropboxTableView;
    UITableViewCell *emailCell;
    UITextField *emailField;
    UITableViewCell *passwordCell;
    UITextField *passwordField;

    UIView *translucentView;
    UIActivityIndicatorView *av;

    DBRestClient *restClient;
    BOOL directlyLoaded;
    BOOL loadFromSettings;
    BOOL loadFromFullScreenPhotoView;
}
@property (nonatomic, retain) IBOutlet UITableView *linkDropboxTableView;
@property (assign) BOOL directlyLoaded;
@property (assign) BOOL loadFromSettings;
@property (assign) BOOL loadFromFullScreenPhotoView;
@property (nonatomic, retain) UIView *translucentView;
@property (nonatomic, retain) UIActivityIndicatorView *av;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;
- (void) didPressCancel;
- (void) errorWithTitle:(NSString *)title message:(NSString *)message;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox SDK
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (DBRestClient *) restClient;

@end
