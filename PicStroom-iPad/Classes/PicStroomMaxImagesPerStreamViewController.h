//
//  PicStroomMaxImagesPerStreamViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 27/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PicStroomMaxImagesPerStreamViewController : UIViewController {
    UITableView *maxImagesTableView;
}


@property (nonatomic, retain) IBOutlet UITableView *maxImagesTableView;
@end
