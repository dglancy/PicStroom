//
//  Metadata.h
//  PicStroom
//
//  Created by Damien Glancy on 17/03/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Picture;

@interface Metadata : NSManagedObject {
    @private
}
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * attribute;
@property (nonatomic, retain) Picture * picture;

@end
