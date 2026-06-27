//
//  PicStroomUserHappinessView.h
//  PicStroom
//
//  Created by Damien Glancy on 27/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PicStroomUserHappinessView : UIView {
    BOOL userLeftComment;

    UIButton *btn1;
    UIButton *btn2;
    UIButton *btn3;
    UIButton *btn4;

    UITextView *commentTextView;
}
@property (nonatomic, retain) UIButton *btn1;
@property (nonatomic, retain) UIButton *btn2;
@property (nonatomic, retain) UIButton *btn3;
@property (nonatomic, retain) UIButton *btn4;
@property (nonatomic, retain) UITextView *commentTextView;
@property (assign) BOOL userLeftComment;


// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View functions
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showCommentBox;
- (void) textChanged:(NSNotification *)notification;

@end
