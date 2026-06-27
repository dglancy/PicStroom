//
//  PicStroomSupervisor.m
//  PicStroom
//
//  Created by Damien Glancy on 05/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomManager.h"
#import "PicStroomAppDelegate.h"
#import "PicStroomSyncStroomManager.h"
#import "PicStroomSupervisor.h"
#import "PicStroomImageProcessor.h"
#import "PicStroomImageProcessor.h"
#import "PicStroomThumbnailButton.h"
#import "PicStroomViewController.h"
#import "PicStroomCellView.h"
#import "PicStroomNoImagesFoundViewController.h"
#import "PicStroomStatusLabel.h"
#import "PicStroomDateLabel.h"
#import "NSNotificationCenter+NSNotificationCenterAdditions.h"

#import "NSOperationQueue+CWSharedQueue.h"
#import "Reachability.h"

#import "Stroom.h"
#import "Entry.h"
#import "Picture.h"

@implementation PicStroomSupervisor
@synthesize currentState;
@synthesize stroom;
@synthesize currentThumbnailUUIDs;
@synthesize currentRawPictureUUIDs;
@synthesize currentThumbnailWidths;
@synthesize dateMarkerUUIDs;
@synthesize uniqueDateRegister;
@synthesize currentEntireThumbnaiLength;
@synthesize frame;
@synthesize stroomCellView;
@synthesize scrollView;
@synthesize labelView;
@synthesize stroomNameLabel;
@synthesize miniIconImageView;
@synthesize noImagesFoundController;
@synthesize statusLabel;
@synthesize syncPictureCount;
@synthesize syncStroomManager;
@synthesize recycledThumbnails;
@synthesize visibleThumbnails;
@synthesize bounceCount;
@synthesize endOfStroomView;
@synthesize endOfStroomLabel;
@synthesize endOfStroomImageView;

