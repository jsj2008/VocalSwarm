//
//  VSSwarmManViewController.m
//  VocalSwarm
//
//  Created by Alexey on 26.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSwarmManViewController.h"

#import "AFNetworking.h"

@interface VSSwarmManViewController ()

@property (nonatomic, weak) UIActivityIndicatorView *activity;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UILabel *nameLabel;

- (void) initialization;

@end

@implementation VSSwarmManViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialization];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void) initialization {
    _userFacebookId = @"";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view.layer setContentsGravity:kCAGravityResizeAspectFill];
    [self.view setClipsToBounds:YES];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:activityView];
    self.activity = activityView;
    
    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 24, self.view.bounds.size.width, 22)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 22)];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    self.nameLabel = label;
    [self.view addSubview:self.nameLabel];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.imageView setHidden:YES];
    [self.activity startAnimating];
    [self updateSpinnerPosition];
}

- (void) updateSpinnerPosition {
    [self.activity setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) updateViewWithFacebookId:(NSString *)facebookId opponentName:(NSString *)opponentName opponentId:(NSUInteger)opponentId connectionTime:(NSTimeInterval)connectionTime {
    self.userFacebookId = facebookId;
    self.opponentId = opponentId;
    self.connectionTime = connectionTime;
    
    QBVideoChat *videoChat = nil;
    NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
    for (QBVideoChat *vc in copyArray) {
        if (vc.videoChatOpponentID == opponentId) {
            videoChat = vc;
        }
    }
    
    if (videoChat && [self.delegate isSessionEstablished:opponentId]) {
        videoChat.viewToRenderOpponentVideoStream = [self view];
        [self.activity stopAnimating];
    } else {
        [self.activity startAnimating];
        self.view.layer.contents = nil;
        if (!videoChat && [self.delegate connectionTime] > connectionTime) {
            QBVideoChat *videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
            [videoChat setIsUseCustomVideoChatCaptureSession:YES];
            [videoChat setIsUseCustomAudioChatSession:YES];
            [videoChat callUser:opponentId conferenceType:QBVideoChatConferenceTypeAudioAndVideo customParameters:nil];
        }
    }
    
    self.nameLabel.text = opponentName;
}

- (void) updateViewWithVideoChat:(QBVideoChat *)videoChat
{
    [self.activity stopAnimating];
    videoChat.viewToRenderOpponentVideoStream = [self view];
    NSLog(@"setting %@ as renderer opponent view", videoChat.viewToRenderOpponentVideoStream);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
