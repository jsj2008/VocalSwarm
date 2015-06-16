//
//  VSAppDelegate.h
//  VocalSwarm
//
//  Created by Alexey on 31.05.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (BOOL) isFirstLaunch;
- (void) setupFirstLaunch;

@end
