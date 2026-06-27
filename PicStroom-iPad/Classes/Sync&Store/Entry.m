//
//  Entry.m
//  PicStroom
//
//  Created by Damien Glancy on 17/03/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "Entry.h"
#import "Picture.h"
#import "Stroom.h"


@implementation Entry
@dynamic author;
@dynamic title;
@dynamic date;
@dynamic link;
@dynamic identifier;
@dynamic stroom;
@dynamic pictures;


- (void) addPicturesObject:(Picture *)value {
    NSSet * changedObjects = [[NSSet alloc] initWithObjects:&value count:1];

    [self willChangeValueForKey:@"pictures" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"pictures"] addObject:value];
    [self didChangeValueForKey:@"pictures" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void) removePicturesObject:(Picture *)value {
    NSSet * changedObjects = [[NSSet alloc] initWithObjects:&value count:1];

    [self willChangeValueForKey:@"pictures" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"pictures"] removeObject:value];
    [self didChangeValueForKey:@"pictures" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void) addPictures:(NSSet *)value {
    [self willChangeValueForKey:@"pictures" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"pictures"] unionSet:value];
    [self didChangeValueForKey:@"pictures" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void) removePictures:(NSSet *)value {
    [self willChangeValueForKey:@"pictures" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"pictures"] minusSet:value];
    [self didChangeValueForKey:@"pictures" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
