//
//  PicStroomLinkInstapaperViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InstapaperKit.h"

@interface PicStroomLinkInstapaperViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, IKEngineDelegate> {
    UITableView *instapaperLoginTableView;
    
    IKEngine *instapaperKit;
    
    UITableViewCell *emailCell;
    UITextField *emailField;
    UITableViewCell *passwordCell;
    UITextField *passwordField;
    
    UIView *translucentView;
    UIActivityIndicatorView *av;
    
    BOOL directlyLoaded;
    BOOL loadFromSettings;
    BOOL loadFromFullScreenPhotoView;
}

@property (nonatomic, retain) IBOutlet UITableView *instapaperLoginTableView;
@property (nonatomic, retain) IKEngine *instapaperKit;
@property (assign) BOOL directlyLoaded;
@property (assign) BOOL loadFromSettings;
@property (assign) BOOL loadFromFullScreenPhotoView;
@property (nonatomic, retain) UIView *translucentView;
@property (nonatomic, retain) UIActivityIndicatorView *av;

- (void) errorWithTitle:(NSString *)title message:(NSString *)message;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;
- (void) didPressCancel;
- (void) errorWithTitle:(NSString *)title message:(NSString *)message;

@end
