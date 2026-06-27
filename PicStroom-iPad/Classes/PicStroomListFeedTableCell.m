//
//  PicStroomListFeedTableCell.m
//  PicStroom
//
//  Created by Damien Glancy on 30/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomListFeedTableCell.h"


@implementation PicStroomListFeedTableCell
@synthesize cellView;
@synthesize imageView;
@synthesize titleLabel;
@synthesize feedSummaryLabel;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) dealloc {
    [cellView release];
    [imageView release];
    [titleLabel release];
    [feedSummaryLabel release];
    [super dealloc];
}

@end