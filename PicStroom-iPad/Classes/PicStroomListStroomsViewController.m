//
//  PicStroomListStroomsViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomListStroomsViewController.h"
#import "PicStroomDetailsViewController.h"
#import "PicStroomManager.h"
#import "Stroom.h"
#import "PicStroomAddStroomsViewController.h"
#import "PicStroomViewController.h"
#import "PicStroomSupervisor.h"
#import "PicStroomOrderStroomManager.h"
#import "PicStroomMaxImagesPerStreamViewController.h"

@implementation PicStroomListStroomsViewController
@synthesize listStroomsTableView;
@synthesize mainViewController;
@synthesize translucentView;
@synthesize av;
@synthesize currentRowBeingDeleted;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -Init, Dealloc & Memory management
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void) dealloc {
    [mainViewController release];
    [listStroomsTableView release];
    [currentRowBeingDeleted release];
    [super dealloc];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidUnload {
    [super viewDidUnload];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    [listStroomsTableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Edit/Order/Delete Streams";
    self.mainViewController = [PicStroomViewController getCurrentController];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didPressAddStroom {
    PicStroomAddStroomsViewController *addStroomsViewController = [[PicStroomAddStroomsViewController alloc] init];

    addStroomsViewController.hideDoneBtn = YES;
    [self.navigationController pushViewController:addStroomsViewController animated:YES];
    [addStroomsViewController release];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing: editing animated: animated];
    [self.listStroomsTableView setEditing:editing animated:animated];
}

- (void)activateEditing {
    
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PicStroomListStroomsViewController delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) picStroomDetailsViewControllerDidFinishWithDelete:(PicStroomDetailsViewController *)controller {
    [self performSelector:@selector(deleteStroom:) withObject:[NSNumber numberWithInt:[controller.indexPathToDelete row]] afterDelay:0.75];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Delete stroom
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) deleteStroom:(NSNumber *)row {
    self.listStroomsTableView.userInteractionEnabled = NO;
    self.translucentView = [[[UIView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width / 2) - 100 / 2), ((self.view.frame.size.height / 2) - 100 / 2), 100, 100)] autorelease];
    self.av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    self.av.frame = CGRectMake(((translucentView.frame.size.width / 2) - 36 / 2), (((translucentView.frame.size.height / 2) - 36 / 2)-10), 36, 36);
    self.translucentView.backgroundColor = [UIColor blackColor];
    self.translucentView.alpha = 0.7;
    self.translucentView.layer.cornerRadius = TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS;
    [self.translucentView addSubview:self.av];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(23, 68, 80, 20)];
    label.text = @"Deleting";
    label.font = [UIFont fontWithName:BOLD_FONT size:14.0f];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [self.translucentView addSubview:label];
    [label release];
    
    [self.view addSubview:self.translucentView];
    [self.av startAnimating];
    
    PicStroomOrderStroomManager *orderManager = [[PicStroomOrderStroomManager alloc] init];
    [orderManager storeCurrentOrderOfStrooms:[[PicStroomViewController getCurrentController] stroomSupervisors]];
    [orderManager release];
    
    PicStroomSupervisor *stroomSupervisor = [mainViewController.stroomSupervisors objectAtIndex:[row intValue]];
    
    if ((stroomSupervisor.currentState == StroomStateNewUpdating) || (stroomSupervisor.currentState == StroomStateUpdating)) {
        // sync in progress for this stroom -- need to cancel & wait before deleting
        self.currentRowBeingDeleted = row;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCancelSyncNotification:) name:NOTIF_SYNC_CANCEL_SYNC_STROOM object:nil];
        [stroomSupervisor cancelSync];
    } else {
        [self performSelector:@selector(executePhysicalDelete:) withObject:row afterDelay:0.5];
    }
}

- (void) handleCancelSyncNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIF_SYNC_CANCEL_SYNC_STROOM object:nil];
    [self executePhysicalDelete:self.currentRowBeingDeleted];
}

