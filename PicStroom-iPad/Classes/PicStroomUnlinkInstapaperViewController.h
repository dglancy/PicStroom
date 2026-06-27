//
//  PicStroomUnlinkInstapaperViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PicStroomUnlinkInstapaperViewController : UIViewController <UIAlertViewDelegate> {
    UITableView *unlinkInstapaperTableView;
}

@property (nonatomic, retain) IBOutlet UITableView *unlinkInstapaperTableView;

@end
