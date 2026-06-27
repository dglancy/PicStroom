//
//  PicStroomStatusLabel.m
//  PicStroom
//
//  Created by Damien Glancy on 16/05/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomStatusLabel.h"
#import "PicStroomSupervisor.h"
#import "PicStroomNoImagesFoundViewController.h"
#import "Stroom.h"


@implementation PicStroomStatusLabel
@synthesize stroomSupervisor;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Override drawTextInRect
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [stroomSupervisor release];
    [super dealloc];
}

- (void) drawTextInRect:(CGRect)rect {
    CGSize myShadowOffset = CGSizeMake(5, 5);
    float myColorValues[] = { 0, 0, 0, .75 };

    CGContextRef myContext = UIGraphicsGetCurrentContext();

    CGContextSaveGState(myContext);

    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);
    CGContextSetShadowWithColor(myContext, myShadowOffset, 5, myColor);

    [super drawTextInRect:rect];

    CGColorRelease(myColor);
    CGColorSpaceRelease(myColorSpace);

    CGContextRestoreGState(myContext);
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateStatus:(NSString *)status {
    if (self.stroomSupervisor.noImagesFoundController) {
        if ([self.stroomSupervisor.currentThumbnailUUIDs count] == 0) {
            self.stroomSupervisor.noImagesFoundController.view.hidden = YES;
        }
    }
    self.text = status;
}

- (void) clearStatus {
    self.text = BLANK_STRING;
    [self unhighlighStatus];
}

- (void) highlightStatus {
    self.textColor = [UIColor colorWithRed:255.0 / 255.0 green:125.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
}

- (void) unhighlighStatus {
    self.textColor = [UIColor whiteColor];
    if (self.stroomSupervisor.noImagesFoundController) {
        if ([self.stroomSupervisor.currentThumbnailUUIDs count] == 0) {
            if ([self.stroomSupervisor.stroom.justAddedMarker boolValue] == NO) {
                self.stroomSupervisor.noImagesFoundController.view.hidden = NO;
            }
        }
    }
}

- (BOOL) isSet {
    if (self.text != nil && [self.text length]>0) {
        return YES;
    } else {
        return NO;
    }
}

@end