//
//  VSSwarmSelectionViewController.h
//  VocalSwarm
//
//  Created by Alexey on 18.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VSSwarm;

@interface VSSwarmSelectionViewController : UIViewController

@property (strong, nonatomic) VSSwarm *swarm;
@property (nonatomic) BOOL isJoinAfterCreate;

@end
