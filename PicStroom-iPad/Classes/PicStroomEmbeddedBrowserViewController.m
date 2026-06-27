//
//  PicStroomEmbeddedBrowserViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 21/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>

#import "PicStroomEmbeddedBrowserViewController.h"
#import "PicStroomFullScreenPhotoViewController.h"
#import "PicStroomFeedScanner.h"
#import "PicStroomFeedSummary.h"
#import "PicStroomManager.h"
#import "PicStroomAddStroomManager.h"
#import "PicStroomSupervisor.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomDropboxUploader.h"
#import "PicStroomLinkDropboxViewController.h"
#import "PicStroomListFeedsViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomEmbeddedBrowserHelpViewController.h"
#import "PicStroomInstapaperManager.h"
#import "PicStroomLinkInstapaperViewController.h"
#import "Stroom.h"

#import "NSOperationQueue+CWSharedQueue.h"

@implementation PicStroomEmbeddedBrowserViewController
@synthesize delegate;
@synthesize justLoaded;
@synthesize basicModeEnabled;
@synthesize feedsFound;
@synthesize webViewLoads;
@synthesize webView;
@synthesize backBtn;
@synthesize forwardBtn;
@synthesize searchBtn;
@synthesize toolbar;
@synthesize url;
@synthesize urlBtn;
@synthesize doneBtn;
@synthesize stroomsStatusLabel;
@synthesize closeToStroomsBtn;
@synthesize closeBtn;
@synthesize emailBtn;
@synthesize safariBtn;
@synthesize webpageTitle;
@synthesize albumBtn;
@synthesize dropboxBtn;
@synthesize instapaperBtn;
@synthesize stroomsBtn;
@synthesize addressBar;
@synthesize addressField;
@synthesize feedPanel;
@synthesize listFeedsController;
@synthesize popoverController;
@synthesize browserActivityIndicatorView;
@synthesize toolbarPosition;
@synthesize toolbarView;
@synthesize helpController;
@synthesize feedSummaries;
@synthesize unloadedByMemoryWarning;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    webView.delegate = nil;
    [feedsFound release];
    [webView release];
    [toolbar release];
    [backBtn release];
    [forwardBtn release];
    [searchBtn release];
    [urlBtn release];
    [doneBtn release];
    [closeToStroomsBtn release];
    [closeBtn release];
    [emailBtn release];
    [safariBtn release];
    [webpageTitle release];
    [url release];
    [albumBtn release];
    [dropboxBtn release];
    [instapaperBtn release];
    [stroomsBtn release];
    [listFeedsController release];
    [popoverController release];
    [browserActivityIndicatorView release];
    [stroomsStatusLabel release];
    [helpController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [super dealloc];
    DebugLog(@"PicStroomEmbeddedBrowserController dealloc()");
}

- (void) didReceiveMemoryWarning {
    DebugLog(@"Embedded browser didReceiveMemoryWarning()");
    self.unloadedByMemoryWarning = YES;
    self.closeBtn.userInteractionEnabled = NO;
    self.closeBtn.enabled = NO;
    [super didReceiveMemoryWarning];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    
    DebugLog(@"popover list viewDidLoad()");
    
    self.justLoaded = YES;
    self.unloadedByMemoryWarning = NO;
    
    self.listFeedsController = nil;
    self.popoverController = nil;
    self.helpController = nil;
    self.webViewLoads = 0;
    self.webView.allowsInlineMediaPlayback = NO;
    self.toolbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_back_landscape" ofType:@"png"]]];
    self.webpageTitle.text = @"Web Browser - Loading";
    
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
    
    if (self.basicModeEnabled) {
        DebugLog(@"Entering basic add web stream mode");
        [self showAddressBar];
        
        self.helpController = [[[PicStroomEmbeddedBrowserHelpViewController alloc] initWithNibName:@"PicStroomEmbeddedBrowserHelpViewController" bundle:nil] autorelease];
        self.helpController.browserController = self;
        [self.webView addSubview:helpController.view];
        [self.addressField becomeFirstResponder];
    }
    
    self.backBtn.enabled = false;
    self.forwardBtn.enabled = false;
    self.emailBtn.enabled = false;
    self.stroomsBtn.selected = NO;
    self.stroomsBtn.userInteractionEnabled = NO;
    self.stroomsStatusLabel.userInteractionEnabled = NO;
    
    UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(urlBtnPressed:)] autorelease];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.webpageTitle addGestureRecognizer:gestureRecognizer];
    
    UITapGestureRecognizer *gestureRecognizer2 = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(streamsBtnPressed:)] autorelease];
    gestureRecognizer2.numberOfTapsRequired = 1;
    [self.stroomsStatusLabel addGestureRecognizer:gestureRecognizer2];
    
    if (self.toolbarPosition != ToolbarNone) {
        [self showFloatingToolbar];
    }
    
    [FlurryAPI logEvent:FLURRY_EMBD_BROWSER_LAUNCHED];
    if (self.url) {
        DebugLog(@"Browser loading url: %@", [self.url absoluteString]);
    }
}

