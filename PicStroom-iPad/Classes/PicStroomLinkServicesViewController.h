//
//  PicStroomLinkServicesViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PicStroomDetailsViewController.h"

@interface PicStroomLinkServicesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *linkServicesTableView;
}


@property (nonatomic, retain) IBOutlet UITableView *linkServicesTableView;
@end
