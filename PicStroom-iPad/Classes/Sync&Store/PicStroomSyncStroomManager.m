//
//  PicStroomUpdateStroomManager.m
//  PicStroom
//
//  Created by Damien Glancy on 25/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <ImageIO/ImageIO.h>

#import "PicStroomSyncStroomManager.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomSupervisor.h"
#import "PicStroomMetadataManager.h"

#import "NSNotificationCenter+NSNotificationCenterAdditions.h"
#import "ASIHTTPRequest.h"
#import "DBRestClient.h"
#import "DBMetadata.h"

#import "Stroom.h"
#import "Entry.h"
#import "Picture.h"

@implementation PicStroomSyncStroomManager

@synthesize stroom;
@synthesize context;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) init {
    if ((self = [super init])) {
        isCancelled = NO;
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:context];
    if (restClient != nil) {
        [restClient release];
    }
    [context release];
    DebugLog(@"Stroom Sync Manager dealloc()");
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stroom update functions (always called in background thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateStroom:(NSManagedObjectID *)stroomObjectID {
    if (self.stroom.stroomSupervisor.currentState == StroomStateNewUpdating || self.stroom.stroomSupervisor.currentState == StroomStateUpdating) {
        DebugLog(@"Stroom %@ is already syncing", self.stroom.title);
        return;
    }

    isCancelled = NO;

    NSNumber *bytesAvailable = [[PicStroomImageProcessor currentProcessor] calculateAvailableDiskSpace];
    if ([bytesAvailable floatValue] < MIN_FREE_DISK_STORAGE_IN_BYTES) {
        DebugLog(@"Not syncing due to not enough disk storage available");
        [FlurryAPI logEvent:FLURRY_NO_DISK_STORAGE_STATE_DETECTED];
        return;
    }

    if (!context) {
        context = [[NSManagedObjectContext alloc] init];
        [context setUndoManager:nil]; // nil undo manager
        [context setStalenessInterval:0.0];
        [context setPersistentStoreCoordinator:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator]];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeContextChanges:) name:NSManagedObjectContextDidSaveNotification object:context];
    }

    self.stroom = (Stroom *)[context objectWithID:stroomObjectID];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_START_STROOM object:[stroom objectID]];
    
    if ([stroom.type intValue] == StroomTypeRSS) {
        [self updateStroomRSS];
    } else if ([stroom.type intValue] == StroomTypeDropbox) {
        [self updateStroomDropbox];
    }
    [FlurryAPI logEvent:FLURRY_SYNC_STROOM];
    [context reset];
}

- (void) purgeExcessImagesFromStroom:(NSUInteger)imageCount withUserDefaultMaxImagesPerStroom:(NSUInteger)userDefaultMaxImagesPerStroom {    
    NSUInteger numberOfImagesToPurge = imageCount - userDefaultMaxImagesPerStroom;
    DebugLog(@"Purging %d images from Stroom: %@", numberOfImagesToPurge, stroom.title);
    
    NSArray *imagesToPurge = [self getOldestPicturesForStroom:self.stroom limit:numberOfImagesToPurge inContext:self.context];
    
    for(Picture *picture in imagesToPurge) {
        if (![PicStroomMetadataManager isStarredPicture:picture]) {
            picture.purged = [NSNumber numberWithBool:YES];
            picture.blocked = [NSNumber numberWithBool:YES];
            [[PicStroomImageProcessor currentProcessor] deleteImageFromDisk:picture.rawPictureUUID];
            [[PicStroomImageProcessor currentProcessor] deleteThumbnailFromDisk:picture.thumbnailUUID];        
            
            NSError *error;
            if (![context save:&error]) {
                DebugLog(@"Whoops, couldn't save purged: %@", [error localizedDescription]);
            } else {
                DebugLog(@"Purged Picture from URL %@ from storage", picture.url);
            }
        }
    }
}

