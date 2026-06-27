//
//  PicStroomFeedSummary.m
//  PicStroom
//
//  Created by Damien Glancy on 10/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomFeedSummary.h"

@implementation PicStroomFeedSummary
@synthesize index;
@synthesize name;
@synthesize type;
@synthesize numberOfImages;
@synthesize url;
@synthesize feedType;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -Init, Dealloc & Memory management
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [name release];
    [type release];
    [url release];
    [super dealloc];
}

@end
