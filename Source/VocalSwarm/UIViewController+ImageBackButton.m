//
//  UIViewController+ImageBackButton.m
//  VocalSwarm
//
//  Created by Alexey on 11.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "UIViewController+ImageBackButton.h"

@implementation UIViewController (ImageBackButton)

- (void)setUpImageBackButton
{
//    UIImage *image = [UIImage imageNamed:@"leftArrow.png"];
    UIImage *image = [UIImage imageNamed:@"navigationBack.png"];
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [backButton setBackgroundImage:image forState:UIControlStateNormal];
    UIBarButtonItem *barBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [backButton addTarget:self action:@selector(popCurrentViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = barBackButtonItem;
    self.navigationItem.hidesBackButton = YES;
}

- (void)popCurrentViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
