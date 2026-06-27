//
//  Picture.m
//  PicStroom
//
//  Created by Damien Glancy on 12/05/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "Picture.h"
#import "Entry.h"
#import "Metadata.h"


@implementation Picture
@dynamic thumbHeight;
@dynamic blocked;
@dynamic rawHeight;
@dynamic purged;
@dynamic url;
@dynamic date;
@dynamic thumbnailUUID;
@dynamic rawWidth;
@dynamic dropboxRevision;
@dynamic thumbWidth;
@dynamic rawPictureUUID;
@dynamic processed;
@dynamic entry;
@dynamic metadata;


- (void) addMetadataObject:(Metadata *)value {
    NSSet * changedObjects = [[NSSet alloc] initWithObjects:&value count:1];

    [self willChangeValueForKey:@"metadata" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"metadata"] addObject:value];
    [self didChangeValueForKey:@"metadata" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void) removeMetadataObject:(Metadata *)value {
    NSSet * changedObjects = [[NSSet alloc] initWithObjects:&value count:1];

    [self willChangeValueForKey:@"metadata" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"metadata"] removeObject:value];
    [self didChangeValueForKey:@"metadata" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void) addMetadata:(NSSet *)value {
    [self willChangeValueForKey:@"metadata" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"metadata"] unionSet:value];
    [self didChangeValueForKey:@"metadata" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void) removeMetadata:(NSSet *)value {
    [self willChangeValueForKey:@"metadata" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"metadata"] minusSet:value];
    [self didChangeValueForKey:@"metadata" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
