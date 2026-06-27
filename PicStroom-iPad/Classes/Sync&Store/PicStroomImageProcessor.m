//
//  PicStroomImageCacheManager.m
//  PicStroom
//
//  Created by Damien Glancy on 26/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#include <sys/param.h>
#include <sys/mount.h>

#import "PicStroomImageProcessor.h"
#import "ASIHTTPRequest.h"

static PicStroomImageProcessor *processor;

@implementation PicStroomImageProcessor
@synthesize imageCacheDirectory;
@synthesize thumbnailImageCacheDirectory;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton Init
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomImageProcessor *) currentProcessor {
    @synchronized(self) {
        if (!processor) {
            processor = [[[self class] alloc] init];
            processor.imageCacheDirectory = [NSString stringWithFormat:@"%@/Library/ImageStore/Images", NSHomeDirectory()];
            processor.thumbnailImageCacheDirectory = [NSString stringWithFormat:@"%@/Library/ImageStore/Thumbnails", NSHomeDirectory()];
            [[NSFileManager defaultManager] createDirectoryAtPath:processor.imageCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
            [[NSFileManager defaultManager] createDirectoryAtPath:processor.thumbnailImageCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }

    return processor;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Download resources
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) syncDownloadImageForURL:(NSURL *)url toPath:(NSString *)path {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request addRequestHeader:@"User-Agent" value:USER_AGENT];
    [request setTimeOutSeconds:SYNC_TIMEOUT_IN_SECS];
    request.useCookiePersistence = NO;
    [ASIHTTPRequest setSessionCookies:nil];
    [request setDownloadDestinationPath:path];
    [request startSynchronous];
    NSError *downloadError = [request error];
    if (downloadError) {
        DebugLog(@"Download error occured getting image at %@", url);
        return NO;
    } else {
        return YES;
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image processing functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *) createTempImageOnDiskFromImage:(UIImage *)image withFilename:(NSString *)filename {
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *tempFileName = [NSTemporaryDirectory () stringByAppendingPathComponent:filename];

    [imageData writeToFile:tempFileName atomically:NO];

    return tempFileName;
}

- (CGImageSourceRef) createImageSourceFromURL:(NSURL *)imageLocationOnDisk {
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageLocationOnDisk, NULL);

    if (!imageSource) {
        DebugLog(@"Issue creating image source for image at: %@", imageLocationOnDisk);
        return nil;
    } else {
        [(id) imageSource autorelease];
        return imageSource;
    }
}

- (CGSize) getImageSizeFromImageSource:(CGImageSourceRef)imageSource {
    NSDictionary *imageSourceOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (id)kCFBooleanFalse, (id)kCGImageSourceShouldCache,
                                        nil];

    NSDictionary *imageProperties = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)imageSourceOptions);
    NSString *height = (NSString *)[imageProperties objectForKey:@"PixelHeight"];
    NSString *width = (NSString *)[imageProperties objectForKey:@"PixelWidth"];

    [imageProperties release];
    return CGSizeMake([width floatValue], [height floatValue]);
}

- (CGImageRef) createIpadSizedImageRefFromImageSource:(CGImageSourceRef)imageSource withSourceSizeOf:(CGSize)imageSourceSize {
    NSDictionary *imageCreationOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                          [NSNumber numberWithInt:1024],  kCGImageSourceThumbnailMaxPixelSize,
                                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                                          nil];

    CGImageRef image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)imageCreationOptions);

    if (!image) {
        return nil;
    } else {
        [(id) image autorelease];
        return image;
    }
}


- (CGImageRef) createThumbnailImageRefFromImageSource:(CGImageSourceRef)imageSource withSourceSizeOf:(CGSize)imageSourceSize {
    float sizef = 120.0f;

    if (imageSourceSize.width > imageSourceSize.height) { // landscape
        sizef = imageSourceSize.width / (imageSourceSize.height / 120);
    }

    int size = [[NSNumber numberWithFloat:ceil(sizef) + 1] intValue];

    NSDictionary *thumbnailCreationOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                              (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                              (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                              [NSNumber numberWithInt:size],  kCGImageSourceThumbnailMaxPixelSize,
                                              (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                                              nil];

    CGImageRef thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)thumbnailCreationOptions);
    if (!thumbnailImage) {
        return nil;
    } else {
        [(id) thumbnailImage autorelease];
        return thumbnailImage;
    }
}

