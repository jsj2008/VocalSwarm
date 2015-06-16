//
//  VSFullWebViewController.h
//  VocalSwarm
//
//  Created by Alexey on 20.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VSFullWebViewControllerDelegate;

@interface VSFullWebViewController : UIViewController

@property (nonatomic, strong) NSURL *dataUrl;

@property (nonatomic, weak) id<VSFullWebViewControllerDelegate> delegate;

@end

@protocol VSFullWebViewControllerDelegate <NSObject>
@optional

- (void) hardDisappear;

@end
