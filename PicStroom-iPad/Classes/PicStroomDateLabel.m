//
//  PicStroomDateLabel.m
//  PicStroom
//
//  Created by Damien Glancy on 12/06/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomDateLabel.h"


@implementation PicStroomDateLabel

- (void) dealloc {
    [super dealloc];
}

- (void) drawTextInRect:(CGRect)rect {
    CGSize myShadowOffset = CGSizeMake(2, 2);
    float myColorValues[] = { 0, 0, 0, 5.0 };
    
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(myContext);
    
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);
    CGContextSetShadowWithColor(myContext, myShadowOffset, 1, myColor);
    
    [super drawTextInRect:rect];
    
    CGColorRelease(myColor);
    CGColorSpaceRelease(myColorSpace);
    
    CGContextRestoreGState(myContext);
}

@end
