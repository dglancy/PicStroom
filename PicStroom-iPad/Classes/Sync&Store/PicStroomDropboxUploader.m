//
//  PicStroomDropboxUploader.m
//  PicStroom
//
//  Created by Damien Glancy on 11/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomDropboxUploader.h"
#import "DBRestClient.h"

static PicStroomDropboxUploader *uploader;

@implementation PicStroomDropboxUploader
@synthesize restClient;
@synthesize backgroundTasks;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton Init
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (PicStroomDropboxUploader *) currentUploader {
    @synchronized(self) {
        if (!uploader) {
            uploader = [[[self class] alloc] init];
            uploader.restClient = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession]] autorelease];
            uploader.restClient.delegate = uploader;
            uploader.backgroundTasks = [[[NSMutableDictionary alloc] init] autorelease];
        }
    }
    return uploader;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [restClient release], restClient = nil;
    [backgroundTasks release], backgroundTasks = nil;
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox upload
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) uploadImageToDropbox:(NSDictionary *)args {
    UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    NSString *sourcePath = [args objectForKey:@"sourcePath"];
    NSString *destPath = [args objectForKey:@"path"];
    NSString *destFile = [[args objectForKey:@"destinationPath"] lastPathComponent];

    [backgroundTasks setObject:[NSNumber numberWithInt:bgTask] forKey:sourcePath];
    DebugLog (@"Uploading file %@ to dropbox folder", destFile);
    [self.restClient uploadFile:destFile toPath:destPath fromPath:sourcePath];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Delegate Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath {
    @synchronized (self) {
        NSNumber *bgTask = (NSNumber *)[backgroundTasks objectForKey:srcPath];
        [backgroundTasks removeObjectForKey:srcPath];
        [[UIApplication sharedApplication] endBackgroundTask:[bgTask intValue]];
        DebugLog (@"Dropbox received file %@", srcPath);
    }
}

- (void) restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    if (error) { // retry
        DebugLog(@"Error sending image to dropbox -- retryting");
        [self performSelector:@selector(uploadImageToDropbox:) withObject:error.userInfo afterDelay:1.5];
    }
}

@end
