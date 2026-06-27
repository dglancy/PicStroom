//
//  PicStroomManager.h
//  PicStroom
//
//  Created by Damien Glancy on 24/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PicStroomImageProcessor.h"
#import "Document.h"
#import "Stroom.h"
#import "Picture.h"
#import "Entry.h"
#import "MWFeedParser.h"

@class Stroom;
@class MWFeedParser;

@interface PicStroomManager : NSObject <MWFeedParserDelegate> {

}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data Search Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *) getAllPicturesForStroom:(NSManagedObjectID *)stroomObjectID;
- (NSArray *) getUnprocessedPicturesForStroom:(Stroom *)stroom inContext:(NSManagedObjectContext *)context;
- (Entry *) getEntryForStroom:(Stroom *)stroom withIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context;
- (Picture *) getPictureFromEntry:(Entry *)entry andPictureUrl:(NSString *)url inContext:(NSManagedObjectContext *)context;
- (NSArray *) getOldestPicturesForStroom:(Stroom *)stroom limit:(NSUInteger)limit inContext:(NSManagedObjectContext *)context;
- (NSInteger) getNumberOfNonSystemStrooms;
- (NSInteger) getNumberOfStrooms;
- (NSInteger) getNumberOfImagesInStroom:(Stroom *)stroom inContext:(NSManagedObjectContext *)context;
- (Stroom *) getStroomFromURL:(NSString *)url;
- (Stroom *) getStroomFromDropboxPath:(NSString *)path;
- (Picture *) getPictureFromRawUUID:(NSString *)uuid;
- (Picture *) getPictureFromThumbnailUUID:(NSString *)uuid;
- (void) deleteStroom:(Stroom *)stroom;
+ (Stroom *) getStarredStroom;
+ (Entry *) getStarredEntry;
- (NSArray *) getAllStrooms;
- (NSArray *) getRSSFeedsUrlFromWebUrl:(NSURL *)url;
- (NSArray *) getRSSFeedsUrlFromHTML:(NSString *)html;
- (NSArray *) getRSSFeedsUrlFromData:(NSData *)data;
- (void) parseRSSFeedFromRSSUrl:(NSURL *)url;
- (NSArray *) extractSuitableImagesFromRawRSSEntry:(NSString *)rawRSS;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data Utility Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveContextChanges;
+ (void) saveContextChangesWithContext:(NSManagedObjectContext *)context;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Http Utility Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSData *) executeRequest:(NSURL *)url;
- (NSString *) cleanUpString:(NSString *)cleanme;

@end
