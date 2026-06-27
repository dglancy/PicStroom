//
//  PicStroomUnlimitedLinkView.m
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomUnlimitedLinkView.h"


@implementation PicStroomUnlimitedLinkView
@synthesize lbl1;

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        lbl1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 275, 20)];
        lbl1.backgroundColor = [UIColor clearColor];
        lbl1.text = @"+ buy unlimited Streams";
        lbl1.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
        lbl1.textColor = [UIColor colorWithRed:108.0f / 255.0f green:105.0f / 255.0f blue:104.0f / 255.0f alpha:1.0f];
        [self addSubview:lbl1];
    }
    return self;
}

- (void) dealloc {
    [lbl1 release];
    [super dealloc];
}

@end
