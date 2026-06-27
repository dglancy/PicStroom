//
//  PicStroomAboutBoxViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "PicStroomAboutBoxViewController.h"
#import "PicStroomAppDelegate.h"
#import "gitversion.h"

@implementation PicStroomAboutBoxViewController
@synthesize buildNumber;
@synthesize emailLink;
@synthesize websiteLink;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [buildNumber release];
    [emailLink release];
    [websiteLink release];
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"About PicStroom";
    self.buildNumber.text = [NSString stringWithFormat:@"Release %@ GitHub %@", PICSTROOM_VERSION, kGitHubCommit];
    [FlurryAPI logEvent:FLURRY_ABOUT_BOX_DISPLAYED];
}

- (void) viewDidUnload {
    [buildNumber release];
    buildNumber = nil;
    [emailLink release];
    emailLink = nil;
    [emailLink release];
    emailLink = nil;
    [websiteLink release];
    websiteLink = nil;
    [super viewDidUnload];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction) emailLinkPressed:(id)sender {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];

    mailViewController.mailComposeDelegate = self;
    [mailViewController setSubject:@"Hi guys!"];
    [mailViewController setToRecipients:[NSArray arrayWithObject:@"hi@picstroom.com"]];

    mailViewController.modalTransitionStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:mailViewController animated:YES];
    [mailViewController release];
}

- (IBAction) websiteLinkPressed:(id)sender {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"No network available, therefore jump to safari request is cancelled.");
        return;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.picstroom.com"]];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Mail delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}

@end