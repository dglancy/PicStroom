//
//  PicStroomThumbnailButton.m
//  PicStroom
//
//  Created by Damien Glancy on 02/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomThumbnailButton.h"
#import "PicStroomSupervisor.h"

@implementation PicStroomThumbnailButton
@synthesize stroomSupervisor;
@synthesize index;
@synthesize dayLabel;
@synthesize monthLabel;

- (void) dealloc {
    DebugLog(@"thumb dealloc()");
    [dayLabel release];
    [monthLabel release];
    [super dealloc];
}

@end
