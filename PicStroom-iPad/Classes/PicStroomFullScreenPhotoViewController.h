//
//  PicStroomFullScreenPhotoViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 18/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#import "PicStroomEmbeddedBrowserViewController.h"
#import "DBRestClient.h"
#import "InstapaperKit.h"

@class PicStroomSupervisor;
@class PicStroomFullScreenPhotoScrollView;
@class Picture;

@interface PicStroomFullScreenPhotoViewController : UIViewController <UIScrollViewDelegate, MFMailComposeViewControllerDelegate, 
                        IKEngineDelegate, PicStroomEmbeddedBrowserViewControllerDelegate> {
	NSMutableArray *currentRawPictureUUIDs;
	NSInteger startIdx;
	Picture *currentPicture;

	BOOL slideShowPlaying;
	NSTimer *slideShowTimer;

	IBOutlet UIScrollView *pagingScrollView;
	UILabel *entryRelatedTextView;
	UILabel *stroomReleatedTextView;

	NSMutableSet *recycledPages;
	NSMutableSet *visiblePages;

	// these values are stored off before we start rotation so we adjust our content offset appropriately during rotation
	int firstVisiblePageIndexBeforeRotation;
	CGFloat percentScrolledIntoFirstVisiblePage;

	// HUD = Toolbar + Photo Title + Stroom Name
	BOOL hudVisable;

	// Title
	UIButton *mainTitleButton;
	UIButton *subTitleButton;

	// Toolbar
	UITapGestureRecognizer *gestureRecognizer;
	UIView *toolbarView;

	// Control bar buttons -- need to control in no-network situations
	ToolbarPosition toolbarPosition;
	UIButton *playBtn;
	UIButton *backBtn;
	UIButton *emailBtn;
	UIButton *saveAlbumBtn;
	UIButton *websiteBtn;
	UIButton *dropboxBtn;
    UIButton *starBtn;
    UIButton *instapaperBtn;
}
@property (nonatomic, retain) NSMutableArray *currentRawPictureUUIDs;
@property (assign)            NSInteger startIdx;
@property (assign)            BOOL slideShowPlaying;
@property (nonatomic, retain) NSTimer *slideShowTimer;
@property (nonatomic, retain) Picture *currentPicture;
@property (nonatomic, retain) UIScrollView *pagingScrollView;
@property (nonatomic, retain) NSMutableSet *recycledPages;
@property (nonatomic, retain) NSMutableSet *visiblePages;
@property (nonatomic)         BOOL hudVisable;
@property (nonatomic, retain) UIButton *mainTitleButton;
@property (nonatomic, retain) UIButton *subTitleButton;
@property (nonatomic, retain) UIView *toolbarView;
@property (nonatomic, retain) UITapGestureRecognizer *gestureRecognizer;

@property (assign) ToolbarPosition toolbarPosition;
@property (nonatomic, retain) UIButton *playBtn;
@property (nonatomic, retain) UIButton *backBtn;
@property (nonatomic, retain) UIButton *emailBtn;
@property (nonatomic, retain) UIButton *saveAlbumBtn;
@property (nonatomic, retain) UIButton *websiteBtn;
@property (nonatomic, retain) UIButton *dropboxBtn;
@property (nonatomic, retain) UIButton *starBtn;
@property (nonatomic, retain) UIButton *instapaperBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Frame calculations
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGRect) frameForPagingScrollView;
- (CGRect) frameForPageAtIndex:(NSUInteger) index;
- (CGSize) contentSizeForPagingScrollView;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Tiling and page configuration
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) jumpToStartingImageWithinStream;
- (void) tilePages;
- (void) configurePage:(PicStroomFullScreenPhotoScrollView *) page forIndex:(NSUInteger) index;
- (BOOL) isDisplayingPageForIndex:(NSUInteger) index;
- (PicStroomFullScreenPhotoScrollView *) dequeueRecycledPage;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image wrangling
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger) imageCount;
- (UIImage *) imageAtIndex:(NSUInteger) index;
- (Picture *) currentVisablePicture;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View controller rotation methods
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) calculateWillAnimateRotationToInterfaceOrientation;
- (void) calculateWillRotateToInterfaceOrientation;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Toolbar & Toolbar Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showTitles;
- (void) updateTitles;
- (void) showToolbar:(CGPoint) point;
- (void) hideToolbar;
- (void) toggleToolbar;
- (void) displayTranslucentNotificationView:(translucentNotificationType) translucentNotificationType;
- (void) fadeView:(UIView *) view;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizers
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) createGestureRecognizers;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) playSlideshowBtnPressed:(id) selector;
- (void) showEmbeddedBrowserBtnPressed:(id) selector;
- (void) sendEmailBtnPressed:(id) selector;
- (void) saveDropBoxBtnPressed:(id) selector;
- (void) saveAlbumBtnPressed:(id) selector;
- (void) backBtnPressed:(id) selector;
- (void) starBtnPressed:(id) selector;
- (void) instapaperBtnPressed:(id)selector;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Slidshow

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) fadeHUD;
- (void) fireNextSlide;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomEmbeddedBrowserViewControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressBackToStroomsBtn:(PicStroomEmbeddedBrowserViewController *) sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *) notice;

@end