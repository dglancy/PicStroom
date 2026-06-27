//
//  PicStroomStatusLabel.h
//  PicStroom
//
//  Created by Damien Glancy on 16/05/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PicStroomSupervisor;

@interface PicStroomStatusLabel : UILabel {

    PicStroomSupervisor *stroomSupervisor;

}
@property (nonatomic, retain) PicStroomSupervisor *stroomSupervisor;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateStatus:(NSString *)status;
- (void) clearStatus;
- (void) highlightStatus;
- (void) unhighlighStatus;
- (BOOL) isSet;

@end