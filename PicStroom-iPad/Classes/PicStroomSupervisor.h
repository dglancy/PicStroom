//
//  PicStroomSupervisor.h
//  PicStroom
//
//  Created by Damien Glancy on 05/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Stroom;
@class PicStroomThumbnailButton;
@class PicStroomViewController;
@class PicStroomCellView;
@class PicStroomSyncStroomManager;
@class PicStroomNoImagesFoundViewController;
@class PicStroomStatusLabel;

@interface PicStroomSupervisor : UIViewController <UIScrollViewDelegate> {
    StroomState currentState;
    Stroom *stroom;
    NSMutableArray *currentThumbnailUUIDs;
    NSMutableArray *currentRawPictureUUIDs;
    NSMutableArray *currentThumbnailWidths;
    NSMutableArray *dateMarkerUUIDs;
    NSMutableArray *uniqueDateRegister;
    NSUInteger currentEntireThumbnaiLength;

    CGRect frame;
    PicStroomCellView *stroomCellView;
    UIScrollView *scrollView;
    UIView *labelView;
    UILabel *stroomNameLabel;
    UIImageView *miniIconImageView;
    PicStroomNoImagesFoundViewController *noImagesFoundController;

    // sync
    NSInteger syncPictureCount;
    PicStroomSyncStroomManager *syncStroomManager;
    PicStroomStatusLabel *statusLabel;
    NSMutableSet *recycledThumbnails;
    NSMutableSet *visibleThumbnails;

    // fun
    NSInteger bounceCount;
    UIView *endOfStroomView;
    UILabel *endOfStroomLabel;
    UIImageView *endOfStroomImageView;

    UITapGestureRecognizer *gestureRecognizer;
}
@property (assign) StroomState currentState;
@property (nonatomic, retain) Stroom *stroom;
@property (nonatomic, retain) NSMutableArray *currentThumbnailUUIDs;
@property (nonatomic, retain) NSMutableArray *currentRawPictureUUIDs;
@property (nonatomic, retain) NSMutableArray *currentThumbnailWidths;
@property (nonatomic, retain) NSMutableArray *dateMarkerUUIDs;
@property (nonatomic, retain) NSMutableArray *uniqueDateRegister;
@property (assign) NSUInteger currentEntireThumbnaiLength;

@property (assign) CGRect frame;
@property (nonatomic, retain) PicStroomCellView *stroomCellView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *labelView;
@property (nonatomic, retain) UILabel *stroomNameLabel;
@property (nonatomic, retain) UIImageView *miniIconImageView;
@property (nonatomic, retain) PicStroomNoImagesFoundViewController *noImagesFoundController;

@property (assign) NSInteger syncPictureCount;
@property (nonatomic, assign) PicStroomSyncStroomManager *syncStroomManager;
@property (nonatomic, retain) PicStroomStatusLabel *statusLabel;
@property (nonatomic, retain) NSMutableSet *recycledThumbnails;
@property (nonatomic, retain) NSMutableSet *visibleThumbnails;

@property (assign) NSInteger bounceCount;
@property (nonatomic, retain) UIView *endOfStroomView;
@property (nonatomic, retain) UILabel *endOfStroomLabel;
@property (nonatomic, retain) UIImageView *endOfStroomImageView;

@property (nonatomic, retain) UITapGestureRecognizer *gestureRecognizer;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notification handlers (always run on main thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleSyncStartStroomNotification:(NSNotification *)notification;
- (void) handleSyncNewPictureFoundNotification:(NSNotification *)notification;
- (void) handleSyncEndStroomNotification:(NSNotification *)notification;
- (void) handleSyncPictureRemovedNotification:(NSNotification *)notification;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync (always run on a background thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) cancelSync;
- (void) startSyncInBackgroundQueue;
- (void) sync:(NSManagedObjectID *)stroomObjectID;
- (void) getLatestPictures;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) stroomTitleTapped;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Updating View Functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) refreshDisplay:(CGRect)newBounds;
- (void) updateStroomNameLabelWithText:(NSString *)text;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizers
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) createGestureRecognizers;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table View Cell Drawing (always run on main thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGSize) resizeCellView;
- (UIView *) getStroomViewForCell;
- (void) createCellView;
- (BOOL) isDisplayingThumbForIndex:(NSUInteger)index;
- (PicStroomThumbnailButton *) dequeueRecycledThumbnail;
- (void) tileThumbnails;
- (void) clearEndOfStroomView;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) imageNumberForOffset:(CGFloat)offset;
- (NSInteger) calculateOffsetForImageNumber:(NSInteger)imageNumber;
- (NSUInteger) calculateContentOffsetWidth;
- (NSInteger) startImageNumberForOffset:(CGFloat)offset;
- (NSInteger) endImageNumberForOffset:(CGFloat)offset;

@end
