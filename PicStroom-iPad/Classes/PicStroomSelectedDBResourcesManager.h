//
//  PicStroomSelectedDBResourcesManager.h
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBMetadata;

@interface PicStroomSelectedDBResourcesManager : NSObject {
    NSMutableArray *selectedDBResources;
}
@property (nonatomic, retain) NSMutableArray *selectedDBResources;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton Init
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomSelectedDBResourcesManager *) currentManager;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) reset;
- (NSMutableArray *) getSelectedResources;
- (void) addSelectedResource:(NSString *)path;
- (void) removeSelectedResource:(NSString *)path;
- (BOOL) isAlreadySelected:(NSString *)path;

@end
