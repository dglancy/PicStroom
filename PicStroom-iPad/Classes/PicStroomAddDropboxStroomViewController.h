//
//  PicStroomAddDropboxStroomViewController.h
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBRestClient.h"

@class PicStroomDropboxRootFolderTableCell;

@interface PicStroomAddDropboxStroomViewController : UITableViewController <DBRestClientDelegate, UIAlertViewDelegate> {
    NSString *rootPath;

    UITableView *addDropboxTableView;
    BOOL directlyLoaded;
    DBRestClient *restClient;

    NSMutableArray *currentDropboxFilePaths;
    NSMutableArray *greyedOutRows;
    BOOL rootFolderAlreadyAdded;

    PicStroomDropboxRootFolderTableCell *dropboxRootFolderCell;
}
@property (nonatomic, retain) IBOutlet UITableView *addDropboxTableView;
@property (assign) BOOL directlyLoaded;
@property (nonatomic, retain) NSString *rootPath;
@property (nonatomic, retain) PicStroomDropboxRootFolderTableCell *dropboxRootFolderCell;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone;
- (void) didPressCancel;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *) displayRootPath:(NSString *)rawPath;
- (NSString *) displayPath:(NSString *)rawPath;
- (BOOL) isResourceChecked:(NSString *)path;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (DBRestClient *) restClient;

@end
