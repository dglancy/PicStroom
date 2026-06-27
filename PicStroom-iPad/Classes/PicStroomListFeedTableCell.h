//
//  PicStroomListFeedTableCell.h
//  PicStroom
//
//  Created by Damien Glancy on 30/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PicStroomListFeedTableCell : UITableViewCell {
    UIView *cellView;
    UIImageView *imageView;
    UILabel *titleLabel;
    UILabel *feedSummaryLabel;
}
@property (nonatomic, retain) UIView *cellView;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *feedSummaryLabel;

@end