@synthesize gestureRecognizer;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) init {
    if ((self = [super init])) {
        self.currentThumbnailUUIDs = [[[NSMutableArray alloc] init] autorelease];
        self.currentRawPictureUUIDs = [[[NSMutableArray alloc] init] autorelease];
        self.currentThumbnailWidths = [[[NSMutableArray alloc] init] autorelease];
        self.dateMarkerUUIDs = [[[NSMutableArray alloc] init] autorelease];
        self.uniqueDateRegister = [[[NSMutableArray alloc] init] autorelease];
        currentEntireThumbnaiLength = 0;

        syncPictureCount = 0;

        recycledThumbnails = [[NSMutableSet alloc] init];
        visibleThumbnails = [[NSMutableSet alloc] init];

        bounceCount = 0;
        endOfStroomLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -2, 60, 20)];
        endOfStroomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 2, 15)];
        endOfStroomView = [[UIView alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncStartStroomNotification:) name:NOTIF_SYNC_START_STROOM object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncNewPictureFoundNotification:) name:NOTIF_SYNC_NEW_PICTURE_FOUND object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncEndStroomNotification:) name:NOTIF_SYNC_END_STROOM object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncPictureRemovedNotification:) name:NOTIF_SYNC_PICTURE_REMOVED object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_SYNC_START_STROOM object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_SYNC_NEW_PICTURE_FOUND object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_SYNC_END_STROOM object:nil];

    [currentThumbnailUUIDs release];
    [currentRawPictureUUIDs release];
    [currentThumbnailWidths release];
    [dateMarkerUUIDs release];
    [uniqueDateRegister release];
    
    [stroomCellView release];
    [scrollView release];
    [labelView release];
    [stroomNameLabel release];
    [miniIconImageView release];
    [noImagesFoundController release];

    [statusLabel release];

    [endOfStroomView release];
    [endOfStroomLabel release];
    [endOfStroomImageView release];

    [recycledThumbnails release];
    [visibleThumbnails release];

    [stroom release];

    DebugLog(@"StroomSupervisor dealloc()");
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View controller lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    DebugLog(@"view did load on stroom supervisor");
    self.view = [self getStroomViewForCell];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    DebugLog(@"view did unload on stroom supervisor");
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notification handlers (always run on main thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleSyncStartStroomNotification:(NSNotification *)notification {
    NSManagedObjectContext *context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    Stroom *notificationStroom = (Stroom *)[context objectWithID:[notification object]];

    if (notificationStroom == self.stroom) {
        if (currentState == StroomStateNewUpdating) {
            [self.statusLabel unhighlighStatus];
            [self.statusLabel updateStatus:@"Adding"];
        } else {
            [self.statusLabel unhighlighStatus];
            [self.statusLabel updateStatus:@"Updating"];
        }
    }
}

- (void) handleSyncNewPictureFoundNotification:(NSNotification *)notification {
    NSManagedObjectContext *context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    Stroom *notificationStroom = (Stroom *)[context objectWithID:[notification object]];

    if (notificationStroom == self.stroom) {
        self.syncPictureCount++;

        if (self.syncPictureCount == 1) {
            [self.statusLabel updateStatus:[NSString stringWithFormat:@"%d new image", syncPictureCount]];
        } else {
            [self.statusLabel updateStatus:[NSString stringWithFormat:@"%d new images", syncPictureCount]];
        }
        if (currentState == StroomStateNewUpdating && (!scrollView.dragging)) {
            [self getLatestPictures];
            [self tileThumbnails];
        }
    }
}

- (void) handleSyncEndStroomNotification:(NSNotification *)notification {
    NSManagedObjectContext *context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    Stroom *notificationStroom = (Stroom *)[context objectWithID:[notification object]];

    if (notificationStroom == self.stroom) {
        if (!self.noImagesFoundController) {
            if ([currentThumbnailUUIDs count] == 0) {
                if (![self.stroom.justAddedMarker boolValue]) {
                    self.noImagesFoundController.view.hidden = NO;
                }
            }
        }

        if (self.syncPictureCount == 0) {
            [self.statusLabel unhighlighStatus];
            [self.statusLabel updateStatus:@"No new images"];
            self.currentState = StroomStateNothingToUpdate;
            [self.statusLabel performSelector:@selector(clearStatus) withObject:nil afterDelay:1.5];
        } else {
            if (self.currentState == StroomStateNewUpdating) {
                self.currentState = StroomStateUptodate;
                [self.statusLabel clearStatus];
                return;
            } else {
                self.currentState = StroomStateUpdatesAvailable;

                [self.statusLabel highlightStatus];
                [self getLatestPictures];
                [self.recycledThumbnails removeAllObjects];
                [self.visibleThumbnails removeAllObjects];
                [self tileThumbnails];
                [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
                self.currentState = StroomStateUptodate;
            }
        }
    }
}

- (void) handleSyncPictureRemovedNotification:(NSNotification *)notification {
    NSManagedObjectContext *context =  [(PicStroomAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    Stroom *notificationStroom = (Stroom *)[context objectWithID:[notification object]];
    
    if (notificationStroom == self.stroom) {
        // entire stream needs to be redrawn
        [self getLatestPictures];
        [self.recycledThumbnails removeAllObjects];
        
        for(PicStroomThumbnailButton *thumbnails in self.visibleThumbnails) {
            [thumbnails removeFromSuperview];
        }
        
        [self.visibleThumbnails removeAllObjects];
        [self tileThumbnails];
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        self.currentState = StroomStateUptodate;
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync (always run on a background thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isCancelled"]) {
        if (self.syncStroomManager) {
            [self.syncStroomManager cancelSync];
        }
    }
}

- (void) cancelSync {
    if (self.syncStroomManager) {
        [self.syncStroomManager cancelSync];
    }
    
}

- (void) startSyncInBackgroundQueue {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"No network available, therefore background sync request is cancelled.");
    } else {
        [self performSelectorInBackgroundQueue:@selector(sync:) withObject:[stroom objectID]];
    }
}

- (void) sync:(NSManagedObjectID *)stroomObjectID {
    if ([self.stroom.type intValue] == StroomTypeStarred) {
        return;
    }
    
    //UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];

    if (self.currentState == StroomStateNew) {
        self.currentState = StroomStateNewUpdating;
    } else if (self.currentState == StroomStateQueued || self.currentState == StroomStateNothingToUpdate || self.currentState == StroomStateUptodate) {
        self.currentState = StroomStateUpdating;
    } else {
        return;
    }

    self.syncPictureCount = 0;
    self.syncStroomManager = [[[PicStroomSyncStroomManager alloc] init] autorelease];
    [self.syncStroomManager updateStroom:stroomObjectID];
    self.syncStroomManager = nil;
    
    //[[UIApplication sharedApplication] endBackgroundTask:bgTask];
}

- (void) getLatestPictures {
    if ([self.currentThumbnailUUIDs count] > 0) {     // reset local storage
        self.currentEntireThumbnaiLength = 0;
        [self.currentThumbnailWidths removeAllObjects];
        [self.currentThumbnailUUIDs removeAllObjects];
        [self.currentRawPictureUUIDs removeAllObjects];
        [self.uniqueDateRegister removeAllObjects];
        [self.dateMarkerUUIDs removeAllObjects];
    }
        
    NSDateFormatter *dayFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dayFormat setDateFormat:@"dd"];
    NSDateFormatter *monthFormat = [[[NSDateFormatter alloc] init] autorelease];
    [monthFormat setDateFormat:@"MMM"];
    NSDateFormatter *yearFormat = [[[NSDateFormatter alloc] init] autorelease];
    [yearFormat setDateFormat:@"YYYY"];
    
    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
    NSArray *pictures = [stroomManager getAllPicturesForStroom:[stroom objectID]];
    
    for (Picture *picture in pictures) {
        [self.currentThumbnailUUIDs addObject:picture.thumbnailUUID];
        [self.currentRawPictureUUIDs addObject:picture.rawPictureUUID];
        [self.currentThumbnailWidths addObject:picture.thumbWidth];
        
        if (([self.stroom.type intValue] != StroomTypeStarred) && picture.date) {
            NSString *potentialUniqueDate = [NSString stringWithFormat:@"%@$%@$%@", [[dayFormat stringFromDate:picture.date] lowercaseString], [[monthFormat stringFromDate:picture.date] lowercaseString], [[yearFormat stringFromDate:picture.date] lowercaseString]];
            if (![self.uniqueDateRegister containsObject:potentialUniqueDate]) {
                [self.dateMarkerUUIDs addObject:picture.thumbnailUUID];
                [self.uniqueDateRegister addObject:potentialUniqueDate];
            }
        }

        self.currentEntireThumbnaiLength += [picture.thumbWidth intValue];
    }
    [stroomManager release];
    [self resizeCellView];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) stroomTitleTapped {
    PicStroomAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    if (appDelegate.currentNetworkStatus == NotReachable) {
        DebugLog(@"No network available, therefore user sync request is cancelled.");
        return;
    }
    if (self.currentState == StroomStateNew || self.currentState == StroomStateUptodate || self.currentState == StroomStateNothingToUpdate) {
        self.currentState = StroomStateQueued;
        [self.statusLabel updateStatus:@"Waiting"];
        [NSTimer scheduledTimerWithTimeInterval:1.8 target:self selector:@selector(startSyncInBackgroundQueue) userInfo:nil repeats:NO];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizers
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) createGestureRecognizers {
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stroomTitleTapped)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [labelView addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table View Cell Drawing (always run on main thread)
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) refreshDisplay:(CGRect)newBounds {
    DebugLog(@"StroomSupervisor is refreshing display for stroom %@ (bounds: x=%f y=%f w=%f h=%f)", stroom.title, newBounds.origin.x, newBounds.origin.y, newBounds.size.width, newBounds.size.height);
    // special: if near end of stroom and now bounds are wider. then for new offset to match new end of stroom

    CGPoint existingOffset = scrollView.contentOffset;
    CGRect oldFrame = scrollView.bounds;

    scrollView.frame = newBounds;
    scrollView.bounds = newBounds;

    if ((oldFrame.size.width < newBounds.size.width) && (existingOffset.x > (scrollView.contentSize.width - newBounds.size.width))) {
        scrollView.contentOffset = CGPointMake(scrollView.contentSize.width - newBounds.size.width, 0);
    } else {
        scrollView.contentOffset = existingOffset;
    }
    [self tileThumbnails];
}


- (CGSize) resizeCellView {
    scrollView.contentSize = CGSizeMake([self calculateContentOffsetWidth], 120);
    return scrollView.contentSize;
}

- (UIView *) getStroomViewForCell {
    if (!stroomCellView) {
        [self createCellView];
    }

    [self tileThumbnails];
    return stroomCellView;
}

- (void) createCellView {
    DebugLog(@"Stroom Supervisor is creating cell view for %@", stroom.title);

    self.stroomCellView = [[[PicStroomCellView alloc] initWithFrame:frame] autorelease];
    self.stroomCellView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.stroomCellView.backgroundColor = [UIColor colorWithRed:26.0f / 255.0f green:26.0f / 255.0f blue:26.0f / 255.0f alpha:1.0f];

    self.stroomCellView.opaque = YES;

    self.scrollView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
    CGSize startingSize = CGSizeMake([self calculateContentOffsetWidth], 120);
    self.scrollView.contentSize = startingSize;
    self.scrollView.backgroundColor = [UIColor colorWithRed:26.0f / 255.0f green:26.0f / 255.0f blue:26.0f / 255.0f alpha:1.0f];
    self.scrollView.opaque = YES;
    self.scrollView.bounces = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.pagingEnabled = NO;
    self.scrollView.delegate = self;
    [self.stroomCellView addSubview:self.scrollView];

    self.labelView = [[[UIView alloc] initWithFrame:CGRectMake(-2, 101, frame.size.width, 19)] autorelease];
    self.stroomNameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(-2, 0, 0, 0)] autorelease];
    if ([self.stroom.type intValue] == StroomTypeStarred) {
        self.stroomNameLabel.textColor = [UIColor blackColor];
        self.stroomNameLabel.backgroundColor = [UIColor colorWithRed:235.0f / 255.0f green:152.0f / 255.0f blue:34.0f / 255.0f alpha:1.0f];
    } else {
        self.stroomNameLabel.textColor = [UIColor whiteColor];
        self.stroomNameLabel.backgroundColor = [UIColor blackColor];
    }
    
    self.stroomNameLabel.font = [UIFont fontWithName:BOLD_FONT size:14.0];
    self.stroomNameLabel.layer.cornerRadius = 4;
    [self.labelView addSubview:self.stroomNameLabel];

    self.miniIconImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
    self.miniIconImageView.backgroundColor = [UIColor clearColor];
    [self.labelView addSubview:self.miniIconImageView];
    [self.stroomCellView addSubview:self.labelView];

    self.statusLabel = [[[PicStroomStatusLabel alloc] initWithFrame:CGRectMake(9, 50, 250, 30)] autorelease];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.font = [UIFont fontWithName:BOLD_FONT size:24.0];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.stroomSupervisor = self;
    
    if ([self.stroom.type intValue] != StroomTypeStarred) {
        [self.stroomCellView addSubview:self.statusLabel];
    }
        
    if (self.currentState == StroomStateNew || self.currentState == StroomStateQueued) {
        [self.statusLabel updateStatus:@"Waiting"];
    }

    self.noImagesFoundController = [[[PicStroomNoImagesFoundViewController alloc] initWithNibName:@"PicStroomNoImagesFoundViewController" bundle:nil] autorelease];
    self.noImagesFoundController.view.hidden = YES;
    [self.scrollView addSubview:self.noImagesFoundController.view];

    [self updateStroomNameLabelWithText:stroom.title];

    [self createGestureRecognizers];
}

- (void) updateStroomNameLabelWithText:(NSString *)text {
    stroomNameLabel.text = [NSString stringWithFormat:@"   %@", stroom.title];
    CGSize textSize = [stroomNameLabel.text sizeWithFont:[stroomNameLabel font]];
    stroomNameLabel.frame = CGRectMake(-2, 0, textSize.width + 26, 20);

    miniIconImageView.frame = CGRectMake(textSize.width + 2, 4, 15, 13);
    if ([stroom.type intValue] == StroomTypeRSS) {
        miniIconImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_stroom" ofType:@"png"]];
    } else if ([stroom.type intValue] == StroomTypeDropbox) {
        miniIconImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_dropbox" ofType:@"png"]];
    } else if ([stroom.type intValue] == StroomTypeStarred) {
        miniIconImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"starred-banner-small" ofType:@"png"]];
    }
}

