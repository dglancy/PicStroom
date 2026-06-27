//
//  PicStroomAddDropboxStroomViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 12/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomAddDropboxStroomViewController.h"
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


@implementation PicStroomAddDropboxStroomViewController
@synthesize addDropboxTableView;
@synthesize directlyLoaded;
@synthesize rootPath;
@synthesize dropboxRootFolderCell;

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
    [addDropboxTableView release];
    [greyedOutRows release];
    [restClient release];
    [rootPath release];
    [dropboxRootFolderCell release];

    DebugLog(@"add dropbox stroom dealloc()");
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
    self.title = @"Add Dropbox folder";
    currentDropboxFilePaths = [[NSMutableArray alloc] init];
    greyedOutRows = [[NSMutableArray alloc] init];

    if (!self.rootPath) {
        self.rootPath = @"/";
    }

    [[self restClient] loadMetadata:rootPath];

    UIBarButtonItem *doneBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didPressDone)] autorelease];
    self.navigationItem.rightBarButtonItem = doneBtn;

    if (directlyLoaded) {
        UIBarButtonItem *cancelBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressCancel)] autorelease];
        self.navigationItem.leftBarButtonItem = cancelBtn;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [addDropboxTableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void) viewDidUnload {
    [self setAddDropboxTableView:nil];
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

- (void) didPressCancel {
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
        self.dropboxRootFolderCell = (PicStroomDropboxRootFolderTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (!self.dropboxRootFolderCell) {
            self.dropboxRootFolderCell = [[[PicStroomDropboxRootFolderTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
            self.dropboxRootFolderCell.selectionStyle = UITableViewCellSelectionStyleNone;
            self.dropboxRootFolderCell.backgroundColor = [UIColor whiteColor];
        }

        PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
        Stroom *stroom = [stroomManager getStroomFromDropboxPath:rootPath];
        [stroomManager release];

        if (stroom != nil) {
            self.dropboxRootFolderCell.rootFolderPathLabel.textColor = [UIColor lightGrayColor];
            self.dropboxRootFolderCell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_grey" ofType:@"png"]];
            rootFolderAlreadyAdded = YES;
        } else {
            if ([self isResourceChecked:rootPath]) {
                self.dropboxRootFolderCell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_plus_green" ofType:@"png"]];
            } else {
                self.dropboxRootFolderCell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
            }
        }
        self.dropboxRootFolderCell.rootFolderPathLabel.text = [self displayRootPath:rootPath];
        return self.dropboxRootFolderCell;
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

            PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
            Stroom *stroom = [stroomManager getStroomFromDropboxPath:child.path];
            [stroomManager release];

            cell.textLabel.text = [self displayPath:child.path];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

            if (stroom != nil) {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_check_grey" ofType:@"png"]];
                [greyedOutRows addObject:[NSNumber numberWithInt:[indexPath row]]];
            } else {
                if ([self isResourceChecked:child.path]) {
                    cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_plus_green" ofType:@"png"]];
                } else {
                    cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pref_empty" ofType:@"png"]];
                }
            }
        }
        return cell;
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    PicStroomAddDropboxStroomViewController *addDropboxStroomViewControler = [[PicStroomAddDropboxStroomViewController alloc] initWithNibName:@"PicStroomAddDropboxStroomViewController" bundle:nil];
    DBMetadata *selectedChild = [currentDropboxFilePaths objectAtIndex:[indexPath row]];

    addDropboxStroomViewControler.rootPath = selectedChild.path;

    [self.navigationController pushViewController:addDropboxStroomViewControler animated:YES];
    [addDropboxStroomViewControler release];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PicStroomSelectedDBResourcesManager *selectedDBResourcesManager = [PicStroomSelectedDBResourcesManager currentManager];
    NSMutableArray *selectedDBResources = [selectedDBResourcesManager getSelectedResources];

    if ([indexPath section] == 0) {
        if (rootFolderAlreadyAdded) {
            DebugLog(@"Not adding root dropbox folder as same stroom is already added");
            return;
        } else {
            if ([selectedDBResourcesManager isAlreadySelected:rootPath]) {
                [selectedDBResourcesManager removeSelectedResource:rootPath];
            } else {
                if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
                    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
                    NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
                    [stroomManager release];

                    if ((count + [selectedDBResources count]) >= UNLIMITED_STROOMS_THRESHOLD) {
                        [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Stream.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
                        return;
                    }
                }
                [selectedDBResources addObject:rootPath];
            }
        }
    }

    if ([indexPath section] == 1) {
        if ([greyedOutRows containsObject:[NSNumber numberWithInt:[indexPath row]]]) {
            DebugLog(@"Not adding dropbox folder as same stroom is already added");
            return;
        }
        

        if ([currentDropboxFilePaths count]==0) {
            return;
        }
        
        DBMetadata *selectedResource = [currentDropboxFilePaths objectAtIndex:[indexPath row]];
        if ([selectedDBResourcesManager isAlreadySelected:selectedResource.path]) {
            [selectedDBResourcesManager removeSelectedResource:selectedResource.path];
        } else {
            if (![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
                PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
                NSInteger count = [stroomManager getNumberOfNonSystemStrooms];
                [stroomManager release];

                if ((count + [selectedDBResources count]) >= UNLIMITED_STROOMS_THRESHOLD) {
                    [[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This is your %dth Stream", UNLIMITED_STROOMS_THRESHOLD + 1] message:[NSString stringWithFormat:@"You can only add %d free Streams.", UNLIMITED_STROOMS_THRESHOLD] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Read more", nil] autorelease] show];
                    return;
                }
            }
            [selectedDBResources addObject:selectedResource.path];
        }
    }
    [tableView reloadData];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Local utils
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) isResourceChecked:(NSString *)resourcePath {
    PicStroomSelectedDBResourcesManager *selectedDBResourcesManager = [PicStroomSelectedDBResourcesManager currentManager];

    if ([[[PicStroomSelectedDBResourcesManager currentManager] getSelectedResources] count] == 0) {
        return NO;
    }

    return [selectedDBResourcesManager isAlreadySelected:resourcePath];
}

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
#pragma mark - Read more alert box button handler
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (![PicStroomInAppPurchaseManager canMakePurchases]) {
            [[[[UIAlertView alloc] initWithTitle:@"In-App Purchases Disabled" message:@"You have disabled In-App purchases on this device. To purchase unlimited Streams you need to re-enable In-App purchases in your settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
            return;
        }

        PicStroomInAppPurchaseAlertViewController *inAppPurchaseController = [[PicStroomInAppPurchaseAlertViewController alloc] initWithNibName:@"PicStroomInAppPurchaseAlertViewController" bundle:nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inAppPurchaseController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navigationController animated:YES];
        [inAppPurchaseController release];
        [navigationController release];
    }
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
            [addDropboxTableView reloadData];
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
