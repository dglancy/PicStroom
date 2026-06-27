//
//  PicStroomManager.m
//  PicStroom
//
//  Created by Damien Glancy on 24/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomManager.h"
#import "PicStroomAppDelegate.h"

#import "Stroom.h"
#import "Entry.h"
#import "Picture.h"

#import "ASIHTTPRequest.h"

@implementation PicStroomManager

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data Search Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSArray *) getAllPicturesForStroom:(NSManagedObjectID *)stroomObjectID {
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];

    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator]];
    Stroom * stroom = (Stroom *)[context objectWithID:stroomObjectID];

    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    NSPredicate * predicate=nil;
    if ([stroom.type intValue] == StroomTypeRSS) {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND entry.stroom.url==%@", stroom.url];
    } else if ([stroom.type intValue] == StroomTypeDropbox) {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND entry.stroom.dropboxPath==%@", stroom.dropboxPath];
    } else if ([stroom.type intValue] == StroomTypeStarred) {
        predicate = [NSPredicate predicateWithFormat:@"thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND blocked==NO and processed==YES AND entry.stroom.url==%@", INTERNAL_STARRED_STROOM_URL];
    }

    [request setPredicate:predicate];

    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray * sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];

    NSError * error = nil;
    NSArray * results = [context executeFetchRequest:request error:&error];
    [sortDescriptor release];
    [sortDescriptors release];
    [request release];
    [context autorelease];

    if (results == nil) {
        DebugLog(@"Error searching for Pictures in Stroom: %@", [error localizedDescription]);
    }

    return results;
}

- (NSArray *) getUnprocessedPicturesForStroom:(Stroom *)stroom inContext:(NSManagedObjectContext *)context {
    NSError * error = nil;

    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Picture" inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];

    [request setEntity:entityDescription];

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND purged==NO AND processed==NO AND entry.stroom.url==%@", stroom.url];

    [request setPredicate:predicate];

    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray * sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];

    NSArray * results = [context executeFetchRequest:request error:&error];
    [sortDescriptor release];
    [sortDescriptors release];
    [request release];

    if (results == nil) {
        DebugLog(@"Error searching for Pictures in Stroom: %@", [error localizedDescription]);
    }

    return results;
}

- (Entry *) getEntryForStroom:(Stroom *)stroom withIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
    NSError * error = nil;
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityEntry = [NSEntityDescription entityForName:ENTITY_ENTRY inManagedObjectContext:context];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"stroom=%@ and identifier=%@", stroom, identifier];

    [fetchRequest setEntity:entityEntry];
    [fetchRequest setPredicate:predicate];
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    if (fetchedObjects == nil || error != nil) {
        return nil;
    } else if ([fetchedObjects count] > 0) {
        return [fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

- (Picture *) getPictureFromEntry:(Entry *)entry andPictureUrl:(NSString *)url inContext:(NSManagedObjectContext *)context {
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityPicture = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:context];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"entry=%@ and url=%@", entry, url];
    
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray * sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    [fetchRequest setEntity:entityPicture];
    [fetchRequest setPredicate:predicate];
    NSError * error = nil;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    if (fetchedObjects == nil || error != nil) {
        return nil;
    } else if ([fetchedObjects count] >= 1) {
        return [fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSArray *) getOldestPicturesForStroom:(Stroom *)stroom limit:(NSUInteger)limit inContext:(NSManagedObjectContext *)context {
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Picture" inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setFetchLimit:limit];
    
    NSPredicate * predicate;
    if ([stroom.type intValue] == StroomTypeRSS) {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND date!=NULL AND entry.stroom.url==%@", stroom.url];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND date!=NULL AND entry.stroom.dropboxPath==%@", stroom.dropboxPath];
    }
    
    [request setPredicate:predicate];
    
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    NSArray * sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError * error = nil;
    NSArray * results = [context executeFetchRequest:request error:&error];
    [sortDescriptor release];
    [sortDescriptors release];
    [request release];
    
    if (results == nil) {
        DebugLog(@"Error searching for Pictures in Stroom: %@", [error localizedDescription]);
    }
    return results;
}

- (NSInteger) getNumberOfImagesInStroom:(Stroom *)stroom inContext:(NSManagedObjectContext *)context { 
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Picture" inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate * predicate;
    if ([stroom.type intValue] == StroomTypeRSS) {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND entry.stroom.url==%@", stroom.url];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"blocked==NO AND processed==YES AND purged==NO AND thumbnailUUID!=NULL AND rawPictureUUID!=NULL AND entry.stroom.dropboxPath==%@", stroom.dropboxPath];
    }
    
    [request setPredicate:predicate];
    
    NSError * error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    [request release];
    
    if (error) {
        DebugLog(@"Error counting Pictures in Stroom: %@", [error localizedDescription]);
    } else if (count==NSNotFound) {
        count = 0;
    }
    return count;
}

- (NSInteger) getNumberOfNonSystemStrooms {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"system=%@ AND type!=%@", [NSNumber numberWithBool:NO], [NSNumber numberWithInt:StroomTypeStarred]];

    [request setEntity:[NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context]];
    [request setPredicate:predicate];
    [request setIncludesSubentities:NO]; // Omit subentities. Default is YES (i.e. include subentities)

    NSError * error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    if (error) {
        DebugLog(@"Whoops, couldn't count strooms: %@", [error localizedDescription]);
        count = 0;
    } else if (count == NSNotFound) {
        count = 0;
    }
    [request release];
    return count;
}