- (void) saveThumbnailImageRefToDisk:(CGImageRef)thumbnailImage withUUID:(NSString *)uuid {
    if (!thumbnailImage || !uuid) {
        return;
    }

    NSDictionary *thumbnailDestinationWriteOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithInt:1], (id)kCGImagePropertyOrientation,
                                                      (id)kCFBooleanFalse, (id)kCGImagePropertyHasAlpha,
                                                      [NSNumber numberWithInt:0.6],  kCGImageDestinationLossyCompressionQuality,
                                                      nil];

    CGImageDestinationRef thumbnailDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[self getThumbnailPathForUUID:uuid]], (CFStringRef)@"public.png", 1, nil);
    if (thumbnailDestination) {
        CGImageDestinationAddImage(thumbnailDestination, thumbnailImage, (CFDictionaryRef)thumbnailDestinationWriteOptions);
        CGImageDestinationFinalize(thumbnailDestination);
        CFRelease(thumbnailDestination);
    }
}

- (void) saveRawImageRefToDisk:(CGImageRef)image withUUID:(NSString *)uuid andType:(NSString *)type {
    if (!uuid || !type) {
        return;
    }

    NSDictionary *imageDestinationWriteOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  [NSNumber numberWithInt:1], (id)kCGImagePropertyOrientation,
                                                  (id)kCFBooleanFalse, (id)kCGImagePropertyHasAlpha,
                                                  [NSNumber numberWithInt:1.0],  kCGImageDestinationLossyCompressionQuality,
                                                  nil];

    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[self getRawImagePathForUUID:uuid]], (CFStringRef)type, 1, nil);
    if (imageDestination) {
        CGImageDestinationAddImage(imageDestination, image, (CFDictionaryRef)imageDestinationWriteOptions);
        CGImageDestinationFinalize(imageDestination);
        CFRelease(imageDestination);
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Util functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSNumber *) calculateAvailableDiskSpace {
    struct statfs tStats;

    statfs([[NSString stringWithFormat:@"%@", NSHomeDirectory()] UTF8String], &tStats);
    float availableDisk = (float)(tStats.f_bavail * tStats.f_bsize);
    float rawAvailableDisk = availableDisk;

    /*
     * NSString *sizeType=nil;
     * if (availableDisk > 1024) {
     *          //Kilobytes
     *          availableDisk = availableDisk / 1024;
     *          sizeType = @" KB";
     *  }
     *
     *  if (availableDisk > 1024) {
     *          //Megabytes
     *          availableDisk = availableDisk / 1024;
     *          sizeType = @" MB";
     *  }
     *
     *  if (availableDisk > 1024) {
     *          //Gigabytes
     *          availableDisk = availableDisk / 1024;
     *          sizeType = @" GB";
     *  }
     *
     * DebugLog(@"Available disk space:%@ (in bytes:%f)",[[NSString stringWithFormat:@"%.2f", availableDisk] stringByAppendingString:sizeType], rawAvailableDisk);
     */

    return [NSNumber numberWithFloat:rawAvailableDisk];
}

- (void) deleteImageFromDisk:(NSString *)uuid {
    NSString *path = [NSString stringWithFormat:@"%@/%@", processor.imageCacheDirectory, uuid];

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    DebugLog(@"Deleted image file: %@", path);
}

- (void) deleteThumbnailFromDisk:(NSString *)uuid {
    NSString *path = [NSString stringWithFormat:@"%@/%@", processor.thumbnailImageCacheDirectory, uuid];

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    DebugLog(@"Deleted thumbnail file: %@", path);
}

- (NSString *) getThumbnailPathForUUID:(NSString *)uuid {
    return [NSString stringWithFormat:@"%@/%@", thumbnailImageCacheDirectory, uuid];
}

- (NSString *) getRawImagePathForUUID:(NSString *)uuid {
    return [NSString stringWithFormat:@"%@/%@", imageCacheDirectory, uuid];
}

- (UIImage *) getThumbnail:(NSString *)uuid {
    NSString *filename = [NSString stringWithFormat:@"%@/%@", thumbnailImageCacheDirectory, uuid];

    return [UIImage imageWithContentsOfFile:filename];
}

- (UIImage *) getImage:(NSString *)uuid {
    NSString *filename = [NSString stringWithFormat:@"%@/%@", imageCacheDirectory, uuid];

    return [UIImage imageWithContentsOfFile:filename];
}

- (NSString *) generateUUID {
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

- (NSString *) thumbnailKeyStringFromImageURL:(NSURL *)imageURL {
    return [NSString stringWithFormat:@"thumb-%@", [imageURL absoluteString]];
}

- (NSURL *) thumbnailKeyURLFromImageURL:(NSURL *)imageURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"thumb-%@", [imageURL absoluteString]]];
}

@end
