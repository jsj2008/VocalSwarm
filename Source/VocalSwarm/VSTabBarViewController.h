//
//  VSTabBarViewController.h
//  VocalSwarm
//
//  Created by Alexey on 03.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VSTabBarViewController : UITabBarController

- (void)scheduleSwarmAction;
- (void)scheduledSwarmsAction;
- (void)liveSwarmJoin:(NSObject *)swarm;
- (void)liveSwarmCreate:(NSObject *)swarm;
- (void)fullScreenWebView:(NSURL *)url;

@end
