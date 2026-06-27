//
//  PicStroomMetadataManager.h
//  PicStroom
//
//  Created by Damien Glancy on 28/08/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomManager.h"

@interface PicStroomMetadataManager : PicStroomManager {
    
}

+ (void) starPicture:(Picture *)picture;
+ (void) unstarPicture:(Picture *)picture;
+ (BOOL) isStarredPicture:(Picture *)picture;
+ (BOOL) isThereAnyStarredPictures;

@end
