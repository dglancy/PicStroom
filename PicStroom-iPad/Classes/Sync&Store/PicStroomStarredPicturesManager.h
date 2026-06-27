//
//  PicStroomStarredPicturesManager.h
//  PicStroom
//
//  Created by Damien Glancy on 28/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomManager.h"
#import "Picture.h"

@interface PicStroomStarredPicturesManager : PicStroomManager {
    
}

+ (void) registerPictureInStarredStroom:(Picture *)picture;
+ (void) deregisterPictureInStarredStroom:(Picture *)picture;

@end
