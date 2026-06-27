//
//  PicStroomUserHappinessViewController.m
//  PicStroom
//
//  Created by Damien Glancy on 27/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "PicStroomUserHappinessViewController.h"
#import "PicStroomUserHappinessView.h"
#import "PicStroomSettingsViewController.h"

@implementation PicStroomUserHappinessViewController
@synthesize happinessTableView;
@synthesize userHappiness;
@synthesize happinessView;
@synthesize settingsController;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [happinessTableView release];
    [happinessView release];
    [super dealloc];
}

- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 58)];
    footerView.backgroundColor = [UIColor clearColor];
    footerView.contentMode = UIViewContentModeCenter;

    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 545, 20)];
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textAlignment = UITextAlignmentCenter;
    footerLabel.textColor = [UIColor lightGrayColor];
    footerLabel.font = [UIFont fontWithName:STANDARD_FONT size:12.0];
    footerLabel.text = @"Inspired by smiley.37signals.com and icons from flukeout.com/free-weather-icons";
    [footerView addSubview:footerLabel];
    [footerLabel release];

    happinessTableView.tableFooterView = footerView;
    [footerView release];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.happinessTableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.happinessView.commentTextView resignFirstResponder];
    if (self.happinessView.userLeftComment) {
        self.settingsController.comment = self.happinessView.commentTextView.text;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:happinessView name:UITextViewTextDidBeginEditingNotification object:nil];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 265;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.selectionStyle = UITableViewCellEditingStyleNone;

    if (!happinessView) {
        self.happinessView = [[[PicStroomUserHappinessView alloc] initWithFrame:CGRectMake(0, 0, 465, 260)] autorelease];
        [self.happinessView.btn1 addTarget:self action:@selector(weatherIconOneWasPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.happinessView.btn2 addTarget:self action:@selector(weatherIconTwoWasPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.happinessView.btn3 addTarget:self action:@selector(weatherIconThreeWasPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.happinessView.btn4 addTarget:self action:@selector(weatherIconFourWasPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.happinessView showCommentBox];
        if ((!self.settingsController.comment) && ([self.settingsController.comment length] > 0)) {
            self.happinessView.commentTextView.text = settingsController.comment;
            self.happinessView.commentTextView.textColor = [UIColor blackColor];
            self.happinessView.userLeftComment = YES;
        }
        [cell.contentView addSubview:self.happinessView];
    }

    if (self.userHappiness == UserHappyOutstanding) {
        self.happinessView.btn1.selected = YES;
        self.happinessView.btn2.selected = NO;
        self.happinessView.btn3.selected = NO;
        self.happinessView.btn4.selected = NO;
    } else if (self.userHappiness == UserHappyILikeIt) {
        self.happinessView.btn2.selected = YES;
        self.happinessView.btn1.selected = NO;
        self.happinessView.btn3.selected = NO;
        self.happinessView.btn4.selected = NO;
    } else if (self.userHappiness == UserHappyCanBeBetter) {
        self.happinessView.btn3.selected = YES;
        self.happinessView.btn1.selected = NO;
        self.happinessView.btn2.selected = NO;
        self.happinessView.btn4.selected = NO;
    } else if (self.userHappiness == UserHappyIWontReturn) {
        self.happinessView.btn4.selected = YES;
        self.happinessView.btn1.selected = NO;
        self.happinessView.btn2.selected = NO;
        self.happinessView.btn3.selected = NO;
    }

    return cell;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) weatherIconOneWasPressed:(id)sender {
    self.userHappiness = UserHappyOutstanding;
    self.happinessView.btn1.selected = YES;
    self.happinessView.btn2.selected = NO;
    self.happinessView.btn3.selected = NO;
    self.happinessView.btn4.selected = NO;
    self.settingsController.userHappiness = userHappiness;
}

- (void) weatherIconTwoWasPressed:(id)sender {
    self.userHappiness = UserHappyILikeIt;
    self.happinessView.btn2.selected = YES;
    self.happinessView.btn1.selected = NO;
    self.happinessView.btn3.selected = NO;
    self.happinessView.btn4.selected = NO;
    self.settingsController.userHappiness = userHappiness;
}

- (void) weatherIconThreeWasPressed:(id)sender {
    self.userHappiness = UserHappyCanBeBetter;
    self.happinessView.btn3.selected = YES;
    self.happinessView.btn1.selected = NO;
    self.happinessView.btn2.selected = NO;
    self.happinessView.btn4.selected = NO;
    self.settingsController.userHappiness = userHappiness;
}

- (void) weatherIconFourWasPressed:(id)sender {
    self.userHappiness = UserHappyIWontReturn;
    self.happinessView.btn4.selected = YES;
    self.happinessView.btn1.selected = NO;
    self.happinessView.btn2.selected = NO;
    self.happinessView.btn3.selected = NO;
    self.settingsController.userHappiness = userHappiness;
}

@end
