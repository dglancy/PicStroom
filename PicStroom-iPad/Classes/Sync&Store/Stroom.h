//
//  Stroom.h
//  PicStroom
//
//  Created by Damien Glancy on 21/05/2011.
//  Copyright (c) 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Entry;
@class PicStroomSupervisor;

@interface Stroom : NSManagedObject {
    @private
}
@property (nonatomic, retain) NSNumber *system;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *dropboxPath;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSNumber *order;
@property (nonatomic, assign) PicStroomSupervisor *stroomSupervisor;
@property (nonatomic, retain) NSNumber *justAddedMarker;
@property (nonatomic, retain) NSSet *entries;

- (void) addEntriesObject:(Entry *)value;
- (void) removeEntriesObject:(Entry *)value;
- (void) addEntries:(NSSet *)value;
- (void) removeEntries:(NSSet *)value;

@end