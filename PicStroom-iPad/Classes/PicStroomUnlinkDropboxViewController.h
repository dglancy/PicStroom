//
//  PicStroomUnlinkDropboxViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PicStroomUnlinkDropboxViewController : UITableViewController <UIAlertViewDelegate> {

    UITableView *unlinkDropboxTableView;
}
@property (nonatomic, retain) IBOutlet UITableView *unlinkDropboxTableView;

@end