- (NSInteger) getNumberOfStrooms {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type!=%@", [NSNumber numberWithInt:StroomTypeStarred]];

    [request setEntity:[NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context]];
    [request setPredicate:predicate];
    [request setIncludesSubentities:NO]; // Omit subentities. Default is YES (i.e. include subentities)
    
    NSError * error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    if (error) {
        DebugLog(@"Whoops, couldn't count strooms: %@", [error localizedDescription]);
        count = 0;
    } else if (count == NSNotFound) {
        count = 0;
    }
    [request release];
    return count;
}

- (Stroom *) getStroomFromURL:(NSString *)url {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"url=%@", url];

    DebugLog(@"Searching for stroom with url: %@", url);
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];

    NSError * error = nil;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    [fetchRequest release];
    if (error != nil || (fetchedObjects != nil && [fetchedObjects count] > 0)) {
        return (Stroom *)[fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

- (Stroom *) getStroomFromDropboxPath:(NSString *)path {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"dropboxPath=%@", path];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];

    NSError * error;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    [fetchRequest release];
    if (fetchedObjects != nil && [fetchedObjects count] > 0) {
        return (Stroom *)[fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

- (Picture *) getPictureFromRawUUID:(NSString *)uuid {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:context];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"rawPictureUUID=%@", uuid];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];

    NSError * error;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    [fetchRequest release];
    if (fetchedObjects != nil && [fetchedObjects count] > 0) {
        return (Picture *)[fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

- (Picture *) getPictureFromThumbnailUUID:(NSString *)uuid {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:context];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"thumbnailUUID=%@", uuid];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    
    NSError * error;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    [fetchRequest release];
    if (fetchedObjects != nil && [fetchedObjects count] > 0) {
        return (Picture *)[fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (Stroom *) getStarredStroom {
    NSManagedObjectContext *context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type==%@", [NSNumber numberWithInt:StroomTypeStarred]];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
    [request release];
    
    if (error != nil || (fetchedObjects != nil && [fetchedObjects count] == 1)) {
        return (Stroom *)[fetchedObjects objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (Entry *) getStarredEntry {
    Stroom *stroom = [self getStarredStroom];
    Entry *entry = nil;
    
    for (Entry *aEntry in stroom.entries) {  // always just one entry in a dropbox
        entry = aEntry;
    }
    return entry;
}

- (void) deleteStroom:(Stroom *)stroom {
    NSManagedObjectContext * context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

    if ([stroom.type intValue] == StroomTypeRSS) {
        [FlurryAPI logEvent:FLURRY_REMOVE_WEB_STROOM];
    } else if ([stroom.type intValue] == StroomTypeDropbox) {
        [FlurryAPI logEvent:FLURRY_REMOVE_DROPBOX_STROOM];
    }
    [context deleteObject:stroom];
    [self saveContextChanges];
}

- (NSArray *) getAllStrooms {
    NSManagedObjectContext * context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type!=%@", [NSNumber numberWithInt:StroomTypeStarred]];
    [fetchRequest setPredicate:predicate];

    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray * sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [sortDescriptor release];
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSError * error;
    NSArray * fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    [sortDescriptors release];
    [fetchRequest release];

    return fetchedObjects;
}

- (NSArray *) getRSSFeedsUrlFromWebUrl:(NSURL *)url {
    return [self getRSSFeedsUrlFromData:[self executeRequest:url]];
}

- (NSArray *) getRSSFeedsUrlFromHTML:(NSString *)html {
    return [self getRSSFeedsUrlFromData:[html dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSArray *) getRSSFeedsUrlFromData:(NSData *)data {
    NSMutableArray * rssFeeds = [[[NSMutableArray alloc] init] autorelease];
    Document * doc = [[Document alloc] initWithHTMLData:data];

    // rss+xml
    NSString * kXPathQuery1 = @"//link[@type=\"application/rss+xml\"]/@href";
    NSArray * elements1 = [doc search:kXPathQuery1];

    for (DocumentElement * element in elements1) {
        [rssFeeds addObject:[NSURL URLWithString:[element content]]];
    }

    // rdf+xml
    //	NSString *kXPathQuery2 = @"//link[@type=\"application/rdf+xml\"]/@href";
    //	NSArray *elements2 = [doc search:kXPathQuery2];
    //    for  (DocumentElement *element in elements2) {
    //        [rssFeeds addObject:[NSURL URLWithString:[element content]]];
    //    }

    // atom+xml
    NSString * kXPathQuery3 = @"//link[@type=\"application/atom+xml\"]/@href";
    NSArray * elements3 = [doc search:kXPathQuery3];
    for (DocumentElement * element in elements3) {
        [rssFeeds addObject:[NSURL URLWithString:[element content]]];
    }

    [doc release];
    return rssFeeds;
}

- (void) parseRSSFeedFromRSSUrl:(NSURL *)url {
    if (!url || [[url absoluteString] length] == 0) {
        DebugLog(@"Not parsing rss as URL is bogus");
        return;
    }

    DebugLog(@"Parse feed from url: %@", [url absoluteString]);
    MWFeedParser * feedParser = [[[MWFeedParser alloc] initWithFeedURL:url] autorelease];
    feedParser.delegate = self;
    feedParser.feedParseType = ParseTypeFull;     // Parse feed info and all items
    feedParser.connectionType = ConnectionTypeSynchronously;
    [feedParser parse];
}

- (NSArray *) extractSuitableImagesFromRawRSSEntry:(NSString *)rawRSS {
    NSMutableArray * images = [[NSMutableArray alloc] init];

    if (rawRSS != nil && [rawRSS length] != 0) {
        NSRegularExpression * regex = [[NSRegularExpression alloc] initWithPattern:@"<\\s*?img\\s+[^>]*?\\s*src\\s*=\\s*([\"\'])((\\\\?+.)*?)\\1[^>]*?>" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray * imagesHTML = [regex matchesInString:rawRSS options:0 range:NSMakeRange(0, [rawRSS length])];
        [regex release];

        for (NSTextCheckingResult * image in imagesHTML) {
            NSString * imageHTML = [rawRSS substringWithRange:image.range];

            NSRegularExpression * regex2 = [[NSRegularExpression alloc] initWithPattern:@"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray * imageSource = [regex2 matchesInString:imageHTML options:0 range:NSMakeRange(0, [imageHTML length])];
            [regex2 release];

            NSString * imageSourceURLString = nil;
            for (NSTextCheckingResult * result in imageSource) {
                NSString * str = [imageHTML substringWithRange:result.range];
                // DebugLog(@"url is %@",str);
                if ([str hasPrefix:@"http"]) {
                    // strip off any crap after file extension
                    // find jpg
                    NSRange r1 = [str rangeOfString:@".jpg" options:NSBackwardsSearch && NSCaseInsensitiveSearch];
                    if (r1.location == NSNotFound) {
                        // find jpeg
                        NSRange r2 = [str rangeOfString:@".jpeg" options:NSBackwardsSearch && NSCaseInsensitiveSearch];
                        if (r2.location == NSNotFound) {
                            // find png
                            NSRange r3 = [str rangeOfString:@".png" options:NSBackwardsSearch && NSCaseInsensitiveSearch];
                            if (r3.location == NSNotFound) {
                                // find gif
                                NSRange r4 = [str rangeOfString:@".gif" options:NSBackwardsSearch && NSCaseInsensitiveSearch];
                                if (r4.location == NSNotFound) {
                                    break;
                                } else {
                                    // gif found
                                    imageSourceURLString = [str substringWithRange:NSMakeRange(0, r4.location + r4.length)];
                                }
                            } else {
                                // png was found
                                imageSourceURLString = [str substringWithRange:NSMakeRange(0, r3.location + r3.length)];
                            }
                        } else {
                            // jpeg was found
                            imageSourceURLString = [str substringWithRange:NSMakeRange(0, r2.location + r2.length)];
                            break;
                        }
                    } else {
                        // jpg was found
                        imageSourceURLString = [str substringWithRange:NSMakeRange(0, r1.location + r1.length)];
                        break;
                    }
                }
            }

            if (imageSourceURLString) {
                DebugLog(@"*** image found: %@", imageSourceURLString);
                NSURL * imageURL = [NSURL URLWithString:imageSourceURLString];
                if (imageURL != nil) {
                    [images addObject:imageURL];
                }
            }
        }
    }
    return [images autorelease];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data Utility Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveContextChanges {
    NSManagedObjectContext * context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSError * error;

    if (![context save:&error]) {
        DebugLog(@"(saveContextChanges) Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

+ (void) saveContextChangesWithContext:(NSManagedObjectContext *)context {
    NSError * error;
    
    if (![context save:&error]) {
        DebugLog(@"(saveContextChanges) Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Http Utility Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSData *) executeRequest:(NSURL *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSData * responseData = nil;
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"User-Agent" value:USER_AGENT];
    [request startSynchronous];
    NSError * error = [request error];
    if (!error) {
        responseData = [request responseData];
    } else {
        DebugLog(@"%@/%@", [error localizedDescription], [error localizedFailureReason]);
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    return responseData;
}

- (NSString *) cleanUpString:(NSString *)cleanme {
    NSMutableString * tempString = [[NSMutableString alloc] initWithString:cleanme];

    [tempString replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:0 range:NSMakeRange(0, [tempString length])];
    [tempString replaceOccurrencesOfString:@"&nbsp" withString:@" " options:0 range:NSMakeRange(0, [tempString length])];

    return [tempString autorelease];
}

@end
