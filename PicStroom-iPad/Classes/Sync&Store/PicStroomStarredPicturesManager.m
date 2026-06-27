//
//  PicStroomStarredPicturesManager.m
//  PicStroom
//
//  Created by Damien Glancy on 28/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomStarredPicturesManager.h"
#import "PicStroomViewController.h"
#import "PicStroomSupervisor.h"
#import "Entry.h"
#import "Picture.h"

#import "NSNotificationCenter+NSNotificationCenterAdditions.h"

@implementation PicStroomStarredPicturesManager

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (void) registerPictureInStarredStroom:(Picture *)picture {
    Picture *notificationPicture = nil;
    Entry *entry = [self getStarredEntry];
    
    // first to see if this has been starred before and was deregistered.
    NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:[picture managedObjectContext]];
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"rawPictureUUID=%@ and entry.stroom.url==%@", picture.rawPictureUUID, INTERNAL_STARRED_STROOM_URL];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    
    NSError * error;
    NSArray *fetchedObjects = [[picture managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    if ([fetchedObjects count]>0) {
        for(Picture *pix in fetchedObjects) {
            pix.blocked = [NSNumber numberWithBool:NO];
            pix.date = [NSDate date];
            notificationPicture = pix;
        }
    } else {
        Picture *starredPicture = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_PICTURE inManagedObjectContext:[picture managedObjectContext]];
        starredPicture.processed = [NSNumber numberWithBool:YES];
        starredPicture.blocked = [NSNumber numberWithBool:NO];
        starredPicture.date = [NSDate date];
        starredPicture.rawPictureUUID = picture.rawPictureUUID;
        starredPicture.rawHeight = picture.rawHeight;
        starredPicture.thumbnailUUID = picture.thumbnailUUID;
        starredPicture.thumbHeight = picture.thumbHeight;
        starredPicture.thumbWidth = picture.thumbWidth;
        
        [entry addPicturesObject:starredPicture];
        notificationPicture = starredPicture;
    }
    [self saveContextChangesWithContext:[picture managedObjectContext]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_NEW_PICTURE_FOUND object:[notificationPicture.entry.stroom objectID]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[notificationPicture.entry.stroom objectID]];
}

+ (void) deregisterPictureInStarredStroom:(Picture *)picture {
    Picture *notificationPicture = nil;
    if ([picture.entry.stroom.type intValue] == StroomTypeStarred) { // we're unstaring from the virtual stream
        picture.blocked = [NSNumber numberWithBool:YES];
        notificationPicture = picture;
    } else {
        NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_PICTURE inManagedObjectContext:[picture managedObjectContext]];
        NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"rawPictureUUID=%@ and entry.stroom.url==%@", picture.rawPictureUUID, INTERNAL_STARRED_STROOM_URL];
        
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setEntity:entity];
        
        NSError * error;
        NSArray *fetchedObjects = [[picture managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        [fetchRequest release];
        
        for(Picture *pix in fetchedObjects) {
            pix.blocked = [NSNumber numberWithBool:YES];
            notificationPicture = pix;
        }
    }
    
    [self saveContextChangesWithContext:[picture managedObjectContext]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_PICTURE_REMOVED object:[notificationPicture.entry.stroom objectID]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:NOTIF_SYNC_END_STROOM object:[notificationPicture.entry.stroom objectID]];
}

@end
