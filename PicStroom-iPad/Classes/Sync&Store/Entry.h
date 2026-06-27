//
//  Entry.h
//  PicStroom
//
//  Created by Damien Glancy on 17/03/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Picture, Stroom;

@interface Entry : NSManagedObject {
    @private
}
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) Stroom *stroom;
@property (nonatomic, retain) NSSet *pictures;

- (void) addPicturesObject:(Picture *)value;
- (void) removePicturesObject:(Picture *)value;
- (void) addPictures:(NSSet *)value;
- (void) removePictures:(NSSet *)value;

@end
