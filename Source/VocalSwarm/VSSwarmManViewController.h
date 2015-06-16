//
//  VSSwarmManViewController.h
//  VocalSwarm
//
//  Created by Alexey on 26.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VSSwarmManProtocol
@required
- (NSTimeInterval) connectionTime;
- (BOOL) isSessionEstablished:(NSUInteger) userID;

@end

@interface VSSwarmManViewController : UIViewController

@property (nonatomic, copy) NSString* userFacebookId;
@property (nonatomic) NSUInteger opponentId;
@property (nonatomic) NSTimeInterval connectionTime;
@property (nonatomic, weak) id<VSSwarmManProtocol> delegate;

- (void) updateViewWithFacebookId:(NSString *)facebookId opponentName:(NSString *)opponentName opponentId:(NSUInteger)opponentId connectionTime:(NSTimeInterval)connectionTime;
- (void) updateViewWithVideoChat:(QBVideoChat *)videoChat;

- (void) updateSpinnerPosition;

@end