- (BOOL) isDisplayingThumbForIndex:(NSUInteger)index {
    BOOL foundThumbnail = NO;

    for (PicStroomThumbnailButton *thumbnail in visibleThumbnails) {
        if (thumbnail.index == index) {
            foundThumbnail = YES;
            break;
        }
    }
    return foundThumbnail;
}

- (PicStroomThumbnailButton *) dequeueRecycledThumbnail {
    PicStroomThumbnailButton *thumbnail = [recycledThumbnails anyObject];

    if (thumbnail) {
        [[thumbnail retain] autorelease];
        [recycledThumbnails removeObject:thumbnail];
    }
    return thumbnail;
}

- (void) tileThumbnails {
    if (!stroomCellView) {
        return;
    } else if ([currentThumbnailUUIDs count] == 0) {
        if ([self.stroom.justAddedMarker boolValue] == YES) {
            self.noImagesFoundController.view.hidden = YES;
        } /*else if (!self.currentState == StroomStateNew || !self.currentState == StroomStateNewUpdating || !self.currentState == StroomStateUpdating) {
            // self.noImagesFoundController.view.hidden=NO;
        }*/
        return;
    } else {
        self.noImagesFoundController.view.hidden = YES;
    }

    CGPoint offset = scrollView.contentOffset;
    NSInteger firstNeededThumbnailIndex = [self startImageNumberForOffset:offset.x];
    NSInteger lastNeededThumbnailIndex  = [self endImageNumberForOffset:offset.x];
    
    // Recycle no-longer-visible thumbs
    for (PicStroomThumbnailButton *thumbnail in visibleThumbnails) {
        if (thumbnail.index < firstNeededThumbnailIndex || thumbnail.index > lastNeededThumbnailIndex) {
            [recycledThumbnails addObject:thumbnail];
            if (thumbnail.dayLabel) {
                [thumbnail.dayLabel removeFromSuperview];
                thumbnail.dayLabel = nil;
            }
            if (thumbnail.monthLabel) {
                [thumbnail.monthLabel removeFromSuperview];
                thumbnail.monthLabel = nil;
            }
            [thumbnail removeFromSuperview];
        }
    }
    [visibleThumbnails minusSet:recycledThumbnails];

    NSDateFormatter *dayFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dayFormat setDateFormat:@"dd"];
    NSDateFormatter *monthFormat = [[[NSDateFormatter alloc] init] autorelease];
    [monthFormat setDateFormat:@"MMM"];

    // add missing thumbs
    for (NSInteger index = firstNeededThumbnailIndex; index <= lastNeededThumbnailIndex; index++) {
        if ((index >= 0) && (index < [currentThumbnailUUIDs count])) {
            if (![self isDisplayingThumbForIndex:index]) {
                PicStroomThumbnailButton *thumbnailBtn = [self dequeueRecycledThumbnail];
                if (thumbnailBtn == nil) {
                    thumbnailBtn = [[[PicStroomThumbnailButton alloc] init] autorelease];
                }

                // place thumbnail on scrollview
                // DebugLog(@"thumbnail for %@ idx=%d",stroom.title, index);
                thumbnailBtn.index = index;
                thumbnailBtn.opaque = YES;
                NSString *thumbnailUUID = [currentThumbnailUUIDs objectAtIndex:index];

                UIImage *thumbnailImage = [[PicStroomImageProcessor currentProcessor] getThumbnail:thumbnailUUID];
                thumbnailBtn.frame = CGRectMake([self calculateOffsetForImageNumber:index], 0, [[currentThumbnailWidths objectAtIndex:index] intValue], PICTURE_HEIGHT_PT);
                [thumbnailBtn setImage:thumbnailImage forState:UIControlStateNormal];
                thumbnailBtn.stroomSupervisor = self;
                [thumbnailBtn addTarget:self.parentViewController action:@selector(launchFullScreenPhotoView:) forControlEvents:UIControlEventTouchUpInside];

                if ([dateMarkerUUIDs containsObject:thumbnailUUID]) {
                    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
                    Picture *picture = [stroomManager getPictureFromThumbnailUUID:thumbnailUUID];
                    [stroomManager release];

                    thumbnailBtn.dayLabel = [[[PicStroomDateLabel alloc] initWithFrame:CGRectMake(8, 2, 50, 19)] autorelease];
                    thumbnailBtn.dayLabel.backgroundColor = [UIColor clearColor];
                    thumbnailBtn.dayLabel.textColor = [UIColor whiteColor];
                    thumbnailBtn.dayLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
                    thumbnailBtn.dayLabel.text = [dayFormat stringFromDate:picture.date];
                    [thumbnailBtn addSubview:thumbnailBtn.dayLabel];

                    thumbnailBtn.monthLabel = [[[PicStroomDateLabel alloc] initWithFrame:CGRectMake(8, 14, 50, 19)] autorelease];
                    thumbnailBtn.monthLabel.backgroundColor = [UIColor clearColor];
                    thumbnailBtn.monthLabel.textColor = [UIColor whiteColor];
                    thumbnailBtn.monthLabel.font = [UIFont fontWithName:STANDARD_FONT size:10.0];
                    thumbnailBtn.monthLabel.text = [[monthFormat stringFromDate:picture.date] lowercaseString];
                    [thumbnailBtn addSubview:thumbnailBtn.monthLabel];
                }

                [self.scrollView addSubview:thumbnailBtn];
                [self.visibleThumbnails addObject:thumbnailBtn];
            }
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.currentState == StroomStateNewUpdating || self.currentState == StroomStateUpdating) {
        return;
    }
    
    if ([self.statusLabel isSet]) {
        [self.statusLabel clearStatus];
    }

    if (self.scrollView.contentOffset.x >= (self.scrollView.contentSize.width - self.scrollView.bounds.size.width)) { // at end of stroom
        if (!self.scrollView.decelerating) {
            self.bounceCount++;
            if (self.bounceCount == 1) {
                self.endOfStroomView.frame = CGRectMake(self.scrollView.contentSize.width + 20, 52, 2, PICTURE_HEIGHT_PT);
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 32.0, PICTURE_HEIGHT_PT);
                self.endOfStroomImageView.frame = CGRectMake(0, 0, 2, 15);
                self.endOfStroomImageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"end-of-stroom" ofType:@"png"]];
                [self.endOfStroomView addSubview:endOfStroomImageView];
                [self.scrollView addSubview:self.endOfStroomView];
            } else if (self.bounceCount == 2) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 65.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, -2, 60, 20)] autorelease];
                self.endOfStroomLabel.text = @"the end";
                self.endOfStroomLabel.textColor = [UIColor lightGrayColor];
                self.endOfStroomLabel.backgroundColor = [UIColor clearColor];
                self.endOfStroomLabel.font = [UIFont fontWithName:BOLD_FONT size:14.0];
                [self.endOfStroomView addSubview:endOfStroomLabel];
            } else if (self.bounceCount == 3) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 45.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.frame = CGRectMake(10, -2, 2000, 20);
                self.endOfStroomLabel.text = @"this is the end";
            } else if (self.bounceCount == 4) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 45.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end";
            } else if (self.bounceCount == 5) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 75.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can";
            } else if (self.bounceCount == 6) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 90.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling";
            } else if (self.bounceCount == 7) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 80.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling this stream";
            } else if (self.bounceCount == 8) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 135.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling this stream but all you will see";
            } else if (self.bounceCount == 9) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 140.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling this stream but all you will see is this text getting";
            } else if (self.bounceCount == 10) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 115.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling this stream but all you will see is this text getting longer and longer";
            } else if (self.bounceCount == 11) {
                self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 120.0, PICTURE_HEIGHT_PT);
                self.endOfStroomLabel.text = @"this is really the end, so you can keep pulling this stream but all you will see is this text getting longer and longer and then disappear";
            } else if (self.bounceCount == 12) {
                [self clearEndOfStroomView];
            }
        }
    } else {
        [self clearEndOfStroomView];
    }
}