- (void) updateStroomDropbox {
    DebugLog(@"Updating dropbox folder: %@", stroom.dropboxPath);
    DBMetadata *metadata = [[self restClient] loadMetadataSync:stroom.dropboxPath withHash:nil];

    NSSortDescriptor *sorter1 = [[NSSortDescriptor alloc] initWithKey:@"lastModifiedDate" ascending:NO];
    NSArray *sortedDropboxContents = [metadata.contents sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter1]];
    [sorter1 release];

    for (DBMetadata *child in sortedDropboxContents) {
        if ((!child.isDirectory) && (!child.isDeleted)) {
            // if file is an image
            NSString *pathExtension = [[child.path pathExtension] lowercaseString];
            if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"png"] || [pathExtension isEqualToString:@"jpeg"] || [pathExtension isEqualToString:@"bmp"] || [pathExtension isEqualToString:@"tiff"]) {
                NSString *dropboxImageURL = [NSString stringWithFormat:@"dropbox://%@", child.path];

                Entry *entry = nil;
                for (Entry *aEntry in stroom.entries) {  // always just one entry in a dropbox
                    entry = aEntry;
                }

                Picture *picture = [self getPictureFromEntry:entry andPictureUrl:dropboxImageURL inContext:context];
                
                BOOL syncPicture = NO;
                
                // check if an existing picture has a newer dropbox revision number
                if(picture) {
                    if (child.revision > [picture.dropboxRevision longLongValue]) {
                        syncPicture = YES;
                    }
                } else {
                    syncPicture = YES;
                }
                
                if (syncPicture) {
                    PicStroomImageProcessor *imageProcessor = [PicStroomImageProcessor currentProcessor];
                    NSString *imageUUID = [imageProcessor generateUUID];
                    BOOL success = [[self restClient] loadFileSync:child.path destinationPath:[imageProcessor getRawImagePathForUUID:imageUUID]];
                    if (!success) {
                        DebugLog(@"Error downloading file from dropbox for %@", child.path);
                    } else {
                        CGImageSourceRef rawImageSource = [imageProcessor createImageSourceFromURL:[NSURL fileURLWithPath:[imageProcessor getRawImagePathForUUID:imageUUID]]];
                        if (rawImageSource != nil) {
                            CGSize rawImageSize = [imageProcessor getImageSizeFromImageSource:rawImageSource];
                            if (rawImageSize.height <= MIN_IMAGE_HEIGHT) {
                                DebugLog(@"Blocking small image at %@", dropboxImageURL);
                                
                                Picture *picture = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_PICTURE inManagedObjectContext:context];
                               
                                picture.url = dropboxImageURL;
                                picture.processed = [NSNumber numberWithBool:YES];
                                picture.blocked = [NSNumber numberWithBool:YES];
                                picture.dropboxRevision = [NSNumber numberWithLongLong:child.revision];
                                [entry addPicturesObject:picture];
                                NSError *error;
                                if (![context save:&error]) {
                                    DebugLog(@"Whoops, couldn't save blocked: %@", [error localizedDescription]);
                                }
                            } else {
                                CGImageRef thumbnailImage = [imageProcessor createThumbnailImageRefFromImageSource:rawImageSource withSourceSizeOf:rawImageSize];
                                if (thumbnailImage == nil) {
                                    DebugLog(@"Blocking image because thumbnail could not be created for %@", dropboxImageURL);
                                    
                                    Picture *picture = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_PICTURE inManagedObjectContext:context];
                   
                                    picture.url = dropboxImageURL;
                                    picture.processed = [NSNumber numberWithBool:YES];
                                    picture.blocked = [NSNumber numberWithBool:YES];
                                    picture.dropboxRevision = [NSNumber numberWithLongLong:child.revision];
                                    [entry addPicturesObject:picture];
                                    NSError *error;
                                    if (![context save:&error]) {
                                        DebugLog(@"Whoops, couldn't save blocked picture: %@", [error localizedDescription]);
                                    }
                                } else {
                                    NSString *thumbnailUUID = [imageProcessor generateUUID];
                                    [imageProcessor saveThumbnailImageRefToDisk:thumbnailImage withUUID:thumbnailUUID];
                                    CGImageSourceRef thumbnailImageSource = [imageProcessor createImageSourceFromURL:[NSURL fileURLWithPath:[imageProcessor getThumbnailPathForUUID:thumbnailUUID]]];
                                    CGSize thumbnailSize = [imageProcessor getImageSizeFromImageSource:thumbnailImageSource];
                                    
                                    picture = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_PICTURE inManagedObjectContext:context];
                               
                                    picture.url = dropboxImageURL;
                                    picture.processed = [NSNumber numberWithBool:YES];
                                    picture.blocked = [NSNumber numberWithBool:NO];
                                    picture.rawPictureUUID = imageUUID;
                                    picture.rawHeight = [NSNumber numberWithFloat:rawImageSize.height];
                                    picture.rawWidth = [NSNumber numberWithFloat:rawImageSize.width];
                                    picture.thumbnailUUID = thumbnailUUID;
                                    picture.thumbHeight = [NSNumber numberWithFloat:thumbnailSize.height];
                                    picture.thumbWidth = [NSNumber numberWithFloat:thumbnailSize.width];
                                    picture.dropboxRevision = [NSNumber numberWithLongLong:child.revision];
                                    picture.date = child.lastModifiedDate;
                                    [entry addPicturesObject:picture];
                                    
                                    NSError *error;
                                    if (![context save:&error]) {
                                        DebugLog(@"Whoops, couldn't save picture: %@", [error localizedDescription]);
                                    } else {
                                        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_NEW_PICTURE_FOUND object:[stroom objectID]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if (isCancelled) { // check every for loop
            DebugLog(@"Cancelling Dropbox sync for %@", stroom.title);
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[self.stroom objectID]];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_CANCEL_SYNC_STROOM object:[self.stroom objectID]];
            return;
        }
    }

    if ([stroom.justAddedMarker boolValue] == YES) {
        stroom.justAddedMarker = [NSNumber numberWithBool:NO];
        NSError *error;
        if (![context save:&error]) {
            DebugLog(@"(justAddedMarker) Whoops, couldn't update Stroom: %@", [error localizedDescription]);
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[self.stroom objectID]];
}

- (void) updateStroomRSS {
    [self parseRSSFeedFromRSSUrl:[NSURL URLWithString:stroom.url]];
    if (!isCancelled) {        
        [self processUnprocessedPictures];
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[self.stroom objectID]];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Cancel Stroom update functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) cancelSync {
    DebugLog(@"Sync Manager for %@ received cancelSync message", stroom.title);
    isCancelled = YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (DBRestClient *) restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - RSS Feed Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
}

- (void) feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if (item.identifier == nil) {
        item.identifier = item.title;
    }
    DebugLog(@"Processing RSS entry: %@", item.title);

    Entry *entry = [self getEntryForStroom:stroom withIdentifier:item.identifier inContext:context];
    if (entry == nil) { // it's a new entry so lets store it!
        entry = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_ENTRY inManagedObjectContext:context];
        entry.title = item.title;
        entry.identifier = item.identifier;
        entry.link = item.link;
        if (item.date == nil) {
            entry.date = [NSDate date];
        } else {
            entry.date = item.date;
        }
        [stroom addEntriesObject:entry];
        NSError *error;
        if (![self.context save:&error]) {
            DebugLog(@"Whoops, couldn't save entry (into stroom): %@", [error localizedDescription]);
        }
    }

    // now grab images -- maybe there are some images we didn't get the last time we looked at this entry
    // or it's our first time looking at it.
    NSMutableArray *imageURLs = [[[NSMutableArray alloc] init] autorelease];

    if ([item.enclosures count] > 0) {
        DebugLog(@"Processing RSS feed enclosures");
        for (NSDictionary *enclosure in item.enclosures) {
            NSString *type = [enclosure objectForKey:@"type"];
            if ([type isEqualToString:@"image/jpeg"] || [type isEqualToString:@"image/png"] || [type isEqualToString:@"image/gif"] || [type isEqualToString:@"image"]) {
                [imageURLs addObject:[NSURL URLWithString:[enclosure objectForKey:@"url"]]];
            }
        }
    }

    if ([imageURLs count] == 0) {
        if (item.summary != nil) {
            [imageURLs addObjectsFromArray:[self extractSuitableImagesFromRawRSSEntry:item.summary]];
        }
        if (item.content != nil) {
            [imageURLs addObjectsFromArray:[self extractSuitableImagesFromRawRSSEntry:item.content]];
        }
    }

    for (NSURL *imageURL in imageURLs) {
        Picture *picture = [self getPictureFromEntry:entry andPictureUrl:[imageURL absoluteString] inContext:context];
        if (!picture) { // new picture
            Picture *picture = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_PICTURE inManagedObjectContext:context];
            picture.url = [imageURL absoluteString];
            picture.date = item.date;
            picture.processed = [NSNumber numberWithBool:NO];

            [entry addPicturesObject:picture];
            NSError *error = nil;
            if (![self.context save:&error]) {
                DebugLog(@"Whoops, couldn't save picture: %@", [error localizedDescription]);
            }
        }

        if (isCancelled) { // check every for loop
            DebugLog(@"Cancelling RSS sync for %@", stroom.title);
            [parser stopParsing];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[stroom objectID]];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_CANCEL_SYNC_STROOM object:[self.stroom objectID]];
            return;
        }
    }
}

