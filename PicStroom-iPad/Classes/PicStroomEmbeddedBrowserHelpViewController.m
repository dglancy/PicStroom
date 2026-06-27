//
//  PicStroomEmbeddedBrowserHelpViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 02/05/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomEmbeddedBrowserHelpViewController.h"
#import "PicStroomEmbeddedBrowserViewController.h"
#import "PicStroomGalleryController.h"
#import "PicStroomAppDelegate.h"

@implementation PicStroomEmbeddedBrowserHelpViewController
@synthesize galleryLinkBtn;
@synthesize browserController;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    [galleryLinkBtn release];
    [browserController release];
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidUnload {
    [self setGalleryLinkBtn:nil];
    self.browserController = nil;
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction) galleryLinkBtnPressed:(id)sender {
    DebugLog(@"Gallery link btn pressed");
    [self dismissModalViewControllerAnimated:YES];
    [self.browserController.addressField resignFirstResponder];
    [self resignFirstResponder];
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.currentNetworkStatus == NotReachable) {
        [[[[UIAlertView alloc] initWithTitle:@"No Network Available" message:@"You need an active network connection to browse the gallery." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    } else {
        PicStroomGalleryController *galleryViewController = [[PicStroomGalleryController alloc] initWithNibName:@"PicStroomGalleryController" bundle:nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:galleryViewController];
        galleryViewController.delegate = self;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [galleryViewController release];
        [navigationController release];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomGalleryControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressGalleryDoneBtn:(PicStroomGalleryController *)controller {
    [browserController performSelector:@selector(doneBtnPressed:) withObject:nil afterDelay:1.5];
}

@end