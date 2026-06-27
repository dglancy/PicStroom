//
//  PicStroomImageCacheManager.h
//  PicStroom
//
//  Created by Damien Glancy on 26/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

@interface PicStroomImageProcessor : NSObject {
    NSString *imageCacheDirectory;
    NSString *thumbnailImageCacheDirectory;
}
@property (retain) NSString *imageCacheDirectory;
@property (retain) NSString *thumbnailImageCacheDirectory;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton Init
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomImageProcessor *) currentProcessor;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Download resources
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) syncDownloadImageForURL:(NSURL *)url toPath:(NSString *)path;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Image processing functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *) createTempImageOnDiskFromImage:(UIImage *)image withFilename:(NSString *)filename;
- (CGImageSourceRef) createImageSourceFromURL:(NSURL *)imageLocationOnDisk;
- (CGSize) getImageSizeFromImageSource:(CGImageSourceRef)imageSource;
- (CGImageRef) createThumbnailImageRefFromImageSource:(CGImageSourceRef)imageSource withSourceSizeOf:(CGSize)imageSourceSize;
- (CGImageRef) createIpadSizedImageRefFromImageSource:(CGImageSourceRef)imageSource withSourceSizeOf:(CGSize)imageSourceSize;
- (void) saveThumbnailImageRefToDisk:(CGImageRef)thumbnailImage withUUID:(NSString *)uuid;
- (void) saveRawImageRefToDisk:(CGImageRef)image withUUID:(NSString *)uuid andType:(NSString *)type;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Util functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSNumber *) calculateAvailableDiskSpace;
- (void) deleteImageFromDisk:(NSString *)uuid;
- (void) deleteThumbnailFromDisk:(NSString *)uuid;
- (UIImage *) getThumbnail:(NSString *)uuid;
- (UIImage *) getImage:(NSString *)uuid;
- (NSString *) generateUUID;
- (NSString *) getThumbnailPathForUUID:(NSString *)uuid;
- (NSString *) getRawImagePathForUUID:(NSString *)uuid;
- (NSString *) thumbnailKeyStringFromImageURL:(NSURL *)imageURL;
- (NSURL *) thumbnailKeyURLFromImageURL:(NSURL *)imageURL;

@end
