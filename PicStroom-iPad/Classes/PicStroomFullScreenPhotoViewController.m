//
//  PicStroomFullScreenPhotoViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 18/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>

#import "PicStroomFullScreenPhotoViewController.h"
#import "PicStroomFullScreenPhotoScrollView.h"
#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomManager.h"
#import "PicStroomImageProcessor.h"
#import "PicStroomSupervisor.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomDropboxUploader.h"
#import "PicStroomEmbeddedBrowserViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomMetadataManager.h"
#import "PicStroomStarredPicturesManager.h"
#import "PicStroomInstapaperManager.h"
#import "PicStroomLinkInstapaperViewController.h"

#import "DropboxSDK.h"

#import "Picture.h"
#import "Stroom.h"
#import "Entry.h"

@implementation PicStroomFullScreenPhotoViewController
@synthesize currentRawPictureUUIDs;
@synthesize slideShowPlaying;
@synthesize slideShowTimer;
@synthesize startIdx;
@synthesize currentPicture;
@synthesize pagingScrollView;
@synthesize recycledPages;
@synthesize visiblePages;
@synthesize hudVisable;
@synthesize mainTitleButton;
@synthesize subTitleButton;
@synthesize toolbarView;
@synthesize gestureRecognizer;
@synthesize toolbarPosition;
@synthesize playBtn;
@synthesize backBtn;
@synthesize emailBtn;
@synthesize saveAlbumBtn;
@synthesize websiteBtn;
@synthesize dropboxBtn;
@synthesize starBtn;
@synthesize instapaperBtn;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
	[currentRawPictureUUIDs release];
	[currentPicture release];
	[pagingScrollView release];
	[recycledPages release];
	[visiblePages release];
	[mainTitleButton release];
	[subTitleButton release];
	[toolbarView release];
	[gestureRecognizer release];

	[backBtn release];
	[emailBtn release];
	[saveAlbumBtn release];
	[websiteBtn release];
	[dropboxBtn release];
    [starBtn release];
    [instapaperBtn release];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	DebugLog(@"Full Screen dealloc()");
	[super dealloc];
}

