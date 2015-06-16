//
//  VSHomeViewController.h
//  VocalSwarm
//
//  Created by Alexey on 10.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>


//TODO mb in stuct
#define displayTypeDefault  @"kDisplayTypeDefault"
#define displayTypeiPad @"kDisplayTypeiPad"

@interface VSHomeViewController : UIViewController<QBActionStatusDelegate>

@property (strong, nonatomic) NSString *displayType;

@end
