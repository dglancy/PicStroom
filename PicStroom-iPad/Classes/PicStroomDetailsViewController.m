//
//  PicStroomDetailsViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 09/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomDetailsViewController.h"
#import "PicStroomManager.h"
#import "PicStroomViewController.h"
#import "PicStroomSupervisor.h"
#import "Stroom.h"

@implementation PicStroomDetailsViewController
@synthesize delegate;
@synthesize titleField;
@synthesize detailsTableView;
@synthesize stroom;
// @synthesize mainViewController;
@synthesize indexPathToDelete;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void) dealloc {
    [titleField release];
    [detailsTableView release];
    [stroom release];
    DebugLog(@"dealloc");
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Edit a Stream";

    UIBarButtonItem *saveStroomBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveStroom)];
    self.navigationItem.rightBarButtonItem = saveStroomBtn;
    [saveStroomBtn release];
}

- (void) viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    self.detailsTableView = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];

    self.stroom.title = titleField.text;
    [stroomManager saveContextChanges];
    [stroomManager release];

    [stroom.stroomSupervisor updateStroomNameLabelWithText:stroom.title];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveStroom {
    PicStroomManager *stroomManager = [[PicStroomManager alloc] init];

    self.stroom.title = titleField.text;
    [stroomManager saveContextChanges];
    [stroomManager release];

    [stroom.stroomSupervisor updateStroomNameLabelWithText:stroom.title];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteStroom {
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate picStroomDetailsViewControllerDidFinishWithDelete:self];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 100;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, detailsTableView.frame.size.width, 43)];

    footerView.backgroundColor = [UIColor clearColor];
    footerView.contentMode = UIViewContentModeCenter;

    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.frame = CGRectMake(30, 20, 480, 43);
    [deleteButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"delete-incl-text" ofType:@"png"]] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteStroom) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:deleteButton];

    return [footerView autorelease];
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellX";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if ([indexPath row] == 0) {
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier] autorelease];
            cell.textLabel.text = @"Name";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor whiteColor];
            cell.opaque = YES;
        }

        if (!self.titleField) {
            self.titleField = [[[UITextField alloc] init] autorelease];
            self.titleField.frame = CGRectMake(85, 11, 350, 24);
            self.titleField.borderStyle = UITextBorderStyleNone;
            self.titleField.font = [UIFont fontWithName:BOLD_FONT size:16.0];
            self.titleField.opaque = YES;
            self.titleField.backgroundColor = [UIColor clearColor];
            self.titleField.delegate = self;

            self.titleField.text = stroom.title;
            self.titleField.textColor = [UIColor blackColor];
            self.titleField.keyboardType = UIKeyboardTypeDefault;
            self.titleField.returnKeyType = UIReturnKeyNext;
            self.titleField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            self.titleField.autocorrectionType = UITextAutocorrectionTypeNo;
            [cell.contentView addSubview:self.titleField];
        }

        [cell becomeFirstResponder];
    } else if ([indexPath row] == 1) {
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier] autorelease];
        }
        cell.textLabel.text = @"URL";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        cell.opaque = YES;
        if ([stroom.type intValue] == StroomTypeRSS) {
            cell.detailTextLabel.text = stroom.url;
        } else {
            cell.detailTextLabel.text = @"None";
        }
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    } else if ([indexPath row] == 2) {
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier] autorelease];
        }
        cell.textLabel.text = @"Type";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        cell.opaque = YES;
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];

        if ([stroom.type intValue] == StroomTypeRSS) {
            cell.detailTextLabel.text = @"Website";
        } else {
            cell.detailTextLabel.text = @"Dropbox";
        }
    }
    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end