- (void) executePhysicalDelete:(NSNumber *)row {
    PicStroomSupervisor *stroomSupervisor = [mainViewController.stroomSupervisors objectAtIndex:[row intValue]];

    [mainViewController.stroomTableView beginUpdates];
    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];
    [stroomManager deleteStroom:stroomSupervisor.stroom];
    [stroomManager release];
    [mainViewController.stroomSupervisors removeObject:stroomSupervisor];
    
    [listStroomsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[row intValue] inSection:1]] withRowAnimation:UITableViewRowAnimationBottom];
    [mainViewController.stroomTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[row intValue] inSection:1]] withRowAnimation:UITableViewRowAnimationBottom];

    NSUInteger spareStroomsNeeded = [mainViewController calculateSpareStroomCells];
    DebugLog(@"space stroom rows needed: %d", [mainViewController calculateSpareStroomCells]);

    if (spareStroomsNeeded > 0) {
        [mainViewController.stroomTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[mainViewController calculateSpareStroomCells] - 1 inSection:3]] withRowAnimation:UITableViewRowAnimationNone];
    }
    [mainViewController.stroomTableView endUpdates];

    [self.av stopAnimating];
    [self.translucentView removeFromSuperview];
    self.translucentView = nil;
    self.av = nil;
    self.listStroomsTableView.userInteractionEnabled = YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return [mainViewController.stroomSupervisors count];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSMutableArray *stroomSupervisors = [[PicStroomViewController getCurrentController] stroomSupervisors];
    
    id obj = [stroomSupervisors objectAtIndex:[sourceIndexPath row]];
    [stroomSupervisors removeObjectAtIndex:[sourceIndexPath row]];
    [stroomSupervisors insertObject:obj atIndex:[destinationIndexPath row]];
   
    PicStroomOrderStroomManager *orderManager = [[PicStroomOrderStroomManager alloc] init];
    [orderManager storeCurrentOrderOfStrooms:stroomSupervisors];
    [orderManager release];
    
    [tableView reloadData];
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.detailTextLabel.text = BLANK_STRING; //clear cached detail text from dequeue of reusable cell

    NSUInteger maxImages = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM] intValue];

    NSString *maxImagesDescription = nil;
    if (maxImages == 0) {
        maxImagesDescription = @"Unlimited";
    } else {
        maxImagesDescription = [NSString stringWithFormat:@"%d", maxImages];
    }
    
    if ([indexPath section] == 0) {
        UITableViewCell *headerCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"HeaderCell"] autorelease];
        headerCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        headerCell.textLabel.text = @"Maximum number of Photos per RSS Stream";
        headerCell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:16.0];
        headerCell.detailTextLabel.text = maxImagesDescription;
        headerCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return headerCell;
    } else if([indexPath section] == 1) {
        PicStroomSupervisor *stroomSupervisor = [mainViewController.stroomSupervisors objectAtIndex:[indexPath row]];
        cell.textLabel.text = stroomSupervisor.stroom.title;
        
        if ([stroomSupervisor.stroom.system boolValue] == YES) {
            if(PICSTROOM_PRO_VERSION) {
                cell.detailTextLabel.text = @"Initial Stream";
            } else { 
                cell.detailTextLabel.text = @"Free initial Stream";
            }
        }
        if ([stroomSupervisor.stroom.type intValue] == StroomTypeDropbox) {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_dropbox_50p" ofType:@"png"]];
        } else if ([stroomSupervisor.stroom.type intValue] == StroomTypeRSS) {
            cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_small_stroom_50p" ofType:@"png"]];
        }
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    return cell;
}

// Override to support editing the table view.
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self performSelector:@selector(deleteStroom:) withObject:[NSNumber numberWithInt:[indexPath row]] afterDelay:0.75];
        if ([mainViewController.stroomSupervisors count] - 1 <= 0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    PicStroomDetailsViewController *detailsViewController = [[PicStroomDetailsViewController alloc] initWithNibName:@"PicStroomDetailsViewController" bundle:nil];
    PicStroomSupervisor *stroomSupervisor = [mainViewController.stroomSupervisors objectAtIndex:[indexPath row]];
    
    detailsViewController.stroom = stroomSupervisor.stroom;
    detailsViewController.indexPathToDelete = indexPath;
    detailsViewController.delegate = self;
    [self.navigationController pushViewController:detailsViewController animated:YES];
    [detailsViewController release];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        PicStroomMaxImagesPerStreamViewController *maxImagesPerStreamViewController = [[PicStroomMaxImagesPerStreamViewController alloc] initWithNibName:@"PicStroomMaxImagesPerStreamViewController" bundle:nil];
        
        [self.navigationController pushViewController:maxImagesPerStreamViewController animated:YES];
        [maxImagesPerStreamViewController release];
    } 
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 0;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [self tableView:tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];     
    }
    
    return proposedDestinationIndexPath;
}

@end