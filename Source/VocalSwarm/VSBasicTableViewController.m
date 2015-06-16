//
//  VSBasicTableViewController.m
//  VocalSwarm
//
//  Created by Алексей on 12.02.14.
//  Copyright (c) 2014 injoit. All rights reserved.
//

#import "VSBasicTableViewController.h"

@interface VSBasicTableViewController ()

@end

@implementation VSBasicTableViewController

- (BOOL)prefersStatusBarHidden
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

@end
