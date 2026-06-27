//
//  PicStroomUpdateStroomManager.h
//  PicStroom
//
//  Created by Damien Glancy on 19/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomManager.h"

@interface PicStroomOrderStroomManager : PicStroomManager {
    
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Update Stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateOrder:(NSInteger)order onStroom:(Stroom *)Stroom;
- (void) storeCurrentOrderOfStrooms:(NSMutableArray *)stroomSupervisors;

@end