- (void) clearEndOfStroomView {
    [UIView animateWithDuration:0.5 animations:^{
         self.scrollView.contentSize = CGSizeMake ([self calculateContentOffsetWidth], PICTURE_HEIGHT_PT);
         [self.endOfStroomImageView removeFromSuperview];
         [self.endOfStroomView removeFromSuperview];
         self.endOfStroomLabel.text = @"";
     }];
    self.bounceCount = 0;

}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tileThumbnails];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) imageNumberForOffset:(CGFloat)offset {
    NSInteger runningTotalPT = 0;

    for (NSInteger count = 0; count < [currentThumbnailWidths count]; count++) {
        runningTotalPT += [[currentThumbnailWidths objectAtIndex:count] intValue] + SPACER_BETWEEN_STROOM_IMAGES_PT;
        if (runningTotalPT > offset) {
            return count;
        }
    }
    return [currentThumbnailWidths count] - 1;
}

- (NSInteger) calculateOffsetForImageNumber:(NSInteger)imageNumber {
    NSInteger runningTotalPT = 0;

    for (NSInteger count = 0; count < imageNumber; count++) {
        runningTotalPT += [[currentThumbnailWidths objectAtIndex:count] intValue] + SPACER_BETWEEN_STROOM_IMAGES_PT;
    }
    return runningTotalPT;
}

- (NSUInteger) calculateContentOffsetWidth {
    NSUInteger spacerWidth = SPACER_BETWEEN_STROOM_IMAGES_PT *[currentThumbnailWidths count];

    if ([currentThumbnailWidths count] > 1) {
        spacerWidth -= SPACER_BETWEEN_STROOM_IMAGES_PT;
    }
    return currentEntireThumbnaiLength + spacerWidth;
}

- (NSInteger) startImageNumberForOffset:(CGFloat)offset {
    return [self imageNumberForOffset:offset];
}

- (NSInteger) endImageNumberForOffset:(CGFloat)offset {
    NSInteger i = [self imageNumberForOffset:offset + self.scrollView.bounds.size.width];

    return i;
}

@end
