//
//  PicStroomFullScreenPhotoScrollView.h
//  PicStroom
//
//  Created by Damien Glancy on 18/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PicStroomFullScreenPhotoScrollView : UIScrollView <UIScrollViewDelegate> {
    UIImageView *imageView;
    NSUInteger index;
}
@property (nonatomic, retain) UIImageView *imageView;
@property (assign) NSUInteger index;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Configure scrollView to display new image
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) displayImage:(UIImage *)image;
- (void) setMaxMinZoomScalesForCurrentBounds;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Methods called during rotation to preserve the zoomScale and the visible portion of the image
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGPoint) pointToCenterAfterRotation;
- (CGFloat) scaleToRestoreAfterRotation;
- (void) restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;

@end
