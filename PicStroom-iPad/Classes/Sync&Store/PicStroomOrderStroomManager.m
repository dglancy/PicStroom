//
//  PicStroomUpdateStroomManager.m
//  PicStroom
//
//  Created by Damien Glancy on 19/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomOrderStroomManager.h"
#import "PicStroomSupervisor.h"

@implementation PicStroomOrderStroomManager

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Update Stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateOrder:(NSInteger)order onStroom:(Stroom *)stroom {
    stroom.order = [NSNumber numberWithInteger:order];
    [self saveContextChanges];
}

- (void) storeCurrentOrderOfStrooms:(NSMutableArray *)stroomSupervisors {
    NSInteger countForOrder = 1;
    for(PicStroomSupervisor *supervisor in stroomSupervisors) {
        [self updateOrder:countForOrder onStroom:supervisor.stroom];
        countForOrder++;
    }
}

@end
