//
//  PicStroomDropboxRootFolderTableCell.h
//  PicStroom
//
//  Created by Damien Glancy on 13/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBRestClient.h"

@interface PicStroomDropboxRootFolderTableCell : UITableViewCell <DBRestClientDelegate> {
    DBRestClient *restClient;
    UIView *rootFolderView;
    UIImageView *imageView;
    UILabel *imageCounterView;
    UILabel *rootFolderPathLabel;
    DBMetadata *rootFolderMetadata;
    NSInteger thumbnailsLoaded;
}
@property (nonatomic, retain) UIView *rootFolderView;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *imageCounterView;
@property (nonatomic, retain) UILabel *rootFolderPathLabel;
@property (nonatomic, retain) DBMetadata *rootFolderMetadata;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Scanner functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showThumbnails;
- (void) loadThumbnails:(NSInteger)number;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox Client
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// -(void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath;
- (DBRestClient *) restClient;

@end
