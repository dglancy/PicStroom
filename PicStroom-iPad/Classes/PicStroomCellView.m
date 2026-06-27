//
//  PicStroomCellView.m
//  PicStroom
//
//  Created by Damien Glancy on 17/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomCellView.h"


@implementation PicStroomCellView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) drawRect:(CGRect)rect { // this being blank causes a black line where I want it; why? who knows!
}


- (void) dealloc {
    [super dealloc];
}

@end
