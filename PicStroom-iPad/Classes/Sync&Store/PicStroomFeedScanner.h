//
//  PicStroomFeedScanner.h
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PicStroomManager.h"
#import "MWFeedParser.h"

@class PicStroomFeedSummary;

@interface PicStroomFeedScanner : PicStroomManager <MWFeedParserDelegate> {
    PicStroomFeedSummary *summary;
    NSInteger imageCounter;
}
@property (nonatomic, retain) PicStroomFeedSummary *summary;
@property (assign) NSInteger imageCounter;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - RSS Feed Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (PicStroomFeedSummary *) scanRSS:(NSURL *)url withIndex:(NSInteger)index;

@end