- (void) viewDidUnload {
    webView.delegate = nil;
    webView = nil;
    backBtn = nil;
    searchBtn = nil;
    webpageTitle = nil;
    urlBtn = nil;
    doneBtn = nil;
    closeToStroomsBtn = nil;
    closeBtn = nil;
    emailBtn = nil;
    safariBtn = nil;
    [self setAlbumBtn:nil];
    [self setDropboxBtn:nil];
    [self setStroomsBtn:nil];
    self.instapaperBtn = nil;
    self.popoverController = nil;
    self.listFeedsController = nil;
    self.browserActivityIndicatorView = nil;
    [doneBtn release];
    doneBtn = nil;
    [stroomsStatusLabel release];
    stroomsStatusLabel = nil;
    helpController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [super viewDidUnload];
    DebugLog(@"PicStroomEmbeddedBrowserController viewDidUnload()");
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration      {
    if (self.popoverController && [self.popoverController isPopoverVisible]) {
        [self.popoverController dismissPopoverAnimated:NO];
    }
    
    if (self.toolbarPosition != ToolbarNone) {
        [self showFloatingToolbar];
    }
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.toolbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_back_portrait" ofType:@"png"]]];
    } else {
        self.toolbar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_back_landscape" ofType:@"png"]]];
    }
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (self.addressBar) {
            self.addressBar.frame = CGRectMake(170, 8, 340, 25);
            self.addressField.frame = CGRectMake(5, 3, self.addressBar.frame.size.width - 5, 20);
        }
    } else {
        if (self.addressBar) {
            self.addressBar.frame = CGRectMake(170, 8, 560, 25);
            self.addressField.frame = CGRectMake(5, 3, self.addressBar.frame.size.width - 5, 20);
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIWebView delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) webViewDidStartLoad:(UIWebView *)localWebView {
    self.webViewLoads++;
    
    if (![self.urlBtn isHidden]) {
        self.urlBtn.hidden = YES;
    }
    
    if ([self.popoverController isPopoverVisible]) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
    
    if (self.helpController) {
        [UIView animateWithDuration:0.75 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{ self.helpController.view.alpha = 0.0; } completion:^(BOOL finished) { [self.helpController.view removeFromSuperview]; }];
    }
    
    self.browserActivityIndicatorView.hidden = NO;
    [self.browserActivityIndicatorView startAnimating];
    
    if (!self.justLoaded) {
        self.stroomsStatusLabel.textColor = [UIColor colorWithRed:127.0 / 255.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0];
        self.stroomsStatusLabel.text = @"searching";
    }
    [self.stroomsBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_streams_white" ofType:@"png"]] forState:UIControlStateNormal];
    self.url = [self.webView.request URL];
    self.addressField.text = [[localWebView.request URL] absoluteString];
    
    [self.addressField resignFirstResponder];
}

- (void) webViewDidFinishLoad:(UIWebView *)localWebView {
    self.webViewLoads--;
    
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    
    if (self.webViewLoads > 0) {
        return;
    }
    
    DebugLog(@"Main HTML page finished loading");
    
    [self hideAddressBar];
    
    if (![self.browserActivityIndicatorView isHidden]) {
        self.browserActivityIndicatorView.hidden = YES;
    }
    
    if ([self.browserActivityIndicatorView isAnimating]) {
        [self.browserActivityIndicatorView stopAnimating];
    }
    
    if ([self.urlBtn isHidden]) {
        self.urlBtn.hidden = NO;
    }
    
    self.webpageTitle.text = [localWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    self.backBtn.enabled = self.webView.canGoBack;
    self.forwardBtn.enabled = self.webView.canGoForward;
    self.emailBtn.enabled = true;
    
    if (!self.justLoaded) {
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        NSString *html = [localWebView stringByEvaluatingJavaScriptFromString:@"document.all[0].innerHTML"];
        NSArray *feeds = [stroomManager getRSSFeedsUrlFromHTML:html];
        if ([feeds count] > 0) {
            DebugLog(@"*** FEEDS FOUND");
            // scan and filter for duplicate feeds (ie same number of images)
            self.feedSummaries = [[[NSMutableArray alloc] init] autorelease];
            for (int idx = 0; idx < [feeds count]; idx++) {
                NSURL *feedUrl = [feeds objectAtIndex:idx];
                static NSString *feedCheck = @"http://";
                NSRange match = [[feedUrl absoluteString] rangeOfString:feedCheck];
                if (match.location == NSNotFound) {
                    DebugLog(@"*** Partial feed path found ***");
                    NSString *u = [NSString stringWithFormat:@"%@/%@", [localWebView.request.URL absoluteString], [feedUrl absoluteString]];
                    feedUrl = [NSURL URLWithString:u];
                }
                
                PicStroomFeedSummary *feedSummary = [self scanRSSFeed:feedUrl withIndex:[NSNumber numberWithInt:idx]];
                BOOL similarFeedsAlreadyFound = NO;
                for (int idx2 = 0; idx2 < [self.feedSummaries count]; idx2++) {
                    PicStroomFeedSummary *scanFeedSummary = (PicStroomFeedSummary *)[self.feedSummaries objectAtIndex:idx2];
                    if (feedSummary.numberOfImages == scanFeedSummary.numberOfImages) {
                        if (feedSummary.feedType == FeedTypeAtom) {
                            [self.feedSummaries removeObjectAtIndex:idx2];
                        } else {
                            similarFeedsAlreadyFound = YES;
                        }
                    }
                }
                if (!similarFeedsAlreadyFound) {
                    [self.feedSummaries addObject:feedSummary];
                }
            }
            
            self.stroomsStatusLabel.userInteractionEnabled = YES;
            self.stroomsBtn.userInteractionEnabled = YES;
            [self.stroomsBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_streams_yellow" ofType:@"png"]] forState:UIControlStateNormal];
            self.feedsFound = feeds;
            self.stroomsBtn.selected = YES;
            if ([self.feedSummaries count] == 1) {
                self.stroomsStatusLabel.textColor = [UIColor colorWithRed:255.0 / 255.0 green:125.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
                self.stroomsStatusLabel.text = @"1 Stream found";
            } else {
                self.stroomsStatusLabel.textColor = [UIColor colorWithRed:255.0 / 255.0 green:125.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
                self.stroomsStatusLabel.text = [NSString stringWithFormat:@"%d Streams found", [self.feedSummaries count]];
            }
            [self.stroomsBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
        } else {
            DebugLog(@"**** NO FEEDS FOUND");
            self.listFeedsController = nil;
            self.listFeedsController.feedSummaries = nil;
            self.stroomsStatusLabel.textColor = [UIColor colorWithRed:127.0 / 255.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0];
            self.stroomsStatusLabel.text = @"No Streams found";
            [self.stroomsBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_streams_white" ofType:@"png"]] forState:UIControlStateNormal];
            self.stroomsBtn.userInteractionEnabled = NO;
            self.stroomsStatusLabel.userInteractionEnabled = NO;
        }
        [stroomManager release];
    }
    
    if (self.justLoaded) {
        self.justLoaded = NO;
    }
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.webViewLoads--;
    DebugLog(@"Error in UIWebView: %@", error.localizedDescription);
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction) doneBtnPressed:(id)sender {
    if (self.webView.loading) {
        [self.webView stopLoading];
    }
    
    if (self.unloadedByMemoryWarning) {
        if (self.basicModeEnabled) {
            [self dismissModalViewControllerAnimated:YES];
            return;
        } else {
            [self closeToStroomsBtnPressed:nil];
            return;
        }
    }
    
    if (self.basicModeEnabled) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:NO];
    }
}

- (void) closeToStroomsBtnPressed:(id)sender {
    if (self.webView.loading) {
        [self.webView stopLoading];
    }
    
    if (!self.basicModeEnabled) {
        [delegate didPressBackToStroomsBtn:self];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction) closeBtnPressed:(id)sender {
    DebugLog(@"Returning to picture view");
    if (self.webView.loading) {
        [self.webView stopLoading];
    }
    [self dismissModalViewControllerAnimated:NO];
}

- (IBAction) backBtnPressed:(id)sender {
    [webView goBack];
}

- (IBAction) forwardBtnPressed:(id)sender {
    [webView goForward];
}

- (IBAction) searchBtnPressed:(id)sender {
    DebugLog(@"search btn pressed");
    if (self.webView.loading) {
        [self.webView stopLoading];
    }
    self.webpageTitle.text = @"Google";
    
    self.url = [NSURL URLWithString:@"http://www.google.com"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (IBAction) urlBtnPressed:(id)sender {
    if (self.addressBar) {
        [self.addressBar removeFromSuperview];
        self.addressBar = nil;
        [self.addressField removeFromSuperview];
        self.addressField = nil;
        self.webpageTitle.hidden = NO;
    } else {
        self.webpageTitle.hidden = YES;
        if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            self.addressBar = [[[UIView alloc] initWithFrame:CGRectMake(170, 8, 340, 25)] autorelease];
            self.addressBar.alpha = 0.0f;
        } else {
            self.addressBar = [[[UIView alloc] initWithFrame:CGRectMake(170, 8, 560, 25)] autorelease];
            self.addressBar.alpha = 0.0f;
        }
        [UIView animateWithDuration:0.4 animations:^{
            self.addressBar.alpha = 1.0f;
        }];
        self.addressField = [[[UITextField alloc] initWithFrame:CGRectMake(5, 3, self.addressBar.frame.size.width - 5, 20)] autorelease];
        self.addressField.font = [UIFont fontWithName:STANDARD_FONT size:14.0];
        self.addressField.textColor = [UIColor colorWithRed:75.0 / 255.0 green:137.0 / 255.0 blue:208.0 / 255.0 alpha:1.0];
        if ([[self.webView.request URL] absoluteString]) {
            self.addressField.text = [[self.webView.request URL] absoluteString];
        } else {
            self.addressField.text = BLANK_STRING;
        }
        self.addressField.keyboardType = UIKeyboardTypeURL;
        self.addressField.returnKeyType = UIReturnKeyGo;
        self.addressField.delegate = self;
        self.addressField.clearButtonMode = UITextFieldViewModeAlways;
        self.addressField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        self.addressBar.backgroundColor = [UIColor whiteColor];
        self.addressBar.layer.cornerRadius = 4.0f;
        [self.addressBar addSubview:self.addressField];
        [self.toolbar addSubview:self.addressBar];
    }
}

- (IBAction) emailBtnPressed:(id)sender {
    if (![self.webView.request URL]) {
        return;
    }
    
    if (![MFMailComposeViewController canSendMail]) { //safety check (again)
        return;
    }
    
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    mailViewController.mailComposeDelegate = self;
    NSString *mailMessageBody = nil;
    
    [mailViewController setSubject:@"Sending you a website link with PicStroom"];
    mailMessageBody = [NSString stringWithFormat:@"<p>I want to share this website link with you.<br/><a href=\"%@\">%@</a><br/><br/>---<br/>Found with <a href=\"http://www.picstroom.com/app\">PicStroom</a><br/>Follow, filter, fetch, feature foto's fast<br/>Available for free in the App Store</p><br/>",  [[self.webView.request URL] absoluteURL], [[self.webView.request URL] absoluteURL]];
    
    [mailViewController setMessageBody:mailMessageBody isHTML:YES];
    [mailViewController addAttachmentData:UIImagePNGRepresentation([self grabScreenshot]) mimeType:@"image/png" fileName:@"picstroom-webpage-screenshot.png"];
    mailViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:mailViewController animated:YES];
    
    [mailViewController release];
}

- (IBAction) safariBtnPressed:(id)sender {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"No network available, therefore jump to safari request is cancelled.");
        return;
    }
    
    if (!url) {
        return;
    }
    
    DebugLog(@"Launching to Safari");
    [[UIApplication sharedApplication] openURL:[self.webView.request URL]];
}

- (IBAction) albumBtnPressed:(id)sender {
    DebugLog(@"album btn pressed");
    
    if (!url) {
        return;
    }
    
    [self displayTranslucentNotificationView:albumNotificationType];
    [FlurryAPI logEvent:FLURRY_SAVE_TO_LIBRARY];
    UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    
    UIImageWriteToSavedPhotosAlbum ([self grabScreenshot], self, nil, nil);
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
}

- (IBAction) dropboxBtnPressed:(id)sender {
    DebugLog (@"dropbox btn pressed");
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog (@"No network available, therefore user dropbox save request is cancelled.");
        return;
    }
    
    if (!url) {
        return;
    }
    
    if ([[DBSession sharedSession] isLinked]) {
        [self displayTranslucentNotificationView:dropboxNotificationType];
        UIImage *screenshot = [self grabScreenshot];
        NSNumber *randomNumber = [NSNumber numberWithInt:arc4random() % INT_MAX];
        NSString *tempFileName = [[PicStroomImageProcessor currentProcessor] createTempImageOnDiskFromImage:screenshot withFilename:[NSString stringWithFormat:@"screenshot-%@.png", [randomNumber stringValue]]];
        
        NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease];
        [args setObject:tempFileName forKey:@"sourcePath"];
        [args setObject:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER] forKey:@"path"];
        [args setObject:tempFileName forKey:@"destinationPath"];
        [[PicStroomDropboxUploader currentUploader] uploadImageToDropbox:args];
    } else {
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

- (IBAction) instapaperBtnPressed:(id)sender {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.currentNetworkStatus == NotReachable) {
		DebugLog(@"No network available, therefore user instapaper save request is cancelled.");
		return;
	}
    
    if (!url) {
        return;
    }
    
    if([PicStroomInstapaperManager isInstapaperLinked]) {        
        [self displayTranslucentNotificationView:instapaperSavedType];
        IKEngine *instapaperKit = [[IKEngine alloc] initWithDelegate:self];
        instapaperKit.OAuthToken = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_INSTAPAPER_USER_OAUTH_TOKEN];
        instapaperKit.OAuthTokenSecret = [PicStroomInstapaperManager getUsersInstapaperTokenSecret];
        
        [instapaperKit addBookmarkWithURL:url userInfo:nil];
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

- (IBAction) streamsBtnPressed:(id)sender {
    DebugLog(@"streams btn pressed");
    
    self.listFeedsController = [[[PicStroomListFeedsViewController alloc] initWithNibName:@"PicStroomListFeedsViewController" bundle:nil] autorelease];
    self.listFeedsController.delegate = self;
    self.listFeedsController.feedSummaries = self.feedSummaries;
    self.listFeedsController.contentSizeForViewInPopover = CGSizeMake(350.0, 100 + (50 *[self.feedSummaries count]));
    self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:self.listFeedsController] autorelease];
    self.popoverController.delegate = self;
    
    if(self.stroomsBtn!=nil && self.stroomsBtn.window!=nil) {
        [self.popoverController presentPopoverFromRect:self.stroomsBtn.bounds inView:self.stroomsBtn permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Toolbar
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showFloatingToolbar {
    CGRect screenBounds;
    
    UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
    
    if ((interfaceOrientation == UIDeviceOrientationPortrait) || (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)) {
        DebugLog(@"Portrait");
        screenBounds = CGRectMake(0, 0, 768, 1024);
    } else {
        DebugLog(@"Landscape");
        screenBounds = CGRectMake(0, 0, 1024, 768);
    }
    
    if (self.toolbarView) {
        [self.toolbarView removeFromSuperview];
        self.toolbarView = nil;
    }
    
    if (self.toolbarPosition == ToolbarLeft) {
        self.toolbarView = [[[UIView alloc] initWithFrame:CGRectMake(0, screenBounds.size.height - 301, 51, 302)] autorelease];
        self.toolbarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_left" ofType:@"png"]]];
        self.closeToStroomsBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)] autorelease];
        //self.closeBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 50, 50, 50)] autorelease];
        self.safariBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 50, 50, 50)] autorelease];
        self.emailBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 100, 50, 50)] autorelease];
        self.albumBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 150, 50, 50)] autorelease];
        self.instapaperBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 200, 50, 50)] autorelease];
        self.dropboxBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 250, 50, 50)] autorelease];
    } else if (self.toolbarPosition == ToolbarRight) {
        toolbarView = [[UIView alloc] initWithFrame:CGRectMake(screenBounds.size.width - 51, screenBounds.size.height - 301, 51, 302)];
        self.toolbarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_right" ofType:@"png"]]];
        self.closeToStroomsBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)] autorelease];
        //self.closeBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 50, 50, 50)] autorelease];
        self.safariBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 50, 50, 50)] autorelease];
        self.emailBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 100, 50, 50)] autorelease];
        self.albumBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 150, 50, 50)] autorelease];
        self.instapaperBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 200, 50, 50)] autorelease];
        self.dropboxBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 250, 50, 50)] autorelease];
    } else {
        toolbarView = [[UIView alloc] initWithFrame:CGRectMake((screenBounds.size.width / 2) - (302 / 2), screenBounds.size.height - 51, 302, 51)];
        self.toolbarView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_bottom" ofType:@"png"]]];
        self.closeToStroomsBtn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)] autorelease];
        //self.closeBtn = [[[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)] autorelease];
        self.safariBtn = [[[UIButton alloc] initWithFrame:CGRectMake(50, 0, 50, 50)] autorelease];
        self.emailBtn = [[[UIButton alloc] initWithFrame:CGRectMake(100, 0, 50, 50)] autorelease];
        self.albumBtn = [[[UIButton alloc] initWithFrame:CGRectMake(150, 0, 50, 50)] autorelease];
        self.instapaperBtn = [[[UIButton alloc] initWithFrame:CGRectMake(200, 0, 50, 50)] autorelease];
        self.dropboxBtn = [[[UIButton alloc] initWithFrame:CGRectMake(250, 0, 50, 50)] autorelease];
    }
    toolbarView.opaque = NO;
    [[self.toolbarView layer] setOpaque:NO];
    
    [self.closeToStroomsBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_overview_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.closeToStroomsBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_overview_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.closeToStroomsBtn addTarget:self action:@selector(closeToStroomsBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.closeBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_detail_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.closeBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_detail_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.closeBtn addTarget:self action:@selector(closeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.safariBtn addTarget:self action:@selector(safariBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if([MFMailComposeViewController canSendMail]) {
        [self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_mail_white" ofType:@"png"]] forState:UIControlStateNormal];
        [self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_mail_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        [self.emailBtn addTarget:self action:@selector(emailBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.emailBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_mail_grey" ofType:@"png"]] forState:UIControlStateNormal];
    }
    
    [self.albumBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_library_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.albumBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_library_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.albumBtn addTarget:self action:@selector(albumBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.dropboxBtn addTarget:self action:@selector(dropboxBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_instapaper_white" ofType:@"png"]] forState:UIControlStateNormal];
    [self.instapaperBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_instapaper_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    [self.instapaperBtn addTarget:self action:@selector(instapaperBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.toolbarView addSubview:self.closeToStroomsBtn];
    [self.toolbarView addSubview:self.closeBtn];
    [self.toolbarView addSubview:self.safariBtn];
    [self.toolbarView addSubview:self.emailBtn];
    [self.toolbarView addSubview:self.albumBtn];
    [self.toolbarView addSubview:self.dropboxBtn];
    [self.toolbarView addSubview:self.instapaperBtn];
    
    [self.view addSubview:self.toolbarView];
}

- (void) showAddressBar {
    if (!self.addressBar) {
        [self.urlBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) hideAddressBar {
    if (self.addressBar) {
        [self.urlBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Address Field delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    NSString *rawEnteredURL = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    static NSString *checkForFeedURL1 = @"feed";
    static NSString *checkForFeedURL2 = @".xml";
    NSRange match1 = [rawEnteredURL rangeOfString:checkForFeedURL1];
    NSRange match2 = [rawEnteredURL rangeOfString:checkForFeedURL2];
    
    if ((match1.location != NSNotFound) || (match2.location != NSNotFound)) { // its a direct feed url
        // feed:// is found
        DebugLog(@"Adding a stroom from a direct feed url");
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        Stroom *searchStroom = [stroomManager getStroomFromURL:rawEnteredURL];
        [stroomManager release];
        if (searchStroom) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Already Added" message:@"You have already added this Stream" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            [alertView release];
            return NO;
        } else {
            // just grab it and save and move on....
            PicStroomAddStroomManager *addStroomManager = [[PicStroomAddStroomManager alloc] init];
            Stroom *stroom = [addStroomManager addStroomRSS:[NSURL URLWithString:textField.text]];
            [addStroomManager release];
            if (!stroom) {
                [[[[UIAlertView alloc] initWithTitle:@"Invalid Web Stroom" message:@"The web Stream you added didn't load or have a valid address. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
                return NO;
            }
            PicStroomSupervisor *stroomSupervisor = [[PicStroomSupervisor alloc] init];
            stroom.stroomSupervisor = stroomSupervisor;
            stroomSupervisor.currentState = StroomStateNew;
            stroomSupervisor.stroom = stroom;
            PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
            [mainViewController.stroomSupervisors addObject:stroomSupervisor];
            [stroomSupervisor release];
            [mainViewController.stroomTableView beginUpdates];
            [mainViewController.stroomTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[mainViewController.stroomSupervisors count] - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
            if ([mainViewController.stroomSupervisors count] <= TARGET_NUM_OF_STROOMS_ON_SCREEN) {
                [mainViewController.stroomTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:TARGET_NUM_OF_STROOMS_ON_SCREEN - ([mainViewController.stroomSupervisors count]) inSection:3]] withRowAnimation:UITableViewRowAnimationTop];
            }
            [mainViewController.stroomTableView endUpdates];
            [stroomSupervisor performSelectorInBackgroundQueue:@selector(startSyncInBackgroundQueue) withObject:nil];
            
            
            [[[[UIAlertView alloc] initWithTitle:@"Direct Feed Added" message:[NSString stringWithFormat:@"You have added %@", textField.text] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
                        
            if (self.basicModeEnabled) {
                [self dismissModalViewControllerAnimated:YES];
            }
            
            return YES;
        }
    }
    
    // check if http:// is in front of string.
    static NSString *check3 = @"http://";
    NSRange match3 = [rawEnteredURL rangeOfString:check3];
    if (match3.location == NSNotFound) {
        rawEnteredURL = [NSString stringWithFormat:@"http://%@", rawEnteredURL];
    }
    
    self.url = [NSURL URLWithString:rawEnteredURL];
    self.addressField.text = rawEnteredURL;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    [self.addressField resignFirstResponder];
    self.justLoaded = NO;
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Popover delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    DebugLog(@"Popover dismissed");
    self.stroomsBtn.selected = NO;
    
    if ([self.listFeedsController.selectedIdx count] > 0) {
        UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        BOOL newStroomAdded = NO;
        for (NSInteger i = 0; i < [self.listFeedsController.selectedIdx count]; i++) {
            NSNumber *idx = [self.listFeedsController.selectedIdx objectAtIndex:i];
            PicStroomFeedSummary *summary = [self.listFeedsController.feedSummaries objectAtIndex:[idx unsignedIntValue]];
            
            PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
            Stroom *searchStroom = [stroomManager getStroomFromURL:[summary.url absoluteString]];
            [stroomManager release];
            
            if (!searchStroom) {
                PicStroomAddStroomManager *addStroomManager = [[PicStroomAddStroomManager alloc] init];
                Stroom *stroom = [addStroomManager addStroomRSS:summary.url];
                [addStroomManager release];
                PicStroomSupervisor *stroomSupervisor = [[PicStroomSupervisor alloc] init];
                stroom.stroomSupervisor = stroomSupervisor;
                stroomSupervisor.currentState = StroomStateNew;
                stroomSupervisor.stroom = stroom;
                PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
                [mainViewController.stroomSupervisors addObject:stroomSupervisor];
                [stroomSupervisor release];
                [mainViewController.stroomTableView beginUpdates];
                [mainViewController.stroomTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[mainViewController.stroomSupervisors count] - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
                if ([mainViewController.stroomSupervisors count] <= TARGET_NUM_OF_STROOMS_ON_SCREEN) {
                    [mainViewController.stroomTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:TARGET_NUM_OF_STROOMS_ON_SCREEN - ([mainViewController.stroomSupervisors count]) inSection:3]] withRowAnimation:UITableViewRowAnimationTop];
                }
                [mainViewController.stroomTableView endUpdates];
                newStroomAdded = YES;
                
                [stroomSupervisor performSelectorInBackgroundQueue:@selector(startSyncInBackgroundQueue) withObject:nil];
            }
        }
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        self.popoverController = nil;
        self.listFeedsController = nil;
        
        if (newStroomAdded) {
            [self displayTranslucentNotificationView:streamAddedNotificationType];
            
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomListFeedsViewControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDoneBtn:(PicStroomListFeedsViewController *)sender {
    [self.popoverController dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:self.popoverController];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Mail delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Grab screenshot
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIImage *) grabScreenshot {
    UIGraphicsBeginImageContext(self.webView.frame.size);
    [self.webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *webViewScreenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return webViewScreenshot;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Site scanning functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (PicStroomFeedSummary *) scanRSSFeed:(NSURL *)rssURL withIndex:(NSNumber *)index {
    NSInteger idx = [index intValue];
    PicStroomFeedScanner *scanner = [[[PicStroomFeedScanner alloc] init] autorelease];
    PicStroomFeedSummary *feedSummary = [scanner scanRSS:rssURL withIndex:idx];
    
    return feedSummary;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Translucent Notification Panel
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) displayTranslucentNotificationView:(translucentNotificationType)translucentNotificationType {
    CGSize screenSize = self.view.bounds.size;
    
    CGRect frame = CGRectMake(((screenSize.width / 2) - TRANSLUCENT_NOTIFICATION_VIEW_WIDTH / 2),
                              ((screenSize.height / 2) - TRANSLUCENT_NOTIFICATION_VIEW_HEIGHT / 2),
                              TRANSLUCENT_NOTIFICATION_VIEW_WIDTH,
                              TRANSLUCENT_NOTIFICATION_VIEW_HEIGHT);
    
    UIView *translucentView = [[UIView alloc] initWithFrame:frame];
    
    translucentView.backgroundColor = [UIColor blackColor];
    translucentView.alpha = 0.7;
    translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, 300, 300);
    if (translucentNotificationType == dropboxNotificationType) {
        imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_Dropbox_no_background" ofType:@"png"]];
    } else if (translucentNotificationType == albumNotificationType) {
        imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_Photo_library_no_background" ofType:@"png"]];
    } else if (translucentNotificationType == streamAddedNotificationType) {
        imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue_added_no_background" ofType:@"png"]];
    } else if (translucentNotificationType == instapaperSavedType) {
		imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dialogue-Instapaper-no-background" ofType:@"png"]];
	}
    [translucentView addSubview:imageView];
    [imageView release];
    
    [self.view addSubview:translucentView];
    [translucentView release];
    
    [self performSelector:@selector(fadeView:) withObject:translucentView afterDelay:0.35];
}

- (void) fadeView:(UIView *)view {
    [UIView animateWithDuration:1.0 delay:0.35 options:UIViewAnimationOptionTransitionNone animations:^{ view.alpha = 0.0; } completion:^(BOOL finished) { [view removeFromSuperview]; }];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reachability
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleNetworkChange:(NSNotification *)notice {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.currentNetworkStatus = [appDelegate.reachability currentReachabilityStatus];
    
    if (appDelegate.currentNetworkStatus == NotReachable) {
        [safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_grey" ofType:@"png"]] forState:UIControlStateNormal];
        [safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
        [dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_grey" ofType:@"png"]] forState:UIControlStateNormal];
        [dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_grey" ofType:@"png"]] forState:UIControlStateHighlighted];
    } else if ((appDelegate.currentNetworkStatus == ReachableViaWiFi) || (appDelegate.currentNetworkStatus == ReachableViaWWAN)) {
        [safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_white" ofType:@"png"]] forState:UIControlStateNormal];
        [safariBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_safari_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
        [dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_white" ofType:@"png"]] forState:UIControlStateNormal];
        [dropboxBtn setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"browse_dropbox_yellow" ofType:@"png"]] forState:UIControlStateHighlighted];
    }
}
@end