- (void) didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
	[super viewDidLoad];
	DebugLog(@"PicStroom Full Screen Photo View Controller viewDidLoad()");
	self.hudVisable = YES;
	self.slideShowPlaying = NO;

	self.pagingScrollView.frame = [self frameForPagingScrollView];
	self.pagingScrollView.contentSize = [self contentSizeForPagingScrollView];

	self.mainTitleButton = [[[UIButton alloc] init] autorelease];
	self.subTitleButton = [[[UIButton alloc] init] autorelease];

	self.recycledPages = [[[NSMutableSet alloc] init] autorelease];
	self.visiblePages = [[[NSMutableSet alloc] init] autorelease];

	// Play Button
	self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.playBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_play_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.playBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_play_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.playBtn addTarget:self action:@selector(playSlideshowBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

	// Back Button
	self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.backBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_overview_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.backBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_overview_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.backBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

	// Site Button
	self.websiteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.websiteBtn addTarget:self action:@selector(showEmbeddedBrowserBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
	// Email Button
	self.emailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	if ([MFMailComposeViewController canSendMail]) {
		[self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_mail_white" ofType:@"png"]] forState:UIControlStateNormal];
		[self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_mail_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
		[self.emailBtn addTarget:self action:@selector(sendEmailBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
	}
	else {
		[self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_mail_grey" ofType:@"png"]] forState:UIControlStateNormal];
	}

	// Save to Album Button
	self.saveAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.saveAlbumBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_photo_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.saveAlbumBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_photo_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.saveAlbumBtn addTarget:self action:@selector(saveAlbumBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
	// Dropbox Button
	self.dropboxBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_white" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.dropboxBtn addTarget:self action:@selector(saveDropBoxBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Star Button
    self.starBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.starBtn addTarget:self action:@selector(starBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Instapaper Button
    self.instapaperBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_white" ofType:@"png"]] forState:UIControlStateNormal];
	[self.instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	[self.instapaperBtn addTarget:self action:@selector(instapaperBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

	[self jumpToStartingImageWithinStream];
	[self tilePages];
	[self createGestureRecognizers];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	[currentPicture release], currentPicture = nil;
	[pagingScrollView release], pagingScrollView = nil;
	[recycledPages release], recycledPages = nil;
	[visiblePages release], visiblePages = nil;
	[mainTitleButton release], mainTitleButton = nil;
	[subTitleButton release], subTitleButton = nil;
	[toolbarView release], toolbarView = nil;
	[gestureRecognizer release], gestureRecognizer = nil;

	[playBtn release], playBtn = nil;
	[backBtn release], backBtn = nil;
	[emailBtn release], emailBtn = nil;
	[starBtn release], starBtn = nil;
	[websiteBtn release], websiteBtn = nil;
	[dropboxBtn release], dropboxBtn = nil;
    [starBtn release], starBtn = nil;
    [instapaperBtn release], instapaperBtn = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];

	DebugLog(@"Full Screen Photo View Controller viewDidUnload()");
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Toolbar & Toolbar Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showTitles {
	DebugLog(@"Main title: %@ and sub title: %@", self.currentPicture.entry.title, self.currentPicture.entry.stroom.title);

	NSString *mainTitle = @"PicStroom";
	NSString *subTitle = @"";

	if ([self.currentPicture.entry.stroom.type intValue] == StroomTypeRSS) {
		mainTitle = self.currentPicture.entry.title;
		subTitle = self.currentPicture.entry.stroom.title;
	}
	else {
		mainTitle = self.currentPicture.entry.title;
		subTitle = @"Dropbox";
	}

	[self.mainTitleButton setTitle:mainTitle forState:UIControlStateNormal];
	self.mainTitleButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:18.0];
	self.mainTitleButton.titleLabel.textColor = [UIColor whiteColor];
	self.mainTitleButton.backgroundColor = [UIColor clearColor];
	self.mainTitleButton.titleLabel.textAlignment = UITextAlignmentLeft;
	CGSize textSizeOfMainButton = [self.mainTitleButton.titleLabel.text sizeWithFont:[self.mainTitleButton.titleLabel font]];
	self.mainTitleButton.frame = CGRectMake(10, 10, textSizeOfMainButton.width, 20);
	[self.mainTitleButton addTarget:self action:@selector(showEmbeddedBrowserBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

	[self.subTitleButton setTitle:subTitle forState:UIControlStateNormal];
	self.subTitleButton.titleLabel.font = [UIFont fontWithName:@"Georgia-Italic" size:14.0];
	self.subTitleButton.titleLabel.textColor = [UIColor whiteColor];
	self.subTitleButton.backgroundColor = [UIColor clearColor];
	CGSize textSizeOfSubTitleButton = [self.subTitleButton.titleLabel.text sizeWithFont:[self.subTitleButton.titleLabel font]];
	self.subTitleButton.frame = CGRectMake(self.mainTitleButton.frame.size.width + 13, 12, textSizeOfSubTitleButton.width, 20);
	[self.subTitleButton addTarget:self action:@selector(showEmbeddedBrowserBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

	[self.view addSubview:self.mainTitleButton];
	[self.view addSubview:self.subTitleButton];
    
    if ([PicStroomMetadataManager isStarredPicture:self.currentPicture]) {
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_white" ofType:@"png"]] forState:UIControlStateNormal];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    } else {
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_white" ofType:@"png"]] forState:UIControlStateNormal];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    }

}

- (void) updateTitles {
	if (hudVisable) {
		NSString *mainTitle;
		NSString *subTitle;

		if ([self.currentPicture.entry.stroom.type intValue] == StroomTypeRSS) {
			mainTitle = self.currentPicture.entry.title;
			subTitle = self.currentPicture.entry.stroom.title;
		}
		else {
			mainTitle = self.currentPicture.entry.title;
			subTitle = @"Dropbox";
		}

		[self.mainTitleButton setTitle:mainTitle forState:UIControlStateNormal];
		CGSize textSizeOfMainButton = [self.mainTitleButton.titleLabel.text sizeWithFont:[self.mainTitleButton.titleLabel font]];
		self.mainTitleButton.frame = CGRectMake(10, 10, textSizeOfMainButton.width, 20);

		[self.subTitleButton setTitle:subTitle forState:UIControlStateNormal];
		CGSize textSizeOfSubTitleButton = [self.subTitleButton.titleLabel.text sizeWithFont:[self.subTitleButton.titleLabel font]];
		self.subTitleButton.frame = CGRectMake(self.mainTitleButton.frame.size.width + 13, 12, textSizeOfSubTitleButton.width, 20);
        
        if ([PicStroomMetadataManager isStarredPicture:self.currentPicture]) {
            [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_white" ofType:@"png"]] forState:UIControlStateNormal];
            [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        } else {
            [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_white" ofType:@"png"]] forState:UIControlStateNormal];
            [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        }
	}
}

- (void) showToolbar:(CGPoint) point {
	CGSize screenSize = self.view.bounds.size;
	CGRect viewRect;
    
    if([self.currentPicture.entry.stroom.type intValue] == StroomTypeDropbox) { // no browser for dropbox strooms
        [websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateNormal];
		[websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
        [self.websiteBtn removeTarget:self action:@selector(showEmbeddedBrowserBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    }

	[self handleNetworkChange:nil];

	// determine screen quadrant
	if ( (screenSize.width - point.x <= 45) && (screenSize.height - point.y >= 90) ) {
		DebugLog(@"show right side toolbar");
		viewRect = CGRectMake( screenSize.width - (TOOLBAR_ICON_WIDTH_PT + 4),
		                       (screenSize.height / 100), // % down from top of screen
		                       TOOLBAR_ICON_WIDTH_PT + 4,
		                       (TOOLBAR_ICON_HEIGHT_PT + TOOLBAR_SPACER_SIZE_PT) * TOOLBAR_NUM_OF_ICONS + (TOOLBAR_SPACER_SIZE_PT * 2) );

		self.backBtn.frame = CGRectMake(2, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.websiteBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 1, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.emailBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 2, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.saveAlbumBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 3, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.starBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 4, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.instapaperBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 5, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.dropboxBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 6, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.playBtn.frame = CGRectMake(2, TOOLBAR_ICON_WIDTH_PT * 7, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.toolbarPosition = ToolbarRight;
	}
	else if ( (point.x <= 90) && (screenSize.height - point.y >= 90) ) {
		DebugLog(@"show left side toolbar");
		viewRect = CGRectMake( 4, 40, TOOLBAR_ICON_WIDTH_PT + 4,
		                       (TOOLBAR_ICON_HEIGHT_PT + TOOLBAR_SPACER_SIZE_PT) * TOOLBAR_NUM_OF_ICONS + (TOOLBAR_SPACER_SIZE_PT * 2) );

		self.backBtn.frame = CGRectMake(2, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.websiteBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 1, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.emailBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 2, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.saveAlbumBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 3, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.starBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 4, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.instapaperBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 5, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.dropboxBtn.frame = CGRectMake(2, TOOLBAR_ICON_HEIGHT_PT * 6, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.playBtn.frame = CGRectMake(2, TOOLBAR_ICON_WIDTH_PT * 7, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.toolbarPosition = ToolbarLeft;
	}
	else if ( (screenSize.width - point.x > screenSize.width / 2) && (screenSize.height - point.y < 90) ) {
		DebugLog(@"show left bottom side toolber");
		viewRect = CGRectMake(4, screenSize.height - TOOLBAR_ICON_HEIGHT_PT + 4, TOOLBAR_ICON_WIDTH_PT * TOOLBAR_NUM_OF_ICONS, TOOLBAR_ICON_HEIGHT_PT + 4);

		self.backBtn.frame = CGRectMake(0, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.websiteBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 1, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.emailBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 2, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.saveAlbumBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 3, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.starBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 4, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.instapaperBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 5, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.dropboxBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 6, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.playBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 7, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.toolbarPosition = ToolbarBottom;
	}
	else if ( (screenSize.width - point.x < screenSize.width / 2) && (screenSize.height - point.y < 90) ) {
		DebugLog(@"show right bottom side toolber");
		viewRect = CGRectMake(screenSize.width - (TOOLBAR_ICON_WIDTH_PT * TOOLBAR_NUM_OF_ICONS) + 4, screenSize.height - TOOLBAR_ICON_HEIGHT_PT + 4, TOOLBAR_ICON_WIDTH_PT * TOOLBAR_NUM_OF_ICONS, TOOLBAR_ICON_HEIGHT_PT + 4);

		self.playBtn.frame = CGRectMake(0, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.dropboxBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 1, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.starBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 2, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.instapaperBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 3, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.saveAlbumBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 4, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.emailBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 5, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.websiteBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 6, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.backBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 7, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.toolbarPosition = ToolbarBottom;
	}
	else if ( (screenSize.width - point.x < screenSize.width) && (point.y < 90) ) {
		DebugLog(@"show top right side toolber");
		viewRect = CGRectMake(screenSize.width - (TOOLBAR_ICON_WIDTH_PT * TOOLBAR_NUM_OF_ICONS) + 4, 0, TOOLBAR_ICON_WIDTH_PT * TOOLBAR_NUM_OF_ICONS, TOOLBAR_ICON_HEIGHT_PT + 4);

		self.playBtn.frame = CGRectMake(0, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.dropboxBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 1, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.starBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 2, 0,TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
        self.instapaperBtn.frame = CGRectMake(TOOLBAR_ICON_HEIGHT_PT * 3, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.saveAlbumBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 4, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.emailBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 5, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.websiteBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 6, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.backBtn.frame = CGRectMake(TOOLBAR_ICON_WIDTH_PT * 7, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
		self.toolbarPosition = ToolbarRight;
	}
	else {
		if ( point.x <= (screenSize.width / 2) ) {
			DebugLog(@"show floating left toolbar");
			viewRect = CGRectMake(point.x - 70, point.y - 140, TOOLBAR_ICON_WIDTH_PT * 3, TOOLBAR_ICON_HEIGHT_PT * 2);
			self.backBtn.frame = CGRectMake(0, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.websiteBtn.frame = CGRectMake(60, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.emailBtn.frame = CGRectMake(120, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.saveAlbumBtn.frame = CGRectMake(120, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.dropboxBtn.frame = CGRectMake(60, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.playBtn.frame = CGRectMake(0, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
            self.starBtn.frame = CGRectMake(180, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
            self.instapaperBtn.frame = CGRectMake(180, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.toolbarPosition = ToolbarLeft;
		}
		else {
			DebugLog(@"show floating right toolbar");
			viewRect = CGRectMake(point.x - 180, point.y - 140, TOOLBAR_ICON_WIDTH_PT * 4, TOOLBAR_ICON_HEIGHT_PT * 2);
            self.starBtn.frame = CGRectMake(0, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
            self.instapaperBtn.frame = CGRectMake(0, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.emailBtn.frame = CGRectMake(60, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.websiteBtn.frame = CGRectMake(120, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.backBtn.frame = CGRectMake(180, 0, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.saveAlbumBtn.frame = CGRectMake(60, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.dropboxBtn.frame = CGRectMake(120, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.playBtn.frame = CGRectMake(180, 60, TOOLBAR_ICON_WIDTH_PT, TOOLBAR_ICON_HEIGHT_PT);
			self.toolbarPosition = ToolbarRight;
		}
	}

	self.toolbarView = [[[UIView alloc] initWithFrame:viewRect] autorelease];
	self.toolbarView.backgroundColor = [UIColor clearColor];

	[self showTitles];
	[self.toolbarView addSubview:self.playBtn];
	[self.toolbarView addSubview:self.backBtn];
	[self.toolbarView addSubview:self.websiteBtn];
	[self.toolbarView addSubview:self.emailBtn];
	[self.toolbarView addSubview:self.saveAlbumBtn];
	[self.toolbarView addSubview:self.dropboxBtn];
    [self.toolbarView addSubview:self.starBtn];
    [self.toolbarView addSubview:self.instapaperBtn];
	[self.view addSubview:self.toolbarView];
	self.hudVisable = YES;
}

- (void) hideToolbar {
	[self.toolbarView removeFromSuperview];
	self.toolbarView = nil;
	[self.mainTitleButton removeFromSuperview];
	[self.subTitleButton removeFromSuperview];
	self.hudVisable = NO;
}

- (void) toggleToolbar {
	if (self.slideShowPlaying) {
		[self.slideShowTimer invalidate];
		self.slideShowPlaying = NO;
		[self.playBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_play_white" ofType:@"png"]] forState:UIControlStateNormal];
		[self.playBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_play_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
		[self displayTranslucentNotificationView:slideShowStopType];
		DebugLog(@"Slide show has stopped playing");
	}

	CGRect screenBounds;
	UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;

	if ( (interfaceOrientation == UIDeviceOrientationPortrait) || (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) ) {
		DebugLog(@"Portrait");
		screenBounds = CGRectMake(0, 0, 768, 1024);
	}
	else {
		DebugLog(@"Landscape");
		screenBounds = CGRectMake(0, 0, 1024, 768);
	}

	CGPoint rawPoint = [gestureRecognizer locationInView:self.pagingScrollView];
	CGPoint point;

	CGRect visibleBounds = self.pagingScrollView.bounds;
	int firstNeededPageIndex = floorf( CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds) );
	int idx = MAX(firstNeededPageIndex, 0);

	if (idx == 0) {
		point = rawPoint;
	}
	else {
		point.x = ( rawPoint.x - ( (screenBounds.size.width * idx) + ( (PADDING * 2) * idx ) ) );
		point.y = rawPoint.y;
	}

	if (self.hudVisable) {
		[self hideToolbar];
	}
	else {
		self.mainTitleButton.alpha = 1.0;
		self.subTitleButton.alpha = 1.0;
		[self showToolbar:point];
	}
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void) playSlideshowBtnPressed:(id) selector {
	DebugLog(@"Play slideshow btn pressed");
	self.slideShowPlaying = YES;
	[self displayTranslucentNotificationView:slideShowStartType];
	[self fadeHUD];
    [self fireNextSlide];
	self.slideShowTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(fireNextSlide) userInfo:nil repeats:YES];
}

- (void) showEmbeddedBrowserBtnPressed:(id) selector {
	PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

	if (appDelegate.currentNetworkStatus == NotReachable) {
		DebugLog(@"No network available, therefore jump to embedded browser request is cancelled.");
		return;
	}
	PicStroomEmbeddedBrowserViewController *browserController = [[PicStroomEmbeddedBrowserViewController alloc] initWithNibName:@"PicStroomEmbeddedBrowserViewController" bundle:nil];
	browserController.url = [NSURL URLWithString:self.currentPicture.entry.link];
	browserController.toolbarPosition = self.toolbarPosition;
	browserController.delegate = self;
	browserController.basicModeEnabled = NO;
	[self presentModalViewController:browserController animated:NO];
	[browserController release];
}

- (void) sendEmailBtnPressed:(id) selector {
	if (![MFMailComposeViewController canSendMail]) { // safety check (again)
		return;
	}

	MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];

	mailViewController.mailComposeDelegate = self;

	NSString *mailMessageBody;
	if ([self.currentPicture.entry.stroom.type intValue] == StroomTypeRSS) {
		[mailViewController setSubject:[NSString stringWithFormat:@"%@ (%@)", self.currentPicture.entry.title, self.currentPicture.entry.stroom.title]];
		mailMessageBody = [NSString stringWithFormat:@"<p></p><p><b>%@</b><br/>%@<br/>%@</p><p><br/><br/>---<br/>Found with <a href=\"http://www.picstroom.com/app\">PicStroom</a><br/>PicStroom is a beautiful application that makes following images from websites easy and engaging.<br/>Available in the App Store</p><br/>", self.currentPicture.entry.title ? self.currentPicture.entry.title:@"", self.currentPicture.entry.stroom.title ? self.currentPicture.entry.stroom.title:@"", self.currentPicture.entry.link ? self.currentPicture.entry.link:@""];
	}
	else {
		[mailViewController setSubject:@"Picture found with PicStroom"];
		mailMessageBody = [NSString stringWithFormat:@"<p>I want to share this picture with you.<br/><br/>---<br/>Found with <a href=\"http://www.picstroom.com/app\">PicStroom</a><br/>Follow, filter, fetch, feature foto's fast<br/>Available for free in the App Store</p><br/>",  self.currentPicture.entry.link ? self.currentPicture.entry.link:@""];
	}

	[mailViewController setMessageBody:mailMessageBody isHTML:YES];

	PicStroomFullScreenPhotoScrollView *page = [visiblePages anyObject]; // there is only one visible page at this stage
	[mailViewController addAttachmentData:UIImagePNGRepresentation(page.imageView.image) mimeType:@"image/png" fileName:@"picstroom-image.png"];

	mailViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:mailViewController animated:YES];
	[mailViewController release];
}

- (void) saveDropBoxBtnPressed:(id) selector {
	PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

	if (appDelegate.currentNetworkStatus == NotReachable) {
		DebugLog(@"No network available, therefore user dropbox save request is cancelled.");
		return;
	}
	if ([[DBSession sharedSession] isLinked]) {
		[self displayTranslucentNotificationView:dropboxNotificationType];
		NSString *rawImagePath = [[PicStroomImageProcessor currentProcessor] getRawImagePathForUUID:self.currentPicture.rawPictureUUID];
		PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
		Picture *picture = [stroomManager getPictureFromRawUUID:self.currentPicture.rawPictureUUID];
		[stroomManager release];
		NSString *targetFileName = [picture.url lastPathComponent];
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease];
		[args setObject:rawImagePath forKey:@"sourcePath"];
		[args setObject:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER] forKey:@"path"];
		[args setObject:targetFileName forKey:@"destinationPath"];
		[[PicStroomDropboxUploader currentUploader] uploadImageToDropbox:args];
	}
	else {
		PicStroomLinkDropboxViewController *linkDropboxViewController = [[PicStroomLinkDropboxViewController alloc] initWithNibName:@"PicStroomLinkDropboxViewController" bundle:nil];
		linkDropboxViewController.loadFromFullScreenPhotoView = YES;
		linkDropboxViewController.directlyLoaded = YES;
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:linkDropboxViewController];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navigationController animated:YES];
		[linkDropboxViewController release];
		[navigationController release];
	}
}

- (void) saveAlbumBtnPressed:(id) selector {
	[self displayTranslucentNotificationView:albumNotificationType];
    [FlurryAPI logEvent:FLURRY_SAVE_TO_LIBRARY];
	UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}
	                                    ];
	PicStroomFullScreenPhotoScrollView *page = [visiblePages anyObject]; // there is only one visible page at this stage
	UIImageWriteToSavedPhotosAlbum (page.imageView.image, self, nil, nil);
	[[UIApplication sharedApplication] endBackgroundTask:bgTask];
    
}

- (void) backBtnPressed:(id) selector {
	[self.parentViewController dismissModalViewControllerAnimated:NO];
	PicStroomViewController *mainController = [PicStroomViewController getCurrentController];
	[mainController.stroomTableView reloadData];
}

- (void) starBtnPressed:(id) selector {
    if(![PicStroomMetadataManager isStarredPicture:self.currentPicture]) {
        [self displayTranslucentNotificationView:starAddedType];
        [PicStroomMetadataManager starPicture:self.currentPicture];
        [PicStroomStarredPicturesManager registerPictureInStarredStroom:self.currentPicture];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_white" ofType:@"png"]] forState:UIControlStateNormal];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_starred_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    } else {
        [self displayTranslucentNotificationView:starRemovedType];
        [PicStroomMetadataManager unstarPicture:self.currentPicture];
        [PicStroomStarredPicturesManager deregisterPictureInStarredStroom:self.currentPicture];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_white" ofType:@"png"]] forState:UIControlStateNormal];
        [self.starBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_star_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    }
}

- (void) instapaperBtnPressed:(id)selector {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.currentNetworkStatus == NotReachable) {
		DebugLog(@"No network available, therefore user instapaper save request is cancelled.");
		return;
	}
    
    if([PicStroomInstapaperManager isInstapaperLinked]) {
        [self displayTranslucentNotificationView:instapaperSavedType];
        IKEngine *instapaperKit = [[IKEngine alloc] initWithDelegate:self];
        instapaperKit.OAuthToken = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_INSTAPAPER_USER_OAUTH_TOKEN];
        instapaperKit.OAuthTokenSecret = [PicStroomInstapaperManager getUsersInstapaperTokenSecret];
        
        [instapaperKit addBookmarkWithURL:[NSURL URLWithString:currentPicture.entry.link] userInfo:nil];
        [instapaperKit release];
    } else {
        PicStroomLinkInstapaperViewController *linkInstapaperViewController = [[PicStroomLinkInstapaperViewController alloc] initWithNibName:@"PicStroomLinkInstapaperViewController" bundle:nil];
        linkInstapaperViewController.loadFromFullScreenPhotoView = YES;
        linkInstapaperViewController.directlyLoaded = YES;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:linkInstapaperViewController];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navigationController animated:YES];

        [linkInstapaperViewController release];
        [navigationController release];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomEmbeddedBrowserViewControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressBackToStroomsBtn:(PicStroomEmbeddedBrowserViewController *) sender {
	DebugLog (@"didPressBackToStroomsBtn");
	[self dismissModalViewControllerAnimated:NO];
	[self dismissModalViewControllerAnimated:NO];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Slideshow

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) fadeHUD {
	[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{ self.toolbarView.alpha = 0.0;
	 }
	 completion:nil];

	[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{ self.mainTitleButton.alpha = 0.0;
	 }
	 completion:nil];

	[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{ self.subTitleButton.alpha = 0.0;
	 }
	 completion:nil];


	self.hudVisable = NO;
}

- (void) fireNextSlide {
	DebugLog(@"Fire next slide");

	NSInteger idx = [currentRawPictureUUIDs indexOfObject:self.currentPicture.rawPictureUUID];

	if (idx + 1 == [currentRawPictureUUIDs count]) { // at slideshow end
        [self displayTranslucentNotificationView:slideShowLoopType];
		[self.pagingScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
		PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
		self.currentPicture = [stroomManager getPictureFromRawUUID:[self.currentRawPictureUUIDs objectAtIndex:0]];
		[stroomManager release];
		return;
	}

	[self.pagingScrollView setContentOffset:CGPointMake( ( (idx + 1) * self.pagingScrollView.bounds.size.width ), 0 ) animated:YES];
	PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
	self.currentPicture = [stroomManager getPictureFromRawUUID:[self.currentRawPictureUUIDs objectAtIndex:idx + 1]];
	[stroomManager release];
	[self tilePages];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Mail delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) mailComposeController:(MFMailComposeViewController *) controller didFinishWithResult:(MFMailComposeResult) result error:(NSError *) error {
	[controller dismissModalViewControllerAnimated:YES];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - InstapaperKit delegates
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)engine:(IKEngine *)engine didFinishConnection:(IKURLConnection *)connection {

}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizers
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) createGestureRecognizers {
	self.gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbar)] autorelease];
	self.gestureRecognizer.numberOfTapsRequired = 1;
	[self.pagingScrollView addGestureRecognizer:self.gestureRecognizer];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Tiling and page configuration
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) jumpToStartingImageWithinStream {
	CGRect visibleBounds = self.pagingScrollView.bounds;
	CGRect startingBounds = CGRectMake(pagingScrollView.bounds.size.width * startIdx, visibleBounds.origin.y, visibleBounds.size.width, visibleBounds.size.height);

	self.pagingScrollView.bounds = startingBounds;
	self.currentPicture = [self currentVisablePicture];
}

- (void) tilePages {
	// Calculate which pages are visible
	CGRect visibleBounds = self.pagingScrollView.bounds;

	int firstNeededPageIndex = floorf( CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds) );
	int lastNeededPageIndex  = floorf( (CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds) );

	firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
	lastNeededPageIndex  = MIN(lastNeededPageIndex, [self imageCount] - 1);

	// Recycle no-longer-visible pages
	for (PicStroomFullScreenPhotoScrollView *page in visiblePages) {
		if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
			[self.recycledPages addObject:page];
			[page removeFromSuperview];
		}
	}
	[self.visiblePages minusSet:recycledPages];

	// add missing pages
	for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
			PicStroomFullScreenPhotoScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[[PicStroomFullScreenPhotoScrollView alloc] init] autorelease];
			}
			[self configurePage:page forIndex:index];
			[self.pagingScrollView addSubview:page];
			[self.visiblePages addObject:page];
		}
	}
}

- (PicStroomFullScreenPhotoScrollView *) dequeueRecycledPage {
	PicStroomFullScreenPhotoScrollView *page = [self.recycledPages anyObject];

	if (page) {
		[[page retain] autorelease];
		[self.recycledPages removeObject:page];
	}
	return page;
}

- (BOOL) isDisplayingPageForIndex:(NSUInteger) index {
	BOOL foundPage = NO;

	for (PicStroomFullScreenPhotoScrollView *page in visiblePages) {
		if (page.index == index) {
			foundPage = YES;
			break;
		}
	}
	return foundPage;
}

- (void) configurePage:(PicStroomFullScreenPhotoScrollView *) page forIndex:(NSUInteger) index {
	page.index = index;
	page.frame = [self frameForPageAtIndex:index];
	[page displayImage:[self imageAtIndex:index]];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - ScrollView delegate methods
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) scrollViewDidScroll:(UIScrollView *) scrollView {
	[self tilePages];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *) scrollView {
	self.currentPicture = [self currentVisablePicture];
	[self updateTitles];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View controller rotation methods
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
	[self calculateWillRotateToInterfaceOrientation];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
	if (self.hudVisable == YES) {
		[self hideToolbar];
	}
	[self calculateWillAnimateRotationToInterfaceOrientation];
}

- (void) calculateWillRotateToInterfaceOrientation {
	// here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
	// place to calculate the content offset that we will need in the new orientation
	CGFloat offset = self.pagingScrollView.contentOffset.x;
	CGFloat pageWidth = self.pagingScrollView.bounds.size.width;

	if (offset >= 0) {
		firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
		percentScrolledIntoFirstVisiblePage = ( offset - (firstVisiblePageIndexBeforeRotation * pageWidth) ) / pageWidth;
	}
	else {
		firstVisiblePageIndexBeforeRotation = 0;
		percentScrolledIntoFirstVisiblePage = offset / pageWidth;
	}
}

- (void) calculateWillAnimateRotationToInterfaceOrientation {
	// recalculate contentSize based on current orientation
	self.pagingScrollView.contentSize = [self contentSizeForPagingScrollView];

	// adjust frames and configuration of each visible page
	for (PicStroomFullScreenPhotoScrollView *page in visiblePages) {
		CGPoint restorePoint = [page pointToCenterAfterRotation];
		CGFloat restoreScale = [page scaleToRestoreAfterRotation];
		page.frame = [self frameForPageAtIndex:page.index];
		[page setMaxMinZoomScalesForCurrentBounds];
		[page restoreCenterPoint:restorePoint scale:restoreScale];
	}

	// adjust contentOffset to preserve page location based on values collected prior to location
	CGFloat pageWidth = self.pagingScrollView.bounds.size.width;
	CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
	self.pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Frame calculations
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGRect) frameForPagingScrollView {
	CGRect frame = [[UIScreen mainScreen] bounds];

	frame.origin.x -= PADDING;
	frame.size.width += (2 * PADDING);
	return frame;
}

- (CGRect) frameForPageAtIndex:(NSUInteger) index {
	// We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
	// landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
	// view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
	// because it has a rotation transform applied.
	CGRect bounds = pagingScrollView.bounds;
	CGRect pageFrame = bounds;

	pageFrame.size.width -= (2 * PADDING);
	pageFrame.origin.x = (bounds.size.width * index) + PADDING;
	return pageFrame;
}

- (CGSize) contentSizeForPagingScrollView {
	// We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
	CGRect bounds = pagingScrollView.bounds;

	return CGSizeMake(bounds.size.width * [self imageCount], bounds.size.height);
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image wrangling
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (Picture *) currentVisablePicture {
	CGRect visibleBounds = pagingScrollView.bounds;
	int firstNeededPageIndex = floorf( CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds) );
	int p = MAX(firstNeededPageIndex, 0);

    if (p > [self.currentRawPictureUUIDs count]-1) { // hack be here
        return nil;
    }
    
	PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
	Picture *picture = [stroomManager getPictureFromRawUUID:[self.currentRawPictureUUIDs objectAtIndex:p]];
	[stroomManager release];

	return picture;
}

- (UIImage *) imageAtIndex:(NSUInteger) index {
	return [[PicStroomImageProcessor currentProcessor] getImage:[self.currentRawPictureUUIDs objectAtIndex:index]];
}

- (NSUInteger) imageCount {
	return [self.currentRawPictureUUIDs count];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Translucent Notification Panel
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) displayTranslucentNotificationView:(translucentNotificationType) translucentNotificationType {
	CGSize screenSize = self.view.bounds.size;

	CGRect frame = CGRectMake( ( (screenSize.width / 2) - TRANSLUCENT_NOTIFICATION_VIEW_WIDTH / 2 ),
	                           ( (screenSize.height / 2) - TRANSLUCENT_NOTIFICATION_VIEW_HEIGHT / 2 ),
	                           TRANSLUCENT_NOTIFICATION_VIEW_WIDTH,
	                           TRANSLUCENT_NOTIFICATION_VIEW_HEIGHT );

	UIView *translucentView = [[UIView alloc] initWithFrame:frame];

	translucentView.backgroundColor = [UIColor blackColor];
	translucentView.alpha = 0.7;
	translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;

	UIImageView *imageView = [[UIImageView alloc] init];
	imageView.frame = CGRectMake(0, 0, 300, 300);
	if (translucentNotificationType == dropboxNotificationType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_Dropbox_no_background" ofType:@"png"]];
	}
	else if (translucentNotificationType == albumNotificationType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_Photo_library_no_background" ofType:@"png"]];
	}
	else if (translucentNotificationType == slideShowStartType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"start" ofType:@"png"]];
	}
	else if (translucentNotificationType == slideShowStopType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pause" ofType:@"png"]];
	} 
    else if (translucentNotificationType == slideShowLoopType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_return_to_start" ofType:@"png"]];
	}
    else if (translucentNotificationType == starAddedType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_starred_no_background" ofType:@"png"]];
	}
    else if (translucentNotificationType == starRemovedType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_unstarred_no_background" ofType:@"png"]];
	}
    else if (translucentNotificationType == instapaperSavedType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue-Instapaper-no-background" ofType:@"png"]];
	}
    
	[translucentView addSubview:imageView];
	[imageView release];

	[self.view addSubview:translucentView];
	[translucentView release];

	[self performSelector:@selector(fadeView:) withObject:translucentView afterDelay:0.25];
}

- (void) fadeView:(UIView *) view {
	[UIView animateWithDuration:1.0 delay:0.35 options:UIViewAnimationOptionTransitionNone animations:^{ view.alpha = 0.0;
	 }
	 completion:^(BOOL finished) { [view removeFromSuperview];
	 }
	];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *) notice {
	PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];

	if (appDelegate.currentNetworkStatus == NotReachable) {
		[websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateNormal];
		[websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
		[dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_grey" ofType:@"png"]] forState:UIControlStateNormal];
		[dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
        [instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_grey" ofType:@"png"]] forState:UIControlStateNormal];
		[instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
	}
	else if ((appDelegate.currentNetworkStatus == ReachableViaWiFi) || (appDelegate.currentNetworkStatus == ReachableViaWWAN)) {
        if([self.currentPicture.entry.stroom.type intValue] == StroomTypeDropbox) { // no browser for dropbox strooms
            [websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateNormal];
            [websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
            [self.websiteBtn removeTarget:self action:@selector(showEmbeddedBrowserBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_white" ofType:@"png"]] forState:UIControlStateNormal];
            [websiteBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_safari_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        }
		[dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_white" ofType:@"png"]] forState:UIControlStateNormal];
		[dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_dropbox_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        [instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_white" ofType:@"png"]] forState:UIControlStateNormal];
		[instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon8_instapaper_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
	}
}

@end