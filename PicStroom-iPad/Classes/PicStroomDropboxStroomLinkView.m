//
//  PicStroomDropboxStroomLinkView.m
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomDropboxStroomLinkView.h"


@implementation PicStroomDropboxStroomLinkView
@synthesize lbl1, lbl2;
@synthesize imageView;

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        lbl1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        lbl1.backgroundColor = [UIColor clearColor];
        lbl1.text = @"+ add";
        lbl1.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
        lbl1.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
        [self addSubview:lbl1];

        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(43, 4, 15, 15)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_dropbox_50p" ofType:@"png"]];
        [self addSubview:imageView];

        lbl2 = [[UILabel alloc] initWithFrame:CGRectMake(62, 0, 115, 20)];
        lbl2.backgroundColor = [UIColor clearColor];
        lbl2.text = @"Dropbox folder";
        lbl2.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
        lbl2.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
        [self addSubview:lbl2];

    }
    return self;
}

- (void) dealloc {
    [lbl1 release];
    [lbl2 release];
    [imageView release];
    [super dealloc];
}

@end
