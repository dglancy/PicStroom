//
//  PicStroomFeedScanner.m
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomFeedScanner.h"
#import "PicStroomFeedSummary.h"

@implementation PicStroomFeedScanner
@synthesize summary;
@synthesize imageCounter;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -Init, Dealloc & Memory management
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [summary release];
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - RSS Feed Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (PicStroomFeedSummary *) scanRSS:(NSURL *)url withIndex:(NSInteger)index {
    self.summary = [[[PicStroomFeedSummary alloc] init] autorelease];
    self.imageCounter = 0;
    self.summary.index = index;
    self.summary.url = url;
    [self parseRSSFeedFromRSSUrl:url];
    self.summary.numberOfImages = imageCounter;
    return summary;
}

- (void) feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    self.summary.name = info.title;
    self.summary.feedType = parser.feedType;
}

- (void) feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if (item.summary) {
        NSArray *imageURLs = [self extractSuitableImagesFromRawRSSEntry:item.summary];
        self.imageCounter += [imageURLs count];
    }

    if (item.content) {
        NSArray *imageURLs = [self extractSuitableImagesFromRawRSSEntry:item.content];
        self.imageCounter += [imageURLs count];
    }
}

- (void) feedParserDidFinish:(MWFeedParser *)parser {
}

@end