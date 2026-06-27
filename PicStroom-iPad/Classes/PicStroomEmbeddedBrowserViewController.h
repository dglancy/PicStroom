//
//  PicStroomEmbeddedBrowserViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 21/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "PicStroomListFeedsViewController.h"

#import "InstapaperKit.h"

@protocol PicStroomEmbeddedBrowserViewControllerDelegate;
@class PicStroomFeedSummary;
@class PicStroomEmbeddedBrowserHelpViewController;

@interface PicStroomEmbeddedBrowserViewController : UIViewController <UIWebViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UIPopoverControllerDelegate, IKEngineDelegate, PicStroomListFeedsViewControllerDelegate> {

    id <PicStroomEmbeddedBrowserViewControllerDelegate> delegate;

    BOOL justLoaded;
    BOOL basicModeEnabled;
    NSURL *url;
    NSInteger webViewLoads;
    NSArray *feedsFound;

    IBOutlet UIWebView *webView;
    IBOutlet UIView *toolbar;
    IBOutlet UIButton *backBtn;
    IBOutlet UIButton *forwardBtn;
    IBOutlet UIButton *searchBtn;
    IBOutlet UIButton *urlBtn;
    IBOutlet UIButton *doneBtn;
    IBOutlet UILabel *stroomsStatusLabel;

    UIButton *closeToStroomsBtn;
    UIButton *closeBtn;
    UIButton *emailBtn;
    UIButton *safariBtn;
    IBOutlet UILabel *webpageTitle;
    UIButton *albumBtn;
    UIButton *dropboxBtn;
    UIButton *instapaperBtn;
    IBOutlet UIButton *stroomsBtn;
    IBOutlet UIActivityIndicatorView *browserActivityIndicatorView;

    UIView *addressBar;
    UITextField *addressField;
    UIView *feedPanel;

    ToolbarPosition toolbarPosition;
    UIView *toolbarView;

    PicStroomListFeedsViewController *listFeedsController;
    UIPopoverController *popoverController;

    PicStroomEmbeddedBrowserHelpViewController *helpController;

    NSMutableArray *feedSummaries;

    BOOL unloadedByMemoryWarning;
}
@property (nonatomic, assign) id <PicStroomEmbeddedBrowserViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL justLoaded;
@property (nonatomic, assign) BOOL basicModeEnabled;
@property (nonatomic, retain) NSArray *feedsFound;
@property (assign)            NSInteger webViewLoads;

@property (nonatomic, retain) IBOutlet UIWebView *webView;

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) IBOutlet UIView *toolbar;
@property (nonatomic, retain) IBOutlet UIButton *backBtn;
@property (nonatomic, retain) IBOutlet UIButton *forwardBtn;
@property (nonatomic, retain) IBOutlet UIButton *searchBtn;
@property (nonatomic, retain) IBOutlet UIButton *urlBtn;
@property (nonatomic, retain) IBOutlet UIButton *doneBtn;
@property (nonatomic, retain) IBOutlet UILabel *stroomsStatusLabel;

@property (nonatomic, retain) UIButton *closeToStroomsBtn;
@property (nonatomic, retain) UIButton *closeBtn;
@property (nonatomic, retain) UIButton *emailBtn;
@property (nonatomic, retain) UIButton *safariBtn;
@property (nonatomic, retain) IBOutlet UILabel *webpageTitle;
@property (nonatomic, retain) UIButton *albumBtn;
@property (nonatomic, retain) UIButton *dropboxBtn;
@property (nonatomic, retain) UIButton *instapaperBtn;
@property (nonatomic, retain) IBOutlet UIButton *stroomsBtn;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *browserActivityIndicatorView;

@property (nonatomic, retain) UIView *addressBar;
@property (nonatomic, retain) UITextField *addressField;
@property (nonatomic, retain) UIView *feedPanel;

@property (nonatomic, retain) PicStroomListFeedsViewController *listFeedsController;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (assign) ToolbarPosition toolbarPosition;
@property (nonatomic, retain) UIView *toolbarView;

@property (nonatomic, retain) PicStroomEmbeddedBrowserHelpViewController *helpController;
@property (nonatomic, retain) NSMutableArray *feedSummaries;

@property (assign) BOOL unloadedByMemoryWarning;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction) doneBtnPressed:(id)sender;
- (void) closeToStroomsBtnPressed:(id)sender;
- (IBAction) closeBtnPressed:(id)sender;
- (IBAction) backBtnPressed:(id)sender;
- (IBAction) forwardBtnPressed:(id)sender;
- (IBAction) searchBtnPressed:(id)sender;
- (IBAction) urlBtnPressed:(id)sender;
- (IBAction) emailBtnPressed:(id)sender;
- (IBAction) safariBtnPressed:(id)sender;
- (IBAction) albumBtnPressed:(id)sender;
- (IBAction) dropboxBtnPressed:(id)sender;
- (IBAction) streamsBtnPressed:(id)sender;
- (IBAction) instapaperBtnPressed:(id)sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Toolbar
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showFloatingToolbar;
- (void) showAddressBar;
- (void) hideAddressBar;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomListFeedsViewControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDoneBtn:(PicStroomListFeedsViewController *)sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Grab screenshot
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIImage *) grabScreenshot;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Site scanning functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (PicStroomFeedSummary *) scanRSSFeed:(NSURL *)rssURL withIndex:(NSNumber *)index;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Translucent Notification Panel
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) displayTranslucentNotificationView:(translucentNotificationType)translucentNotificationType;
- (void) fadeView:(UIView *)view;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *)notice;

@end

@protocol PicStroomEmbeddedBrowserViewControllerDelegate
@optional
- (void) didPressBackToStroomsBtn:(PicStroomEmbeddedBrowserViewController *)sender;
- (void) didPressDoneBtn:(PicStroomEmbeddedBrowserViewController *)sender;
@end