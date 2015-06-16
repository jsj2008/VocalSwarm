//
//  VSSwarmMainViewController.h
//  VocalSwarm
//
//  Created by Alexey on 10.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSSwarmManViewController.h"
#import "VSBasicViewController.h"

@class VSSwarm;

@interface VSSwarmMainViewController : VSBasicViewController <VSSwarmManProtocol>

@property (strong, nonatomic) VSSwarm *swarm;

@property (nonatomic) BOOL isReplaceBack;

@end
