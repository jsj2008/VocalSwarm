//
//  VSBasicViewController.m
//  VocalSwarm
//
//  Created by Алексей on 12.02.14.
//  Copyright (c) 2014 injoit. All rights reserved.
//

#import "VSBasicViewController.h"

@interface VSBasicViewController ()

@end

@implementation VSBasicViewController

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//	// Do any additional setup after loading the view.
//    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
//        {
//            CGRect frame = self.navigationController.view.frame;
//            frame.origin.y = 20;
//            frame.size.height -= 20;
//            [self.navigationController.view setFrame:frame];
//        }
//    }
//}

- (BOOL)prefersStatusBarHidden
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

@end
