//
//  PicStroomFeedSummary.h
//  PicStroom
//
//  Created by Damien Glancy on 10/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWFeedParser.h"

@interface PicStroomFeedSummary : NSObject {
    NSInteger index;
    NSString *name;
    NSString *type;
    NSInteger numberOfImages;
    NSURL *url;
    FeedType feedType;
}
@property (assign) NSInteger index;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;
@property (assign) NSInteger numberOfImages;
@property (nonatomic, retain) NSURL *url;
@property (assign) FeedType feedType;

@end
