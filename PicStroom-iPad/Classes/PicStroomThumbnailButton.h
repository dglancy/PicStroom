//
//  PicStroomThumbnailButton.h
//  PicStroom
//
//  Created by Damien Glancy on 02/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Stroom;
@class PicStroomSupervisor;
@class PicStroomDateLabel;

@interface PicStroomThumbnailButton : UIButton {
    PicStroomSupervisor *stroomSupervisor;
    NSInteger index;
    PicStroomDateLabel *dayLabel;
    PicStroomDateLabel *monthLabel;
}
@property (nonatomic, assign) PicStroomSupervisor *stroomSupervisor;
@property (assign) NSInteger index;
@property (nonatomic, retain) PicStroomDateLabel *dayLabel;
@property (nonatomic, retain) PicStroomDateLabel *monthLabel;

@end
