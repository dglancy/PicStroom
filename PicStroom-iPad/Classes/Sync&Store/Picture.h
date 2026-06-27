//
//  Picture.h
//  PicStroom
//
//  Created by Damien Glancy on 12/05/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Entry, Metadata;

@interface Picture : NSManagedObject {
    @private
}
@property (nonatomic, retain) NSNumber *thumbHeight;
@property (nonatomic, retain) NSNumber *blocked;
@property (nonatomic, retain) NSNumber *rawHeight;
@property (nonatomic, retain) NSNumber *purged;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *thumbnailUUID;
@property (nonatomic, retain) NSNumber *rawWidth;
@property (nonatomic, retain) NSNumber *dropboxRevision;
@property (nonatomic, retain) NSNumber *thumbWidth;
@property (nonatomic, retain) NSString *rawPictureUUID;
@property (nonatomic, retain) NSNumber *processed;
@property (nonatomic, retain) Entry *entry;
@property (nonatomic, retain) NSSet *metadata;

- (void) addMetadataObject:(Metadata *)value;

@end