- (void) feedParserDidFinish:(MWFeedParser *)parser {
    DebugLog(@"RSS parser finished for Stroom: %@", stroom.title);
}

- (void) feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    DebugLog(@"RSS parser finished with ERROR for Stroom: %@", stroom.title ? stroom.title : @"<None>");
    if (isCancelled) {
        DebugLog(@"RSS parser is cancelled and had and at the same time had a serious network error");
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_CANCEL_SYNC_STROOM object:[self.stroom objectID]];
    }
    isCancelled = YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Picture processing
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) processUnprocessedPictures {
    NSArray *unprocessedPictures = [self getUnprocessedPicturesForStroom:self.stroom inContext:self.context];
    
    if ([unprocessedPictures count]>0) {
        // purge images if more than user default allowed amount
        NSNumber *userDefaultMaxImagesPerStroom = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM];    
        if ([userDefaultMaxImagesPerStroom intValue] != 0) {
            NSUInteger imageCount = [self getNumberOfImagesInStroom:self.stroom inContext:self.context];
            
            if (imageCount > [userDefaultMaxImagesPerStroom intValue]) {
                DebugLog(@"*** purging images that are more than user amount allowed");
                [self purgeExcessImagesFromStroom:imageCount withUserDefaultMaxImagesPerStroom:[userDefaultMaxImagesPerStroom intValue]];
            }
        }
    }

    for (Picture *picture in unprocessedPictures) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        PicStroomImageProcessor *imageProcessor = [PicStroomImageProcessor currentProcessor];
        NSString *imageUUID = [imageProcessor generateUUID];
        BOOL isDownloaded = [imageProcessor syncDownloadImageForURL:[NSURL URLWithString:picture.url] toPath:[imageProcessor getRawImagePathForUUID:imageUUID]];

        if (isDownloaded) {
            CGImageSourceRef rawImageSource = [imageProcessor createImageSourceFromURL:[NSURL fileURLWithPath:[imageProcessor getRawImagePathForUUID:imageUUID]]];
            if (rawImageSource) {
                CGSize rawImageSize = [imageProcessor getImageSizeFromImageSource:rawImageSource];
                if (rawImageSize.height <= MIN_IMAGE_HEIGHT) {
                    DebugLog(@"Blocking small image at %@", picture.url);
                    picture.blocked = [NSNumber numberWithBool:YES];
                    NSError *error = nil;
                    if (![self.context save:&error]) {
                        DebugLog(@"Whoops, couldn't save blocked: %@", [error localizedDescription]);
                    }
                    [imageProcessor deleteImageFromDisk:imageUUID];
                } else {
                    // check if raw image is large enough to need resizing to fit iPad
                    if (rawImageSize.height > 1024 || rawImageSize.width > 1024) {
                        DebugLog(@"Large image detected, resizing to fit iPad memory better");
                        CGImageRef newRawImageSource = [imageProcessor createIpadSizedImageRefFromImageSource:rawImageSource withSourceSizeOf:rawImageSize];
                        if (newRawImageSource) {
                            NSString *imageType = nil;
                            NSString *pathExtension = [[picture.url pathExtension] lowercaseString];
                            if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"jpeg"]) {
                                DebugLog(@"JPEG resized");
                                imageType = @"public.jpeg";
                            } else if ([pathExtension isEqualToString:@"png"]) {
                                DebugLog(@"PNG resized");
                                imageType = @"public.png";
                            } else if ([pathExtension isEqualToString:@"gif"]) {
                                DebugLog(@"GIF resized");
                                imageType = @"com.compuserve.gif";
                            }

                            if (imageType) {
                                [imageProcessor saveRawImageRefToDisk:newRawImageSource withUUID:imageUUID andType:imageType];
                            }
                        }
                    }
                    CGImageRef thumbnailImage = [imageProcessor createThumbnailImageRefFromImageSource:rawImageSource withSourceSizeOf:rawImageSize];
                    if (!thumbnailImage) {
                        DebugLog(@"Blocking image because thumbnail could not be created for %@", picture.url);
                        picture.blocked = [NSNumber numberWithBool:YES];
                        NSError *error = nil;
                        if (![self.context save:&error]) {
                            DebugLog(@"Whoops, couldn't save blocked picture: %@", [error localizedDescription]);
                        }
                        [imageProcessor deleteImageFromDisk:imageUUID];
                    } else {
                        NSString *thumbnailUUID = [imageProcessor generateUUID];
                        [imageProcessor saveThumbnailImageRefToDisk:thumbnailImage withUUID:thumbnailUUID];
                        CGImageSourceRef thumbnailImageSource = [imageProcessor createImageSourceFromURL:[NSURL fileURLWithPath:[imageProcessor getThumbnailPathForUUID:thumbnailUUID]]];
                        CGSize thumbnailSize = [imageProcessor getImageSizeFromImageSource:thumbnailImageSource];

                        picture.processed = [NSNumber numberWithBool:YES];
                        picture.blocked = [NSNumber numberWithBool:NO];
                        picture.rawPictureUUID = imageUUID;
                        picture.rawHeight = [NSNumber numberWithFloat:rawImageSize.height];
                        picture.rawWidth = [NSNumber numberWithFloat:rawImageSize.width];
                        picture.thumbnailUUID = thumbnailUUID;
                        picture.thumbHeight = [NSNumber numberWithFloat:thumbnailSize.height];
                        picture.thumbWidth = [NSNumber numberWithFloat:thumbnailSize.width];
                        NSError *error = nil;
                        if (![context save:&error]) {
                            DebugLog(@"Whoops, couldn't save picture: %@", [error localizedDescription]);
                        } else {
                            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_NEW_PICTURE_FOUND object:[stroom objectID]];
                        }
                    }
                }
            }
        }

        [pool release];
        if (isCancelled) { // check every for loop
            DebugLog(@"Cancelling RSS sync processing of unprocessed pictures for %@", stroom.title);
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_CANCEL_SYNC_STROOM object:[stroom objectID]];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[stroom objectID]];
            return;
        }
    }

    if ([stroom.justAddedMarker boolValue] == YES) {
        stroom.justAddedMarker = [NSNumber numberWithBool:NO];
        NSError *error;
        if (![context save:&error]) {
            DebugLog(@"Whoops, couldn't update Stroom: %@", [error localizedDescription]);
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) mergeContextChanges:(NSNotification *)notification {
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    NSManagedObjectContext *appDelegateContext =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

    [appDelegateContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
}

@end
