//
//  PicStroomInstapaperManager.m
//  PicStroom
//
//  Created by Damien Glancy on 10/09/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomInstapaperManager.h"

#import "SFHFKeychainUtils.h"

@implementation PicStroomInstapaperManager

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////


+ (BOOL)isInstapaperLinked {
    NSError *error;
    NSString *response = [SFHFKeychainUtils getPasswordForUsername:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY andServiceName:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY error:&error];
    
    if (error) {
        DebugLog(@"An issue reading Instapaper OAuth secret key from keystore");
        return NO;
    } else {
        if ([response length]>0) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getUsersInstapaperTokenSecret {
    
    NSError *error;
    NSString *response = [SFHFKeychainUtils getPasswordForUsername:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY andServiceName:INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY error:&error];
    
    if (error) {
        DebugLog(@"An issue reading Instapaper OAuth secret key from keystore");
        return nil;
    } else {
        if ([response length]>0) {
            return response;
        }
    }
    
    return nil;
}

@end