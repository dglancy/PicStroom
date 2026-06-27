//
//  PicStroomUserHappinessView.m
//  PicStroom
//
//  Created by Damien Glancy on 27/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PicStroomUserHappinessView.h"
#import "PicStroomUserHappinessViewController.h"

@implementation PicStroomUserHappinessView
@synthesize btn1, btn2, btn3, btn4;
@synthesize userLeftComment;
@synthesize commentTextView;

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init & Dealloc
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        userLeftComment = NO;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 450, 30)];
        titleLabel.font = [UIFont fontWithName:BOLD_FONT size:17.0];
        titleLabel.text = @"Tell us what you think of PicStroom...";
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.opaque = YES;
        [self addSubview:titleLabel];
        [titleLabel release];

        btn1 = [[UIButton alloc] initWithFrame:CGRectMake(15, 35, 110, 122)];
        [btn1 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w01-not_selected" ofType:@"png"]] forState:UIControlStateNormal];
        [btn1 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w01-selected" ofType:@"png"]] forState:UIControlStateSelected];
        [btn1 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w01-selected" ofType:@"png"]] forState:UIControlStateHighlighted];
        btn1.showsTouchWhenHighlighted = NO;

        btn2 = [[UIButton alloc] initWithFrame:CGRectMake(127, 35, 110, 122)];
        [btn2 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w02-not_selected" ofType:@"png"]] forState:UIControlStateNormal];
        [btn2 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w02-selected" ofType:@"png"]] forState:UIControlStateSelected];
        [btn2 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w02-selected" ofType:@"png"]] forState:UIControlStateHighlighted];
        btn2.showsTouchWhenHighlighted = NO;

        btn3 = [[UIButton alloc] initWithFrame:CGRectMake(237, 35, 110, 122)];
        [btn3 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w03-not_selected" ofType:@"png"]] forState:UIControlStateNormal];
        [btn3 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w03-selected" ofType:@"png"]] forState:UIControlStateSelected];
        [btn3 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w03-selected" ofType:@"png"]] forState:UIControlStateHighlighted];
        btn3.showsTouchWhenHighlighted = NO;

        btn4 = [[UIButton alloc] initWithFrame:CGRectMake(350, 35, 110, 122)];
        [btn4 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w04-not_selected" ofType:@"png"]] forState:UIControlStateNormal];
        [btn4 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w04-selected" ofType:@"png"]] forState:UIControlStateSelected];
        [btn4 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"w05-selected" ofType:@"png"]] forState:UIControlStateHighlighted];
        btn4.showsTouchWhenHighlighted = NO;

        commentTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 170, 445, 70)];

        [self addSubview:btn1];
        [self addSubview:btn2];
        [self addSubview:btn3];
        [self addSubview:btn4];
    }
    return self;
}

- (void) dealloc {
    [btn1 release];
    [btn2 release];
    [btn3 release];
    [btn4 release];
    [commentTextView release];
    [super dealloc];
}


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showCommentBox {
    self.commentTextView.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_FONT_SIZE];
    self.commentTextView.scrollEnabled = NO;
    self.commentTextView.textColor = [UIColor grayColor];
    self.commentTextView.text = @"We appreciate any comment you want to share with us in 255 characters!";
    self.commentTextView.layer.borderWidth = 1;
    self.commentTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidBeginEditingNotification object:nil];

    [self addSubview:self.commentTextView];
}

- (void) textChanged:(NSNotification *)notification {
    if (!userLeftComment) {
        self.commentTextView.textColor = [UIColor blackColor];
        self.commentTextView.text = @"";
        userLeftComment = YES;
    }
}

@end
