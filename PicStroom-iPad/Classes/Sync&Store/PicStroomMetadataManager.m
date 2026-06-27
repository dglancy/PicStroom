//
//  PicStroomMetadataManager.m
//  PicStroom
//
//  Created by Damien Glancy on 28/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomMetadataManager.h"
#import "PicStroomAppDelegate.h"
#import "Metadata.h"

@implementation PicStroomMetadataManager

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (void) starPicture:(Picture *)picture {    
    Metadata *metadata = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_METADATA inManagedObjectContext:[picture managedObjectContext]];
    metadata.attribute = METADATA_STAR;
    metadata.value = @"Y";
    
    [picture addMetadataObject:metadata];
    
    [FlurryAPI logEvent:FLURRY_STAR_IMAGE];
    [self saveContextChangesWithContext:[picture managedObjectContext]];
}

+ (void) unstarPicture:(Picture *)picture {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"attribute == %@",METADATA_STAR];
    NSSet *filteredSet = [picture.metadata filteredSetUsingPredicate:predicate];

    for(Metadata *metadata in filteredSet) {
        [[picture managedObjectContext] deleteObject:metadata];
    }
    
    [FlurryAPI logEvent:FLURRY_UNSTAR_IMAGE];
    [self saveContextChangesWithContext:[picture managedObjectContext]];
}

+ (BOOL) isStarredPicture:(Picture *)picture {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"attribute == %@",METADATA_STAR];
    NSSet *filteredSet = [picture.metadata filteredSetUsingPredicate:predicate];
    if([filteredSet count]>0) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL) isThereAnyStarredPictures {
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:[(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator]];
    
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:ENTITY_METADATA inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate * predicate= [NSPredicate predicateWithFormat:@"attribute == %@", METADATA_STAR];
    [request setPredicate:predicate];
    
    NSError * error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    [request release];
    [context autorelease];
    
    if (error) {
        DebugLog(@"Error finding starred pictures: %@", [error localizedDescription]);
        return NO;
    } else if (count==NSNotFound || count==0) {
        return NO;
    } else {
        return YES;
    }
}


@end
