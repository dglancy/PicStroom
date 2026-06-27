//
//  PicStroomSetDropboxSaveFolderViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 17/04/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomSetDropboxSaveFolderViewController.h"
#import "PicStroomSelectedDBResourcesManager.h"
#import "PicStroomDropboxRootFolderTableCell.h"
#import "PicStroomAddStroomManager.h"
#import "PicStroomInAppPurchaseAlertViewController.h"
#import "PicStroomSupervisor.h"
#import "PicStroomInAppPurchaseManager.h"

#import "PicStroomViewController.h"
#import "Stroom.h"

#import "NSOperationQueue+CWSharedQueue.h"
#import "DBRestClient.h"
#import "DBMetadata.h"

@implementation PicStroomSetDropboxSaveFolderViewController
@synthesize setDropboxSaveFolderTableView;
@synthesize rootPath;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    [currentDropboxFilePaths release];
    [setDropboxSaveFolderTableView release];
    [restClient release];

    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Set Dropbox save folder";
    currentDropboxFilePaths = [[NSMutableArray alloc] init];

    if (rootPath == nil) {
        rootPath = @"/";
    }

    [[self restClient] loadMetadata:rootPath];

    UIBarButtonItem *doneBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    self.navigationItem.rightBarButtonItem = doneBtn;
}

- (void) viewWillAppear:(BOOL)animated {
    [setDropboxSaveFolderTableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void) viewDidUnload {
    self.setDropboxSaveFolderTableView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressDone {
    // add dropbox strooms
    NSArray *selectedDBResources = [[PicStroomSelectedDBResourcesManager currentManager] getSelectedResources];

    for (NSString *dropboxPath in selectedDBResources) {
        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        Stroom *searchStroom = [stroomManager getStroomFromDropboxPath:dropboxPath];
        [stroomManager release];
        if (!searchStroom) {
            PicStroomAddStroomManager *addStroomManager = [[PicStroomAddStroomManager alloc] init];
            Stroom *stroom = [addStroomManager addStroomDropbox:dropboxPath];
            [addStroomManager release];
            PicStroomSupervisor *stroomSupervisor = [[PicStroomSupervisor alloc] init];
            stroom.stroomSupervisor = stroomSupervisor;
            stroomSupervisor.currentState = StroomStateNew;
            stroomSupervisor.stroom = stroom;;
            PicStroomViewController *mainViewController = [PicStroomViewController getCurrentController];
            [mainViewController.stroomSupervisors addObject:stroomSupervisor];

            [mainViewController.stroomTableView beginUpdates];
            [mainViewController.stroomTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[mainViewController.stroomSupervisors count] - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
            if ([mainViewController.stroomSupervisors count] <= TARGET_NUM_OF_STROOMS_ON_SCREEN) {
                [mainViewController.stroomTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:TARGET_NUM_OF_STROOMS_ON_SCREEN - ([mainViewController.stroomSupervisors count]) inSection:3]] withRowAnimation:UITableViewRowAnimationTop];
            }
            [mainViewController.stroomTableView endUpdates];

            [stroomSupervisor performSelectorInBackgroundQueue:@selector(startSyncInBackgroundQueue) withObject:nil];
            [stroomSupervisor release];
        }
    }
    [[PicStroomSelectedDBResourcesManager currentManager] reset];
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        return 100.0f;
    } else {
        return 40.0f;
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        NSInteger i = [currentDropboxFilePaths count];
        if (i == 0) {
            return 1; // a row to say that there are no more folders!
        }
        return i;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 35.0f;
    } else {
        return 15.0f;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UIView *sectionView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 20)] autorelease];
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(40, 8, 100, 20)];
        title.text = @"Subfolders";
        title.font = [UIFont fontWithName:STANDARD_FONT size:15.0];
        title.backgroundColor = [UIColor clearColor];
        title.textColor = [UIColor grayColor];
        [sectionView addSubview:title];
        [title release];
        return sectionView;
    } else { return nil; }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier1 = @"Cell1";
    static NSString *CellIdentifier2 = @"Cell2";

    if ([indexPath section] == 0) {
        dropboxRootFolderCell = (PicStroomDropboxRootFolderTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (dropboxRootFolderCell == nil) {
            dropboxRootFolderCell = [[[PicStroomDropboxRootFolderTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
            dropboxRootFolderCell.selectionStyle = UITableViewCellSelectionStyleNone;
            dropboxRootFolderCell.backgroundColor = [UIColor whiteColor];
        }

        if ([rootPath isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER]]) {
            dropboxRootFolderCell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_green" ofType:@"png"]];
        } else {
            dropboxRootFolderCell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
        }

        dropboxRootFolderCell.rootFolderPathLabel.text = [self displayRootPath:rootPath];
        return dropboxRootFolderCell;
    } else {
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier2] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor whiteColor];
        }

        if ([currentDropboxFilePaths count] == 0) {
            cell.textLabel.text = @"No further subfolders";
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
        } else {
            DBMetadata *child = [currentDropboxFilePaths objectAtIndex:[indexPath row]];

            cell.textLabel.text = [self displayPath:child.path];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

            if ([child.path isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER]]) {
                cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_green" ofType:@"png"]];
            } else {
                cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
            }
        }
        return cell;
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    PicStroomSetDropboxSaveFolderViewController *setDropboxSaveFolderViewControler = [[PicStroomSetDropboxSaveFolderViewController alloc] initWithNibName:@"PicStroomSetDropboxSaveFolderViewController" bundle:nil];
    DBMetadata *selectedChild = [currentDropboxFilePaths objectAtIndex:[indexPath row]];

    setDropboxSaveFolderViewControler.rootPath = selectedChild.path;

    [self.navigationController pushViewController:setDropboxSaveFolderViewControler animated:YES];
    [setDropboxSaveFolderViewControler release];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        if (![rootPath isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER]]) {
            [[NSUserDefaults standardUserDefaults] setObject:rootPath forKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER];
        }
    } else if ([indexPath section] == 1) {
        if ([currentDropboxFilePaths count]==0) {
            return;
        }
        
        DBMetadata *selectedResource = [currentDropboxFilePaths objectAtIndex:[indexPath row]];
        if (![selectedResource.path isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER]]) {
            [[NSUserDefaults standardUserDefaults] setObject:selectedResource.path forKey:USER_DEFAULTS_DROPBOX_SAVE_FOLDER];
        }
    }
    [tableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *) displayRootPath:(NSString *)rawPath {
    if ([rawPath isEqualToString:@"/"]) {
        return @"/Dropbox";
    }

    return [NSString stringWithFormat:@"/Dropbox%@", rawPath];
}

- (NSString *) displayPath:(NSString *)rawPath {
    NSRange range = [rawPath rangeOfString:@"/" options:NSBackwardsSearch];

    return [NSString stringWithFormat:@"/%@", [rawPath substringFromIndex:range.length]];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dropbox Parser Callbacks
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    dropboxRootFolderCell.rootFolderMetadata = metadata;
    [dropboxRootFolderCell showThumbnails];
    for (DBMetadata *child in metadata.contents) {
        if (child.isDirectory) {
            [currentDropboxFilePaths addObject:child];
            [setDropboxSaveFolderTableView reloadData];
        }
    }
}

- (DBRestClient *) restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end
