//
//  VSSettingsNavigationController.m
//  VocalSwarm
//
//  Created by Alexey on 04.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsNavigationController.h"

#import "VSSettingsModel.h"

@interface VSSettingsNavigationController ()

@end

@implementation VSSettingsNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
//    [VSSettingsModel synchronizeAlltoServer:YES
//                                   finished:nil];
}

@end
