//
//  VSFirstLaunchViewController.m
//  VocalSwarm
//
//  Created by Alexey on 22.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSFirstLaunchViewController.h"
#import "config.h"
#import <Parse/Parse.h>
#import "VSAppDelegate.h"
@interface VSFirstLaunchViewController ()

@end

@implementation VSFirstLaunchViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar setHidden:NO];
    [self performSegueWithIdentifier:@"ShowMainSegue" sender:self];
    [super viewDidDisappear:animated];
}

@end
