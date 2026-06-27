//
//  PicStroomSelectedDBResourcesManager.m
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomSelectedDBResourcesManager.h"
#import "DBMetadata.h"

static PicStroomSelectedDBResourcesManager *manager;

@implementation PicStroomSelectedDBResourcesManager
@synthesize selectedDBResources;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton Init
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomSelectedDBResourcesManager *) currentManager {
    @synchronized(self) {
        if (!manager) {
            manager = [[[self class] alloc] init];
            manager.selectedDBResources = [[NSMutableArray alloc] init];
        }
    }
    return manager;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) reset {
    [selectedDBResources removeAllObjects];
}

- (NSMutableArray *) getSelectedResources {
    return selectedDBResources;
}

- (void) addSelectedResource:(NSString *)path {
    [selectedDBResources addObject:path];
}

- (void) removeSelectedResource:(NSString *)path {
    [selectedDBResources removeObject:path];
}

- (BOOL) isAlreadySelected:(NSString *)path {
    return [selectedDBResources containsObject:path];
}

@end
