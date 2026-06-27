//
//  PicStroomEmbeddedBrowserHelpViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 02/05/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PicStroomGalleryController.h"

@class PicStroomEmbeddedBrowserViewController;

@interface PicStroomEmbeddedBrowserHelpViewController : UIViewController<PicStroomGalleryControllerDelegate> {

    UIButton *galleryLinkBtn;
    PicStroomEmbeddedBrowserViewController *browserController;
}
@property (nonatomic, retain) IBOutlet UIButton *galleryLinkBtn;
@property (nonatomic, retain) PicStroomEmbeddedBrowserViewController *browserController;

- (IBAction) galleryLinkBtnPressed:(id)sender;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomGalleryControllerDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressGalleryDoneBtn:(PicStroomGalleryController *)controller;

@end