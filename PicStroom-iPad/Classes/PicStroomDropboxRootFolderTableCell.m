//
//  PicStroomDropboxRootFolderTableCell.m
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomDropboxRootFolderTableCell.h"

#import "DBMetadata.h"
#import "DBRestClient.h"

@implementation PicStroomDropboxRootFolderTableCell
@synthesize rootFolderView;
@synthesize imageView;
@synthesize imageCounterView;
@synthesize rootFolderPathLabel;
@synthesize rootFolderMetadata;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        thumbnailsLoaded = 0;
        rootFolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        rootFolderView.backgroundColor = [UIColor clearColor];

        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 28, 28)];
        [rootFolderView addSubview:imageView];

        rootFolderPathLabel = [[UILabel alloc] initWithFrame:CGRectMake(38, 8, 425, 30)];
        rootFolderPathLabel.backgroundColor = [UIColor clearColor];
        rootFolderPathLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        [rootFolderView addSubview:rootFolderPathLabel];

        imageCounterView = [[UILabel alloc] init];
        imageCounterView.textColor = [UIColor lightGrayColor];
        imageCounterView.font = [UIFont fontWithName:STANDARD_FONT size:14.0];
        [rootFolderView addSubview:imageCounterView];

        [self.contentView addSubview:rootFolderView];
    }
    return self;
}

- (void) dealloc {
    [rootFolderView release];
    [imageView release];
    [rootFolderPathLabel release];
    [imageCounterView release];
    [rootFolderMetadata release];
    if (restClient) {
        [restClient release];
    }
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Scanner functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showThumbnails {
    NSUInteger imageCount = 0;

    for (DBMetadata *child in self.rootFolderMetadata.contents) {
        NSString *pathExtension = [[child.path pathExtension] lowercaseString];
        if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"png"] || [pathExtension isEqualToString:@"jpeg"]) {
            imageCount++;
        }
    }
    if (imageCount == 0) {
        self.imageCounterView.frame = CGRectMake(38, 32, 400, 20);
        self.imageCounterView.text = @"No images found in this folder";
    } else if (imageCount <= 10) {
        self.imageCounterView.frame = CGRectMake(38, 72, 400, 20);
        if (imageCount == 1) {
            self.imageCounterView.text = [NSString stringWithFormat:@"%d image found in this folder", imageCount];
        } else {
            self.imageCounterView.text = [NSString stringWithFormat:@"%d images found in this folder", imageCount];
        }
        [self loadThumbnails:imageCount];
    } else {
        self.imageCounterView.frame = CGRectMake(38, 72, 400, 20);
        if ((imageCount - 10) == 1) {
            self.imageCounterView.text = @"1 more image found in this folder";
        } else {
            self.imageCounterView.text = [NSString stringWithFormat:@"%d more images found in this folder", imageCount - 10];
        }
        [self loadThumbnails:10];
    }
    DebugLog(@"%d dropbox images found", imageCount);
}

- (void) loadThumbnails:(NSInteger)number {
    DebugLog(@"Loading %d thumbnails(s)", number);
    NSUInteger thumbnailsProcessed = 0;
    for (DBMetadata *child in rootFolderMetadata.contents) {
        if (thumbnailsProcessed == number) {
            return;
        }

        NSString *pathExtension = [[child.path pathExtension] lowercaseString];
        if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"png"] || [pathExtension isEqualToString:@"jpeg"]) {
            [[self restClient] loadThumbnail:child.path ofSize:@"small" intoPath:[NSTemporaryDirectory () stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
            thumbnailsProcessed++;
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox Client
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void) restClient:(DBRestClient *)client loadedThumbnail:(NSString *)destPath {
    @synchronized(self) {
        NSUInteger x = 38;

        if (thumbnailsLoaded > 0) {
            x = 38 + (40 * thumbnailsLoaded);
        }
        UIImageView *thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(x, 38, 32, 32)];
        thumbnail.image = [UIImage imageWithContentsOfFile:destPath];
        [self.rootFolderView addSubview:thumbnail];
        [thumbnail release];
        thumbnailsLoaded++;
    }

    [[NSFileManager defaultManager] performSelector:@selector(removeItemAtPath:error:) withObject:destPath afterDelay:10];
}

- (DBRestClient *) restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end
