//
//  PicStroomAboutBoxViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface PicStroomAboutBoxViewController : UIViewController <MFMailComposeViewControllerDelegate> {
    IBOutlet UILabel *buildNumber;
    IBOutlet UIButton *emailLink;
    IBOutlet UIButton *websiteLink;
}
@property (nonatomic, retain) IBOutlet UILabel *buildNumber;
@property (nonatomic, retain) IBOutlet UIButton *emailLink;
@property (nonatomic, retain) IBOutlet UIButton *websiteLink;

- (IBAction) emailLinkPressed:(id)sender;
- (IBAction) websiteLinkPressed:(id)sender;

@end
