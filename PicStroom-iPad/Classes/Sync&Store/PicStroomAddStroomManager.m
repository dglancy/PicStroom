//
//  PicStroomAddStroomManager.m
//  PicStroom
//
//  Created by Damien Glancy on 25/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomAddStroomManager.h"
#import "NSNotificationCenter+NSNotificationCenterAdditions.h"
#import "Stroom.h"
#import "Entry.h"
#import "Picture.h"

@implementation PicStroomAddStroomManager
@synthesize stroom;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [stroom release], stroom = nil;
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Add Web Stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (Stroom *) addStroomRSS:(NSURL *)url {
    if (!url || [[url absoluteString] length] == 0) {
        DebugLog(@"Not adding stroom as URL is bogus");
        return nil;
    }

    NSManagedObjectContext * context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    self.stroom = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_STROOM inManagedObjectContext:context];
    self.stroom.url = [url absoluteString];
    self.stroom.type = [NSNumber numberWithInt:StroomTypeRSS];
    self.stroom.date = [NSDate date];
    self.stroom.order = [NSNumber numberWithInteger:([self getNumberOfStrooms]+1)];

    [self parseRSSFeedFromRSSUrl:url];
    if (!self.stroom) {
        DebugLog(@"*** Issue creating stroom");
        [context rollback];
        return nil;
    } else {
        [self saveContextChanges];

        [FlurryAPI logEvent:FLURRY_ADD_WEB_STROOM];
        return stroom;
    }
}

- (Stroom *) addSystemStroomRSS:(NSURL *)url {
    NSManagedObjectContext * context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

    self.stroom = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_STROOM inManagedObjectContext:context];
    self.stroom.url = [url absoluteString];
    self.stroom.type = [NSNumber numberWithInt:StroomTypeRSS];
    self.stroom.date = [NSDate date];
    self.stroom.system = [NSNumber numberWithBool:YES];

    [self parseRSSFeedFromRSSUrl:url];
    [self saveContextChanges];

    [FlurryAPI logEvent:FLURRY_ADD_WEB_STROOM];
    return stroom;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Add Dropbox folder
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (Stroom *) addStroomDropbox:(NSString *)path {
    NSString * title = [self generateDropboxTitleFromPath:path];

    NSManagedObjectContext * context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

    self.stroom = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_STROOM inManagedObjectContext:context];
    self.stroom.type = [NSNumber numberWithInt:StroomTypeDropbox];
    self.stroom.title = title;
    self.stroom.dropboxPath = path;
    self.stroom.date = [NSDate date];
    self.stroom.order = [NSNumber numberWithInteger:([self getNumberOfStrooms]+1)];

    Entry * newEntry = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_ENTRY inManagedObjectContext:context];
    newEntry.title = title;
    newEntry.date = [NSDate date];
    [self.stroom addEntriesObject:newEntry];

    [self saveContextChanges];

    [FlurryAPI logEvent:FLURRY_ADD_DROPBOX_STROOM];
    return self.stroom;
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Starred Stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) isStarredStroomAvailable {
    NSManagedObjectContext *context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type=%@", [NSNumber numberWithInt:StroomTypeStarred]];
    
    [request setEntity:[NSEntityDescription entityForName:ENTITY_STROOM inManagedObjectContext:context]];
    [request setPredicate:predicate];
    [request setIncludesSubentities:NO]; // Omit subentities. Default is YES (i.e. include subentities)
    
    NSError * error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    [request release];
    
    if (error) {
        DebugLog(@"Whoops, couldn't count strooms: %@", [error localizedDescription]);
        return YES; // error on caution -- we don't want duplicates of the starred stroom
    } else if (count == NSNotFound || count == 0 ) {
        return NO;
    } else {
        return YES;
    }
}

+ (Stroom *) createStarredStroom {
    NSManagedObjectContext *context = [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    Stroom *stroom = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_STROOM inManagedObjectContext:context];
    stroom.type = [NSNumber numberWithInt:StroomTypeStarred];
    stroom.title = @"Starred images";
    stroom.url = INTERNAL_STARRED_STROOM_URL;
    stroom.date = [NSDate date];
    stroom.order = [NSNumber numberWithInteger:0];
    
    Entry * newEntry = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_ENTRY inManagedObjectContext:context];
    newEntry.title = @"Holding Entry For Starred Pictures";
    newEntry.date = [NSDate date];
    [stroom addEntriesObject:newEntry];
    
    [self saveContextChangesWithContext:context];
    return stroom;
}



// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - RSS Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    if (info.title == nil || [info.title length] == 0) {
        self.stroom.title = self.stroom.url;
        DebugLog(@"No RSS feed title available, using URL.");
    } else {
        self.stroom.title = info.title;
    }
    [parser stopParsing]; // no need to parse any more
}

- (void) feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
}

- (void) feedParserDidFinish:(MWFeedParser *)parser {
}

- (void) feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    DebugLog(@"Adding RSS Stroom ... parser finished with ERROR for Stroom: %@", self.stroom.title ? self.stroom.title : @"<None>");
    self.stroom = nil;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) mergeContextChanges:(NSNotification *)notification {
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    NSManagedObjectContext * appDelegateContext =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

    [appDelegateContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Utility functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *) generateDropboxTitleFromPath:(NSString *)path {
    return path;
}

@end
