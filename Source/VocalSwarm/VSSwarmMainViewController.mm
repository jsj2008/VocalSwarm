//
//  VSSwarmMainViewController.m
//  VocalSwarm
//
//  Created by Alexey on 10.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSwarmMainViewController.h"
#import "VSSwarm.h"
#import "VSGame.h"
#import "VSvsSwarm.h"
#import "VSSettingsModel.h"
#import "UIViewController+ImageBackButton.h"
#import "VSSwarmsModel.h"
#import "VSTeamSwarm.h"
#import "VSPrivateSwarm.h"
#import <FacebookSDK/FacebookSDK.h>
#import "VSSwarmManViewController.h"
#import "VSNetworkChalk.h"
#import "TPCircularBuffer.h"
#import "VSUtils.h"

#define kFacebookId @"kFacebookId"
#define kConnectTime @"kConnectTime"
#define kFullName @"kFullName"
#define kIsHomeTeam @"kIsHomeTeam"

#define kUserID @"kUserID"

#define kMaxMansCount 4

#define kBufferLength 32768
#define qbAudioDataSizeForSecods(second) 512*(32*second)

static TPCircularBuffer circularBuffer;

@interface VSSwarmMainViewController () <QBActionStatusDelegate, FBViewControllerDelegate, QBChatDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIButton *propsButton;
@property (weak, nonatomic) IBOutlet UIButton *socialButton;
@property (weak, nonatomic) IBOutlet UIButton *statsButton;

@property (weak, nonatomic) IBOutlet UIView *socialContainer;
@property (weak, nonatomic) IBOutlet UIView *statsContainer;
@property (weak, nonatomic) IBOutlet UIView *propsContainer;
@property (weak, nonatomic) IBOutlet UIView *chatContainer;

@property (weak, nonatomic) IBOutlet UIScrollView *statsScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *statsImageVIew;

@property (weak, nonatomic) IBOutlet UIView *webContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *webActivity;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *webCloseButton;

@property (weak, nonatomic) IBOutlet UIView *adView;

@property (weak, nonatomic) IBOutlet UILabel *homeTeamNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *homeTeamScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *awayTeamNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *awayTeamScoreLabel;

- (IBAction)webViewCloseAction;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *chatActivityIndicator;

@property (nonatomic, strong) NSString *roomForConnect;
@property (nonatomic, strong) NSDate *connectTime;
@property (nonatomic, strong) NSTimer *presenceTimer;
@property (nonatomic, strong) QBChatRoom *chatRoom;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoCaptureOutput;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;

@property (nonatomic, strong) NSMutableArray *startedSession;
@property (nonatomic) BOOL testPresenceSended;
@property (nonatomic, weak) UIView *myView;

- (IBAction) selectChat;
- (IBAction) selectProps;
- (IBAction) selectSocial;
- (IBAction) selectStats;

- (IBAction) showHideProps;

- (IBAction)tweetAction;
- (IBAction)facebookAction;
- (IBAction)givePropsAction:(id)sender;

@property (strong, nonatomic) NSArray *swarmMansArray;

@property (nonatomic) BOOL isTwitterAnotherWindow;

@end

@implementation VSSwarmMainViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _swarm = nil;
        _isReplaceBack = NO;
        NSMutableArray *mutArray = [NSMutableArray array];
        for (int i = 0; i < kMaxMansCount; ++i) {
            VSSwarmManViewController *smvc = [[VSSwarmManViewController alloc] init];
            smvc.delegate = self;
            [mutArray addObject:smvc];
        }
        _swarmMansArray = [NSArray arrayWithArray:mutArray];
        _startedSession = [NSMutableArray array];
        _isTwitterAnotherWindow = NO;
    }
    return self;
}

- (void)removeStartedSessionWithId:(NSUInteger)videoOpponentId
{
    NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
	for (QBVideoChat *videoChat in copyArray) {
        if (videoChat.videoChatOpponentID == videoOpponentId) {
            [videoChat finishCall];
            [[QBChat instance] unregisterVideoChatInstance:videoChat];
        }
    }
    
    for (int i = 0; i < [self.startedSession count]; ++i) {
        if (videoOpponentId == [[self.startedSession objectAtIndex:i] integerValue])
        {
            [self.startedSession removeObjectAtIndex:i];
            i--;
        }
    }
}

- (void)connectTimeout:(NSTimer *)timer
{
    NSUInteger userID = [[[timer userInfo] objectForKey:kUserID] integerValue];
    for (NSNumber *startedSession in self.startedSession) {
        if ([startedSession integerValue] == userID) {
            return; //do nothing if connection established
        }
    }
    
    [self removeStartedSessionWithId:userID];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.statsScrollView.contentSize = self.statsImageVIew.frame.size;
    
    for (int i = 0; i < kMaxMansCount; ++i) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [button setImage:[UIImage imageNamed:@"propsAddImage"]
                forState:UIControlStateNormal];
        [button addTarget:self
                   action:@selector(givePropsAction:)
         forControlEvents:UIControlEventTouchUpInside];
        [self.propsContainer addSubview:button];
    }
    
    [self selectChat];
    NSLog(@"swarm show %@", [self.swarm getSwarmId]);
    
    if (self.isReplaceBack) {
        [self setUpImageBackButton];
        UIImage *navigationMainButtonImage = [UIImage imageNamed:@"navigationBarMainButton.png"];
        UIButton *navigationMainButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, navigationMainButtonImage.size.width, navigationMainButtonImage.size.height)];
        [navigationMainButton setImage:navigationMainButtonImage forState:UIControlStateNormal];
        [navigationMainButton addTarget:self action:@selector(popCurrentViewController) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.titleView = navigationMainButton;
    }
    
    [self updateSwarmScore];
    
    for (UIView *propsAddButton in [self.propsContainer subviews]) {
        [propsAddButton setHidden:YES];
    }
}

- (void)showAds
{
    if (self.adView) {
        [FlurryAds fetchAndDisplayAdForSpace:@"BOTTOM_IPAD"
                                        view:self.adView
                                        size:BANNER_BOTTOM];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)exitActions {
    if (self.adView) {
        [FlurryAds removeAdFromSpace:@"BOTTOM_IPAD"];
    }
    
    [self.videoCaptureOutput setSampleBufferDelegate:nil queue:nil];
    
    for (NSNumber *startedSess in [self.startedSession copy])
    {
        [self removeStartedSessionWithId:[startedSess integerValue]];
    }
    NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
	for (QBVideoChat *videoChat in copyArray) {
        [videoChat finishCall];
        [[QBChat instance] unregisterVideoChatInstance:videoChat];
    }
    
    [self.presenceTimer invalidate];
    self.presenceTimer = nil;
    [[QBChat instance] leaveRoom:self.chatRoom];
    self.chatRoom = nil;
    [[QBChat instance] logout];
    [self pauseAudioSession];
    [[QBChat instance] setDelegate:nil];
    
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    if (self.navigationController && [self.navigationController topViewController] == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)hardDisappear {
    [self exitActions];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isTwitterAnotherWindow) {
        return;
    }
    
    [self exitActions];

    [super viewWillDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
  
    [[QBChat instance] setDelegate:self];
    
    if (!self.isReplaceBack) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    
    if (self.isTwitterAnotherWindow) {
        self.isTwitterAnotherWindow = NO;
        return;
    }
    
    [self performSelector:@selector(showAds)];
    
    [self initMansViews];
    [self configureAudioSession];
//    [self pauseAudioSession];
    [self configureAndStartCaptureSession];
    
    [self.chatActivityIndicator setHidden:NO];
    
//    [self postFacebookAutoTimeline];
    
    self.testPresenceSended = NO;
    VSSettingsModel.currentUser.password = QBBaseModule.sharedModule.token;
    [QBSettings useTLSForChat:NO];
    [[QBChat instance] loginWithUser:VSSettingsModel.currentUser];
}

- (void)afterChatLoginAction
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    if (self.swarm.type == PrivateSwarmType) {
        [[VSSwarmsModel sharedInstance] findPrivateSwarm:[NSString stringWithFormat:@"%d", [self.swarm matchId]]
                                                  result:^(VSPrivateSwarm *swarm) {
                                                      if (swarm) {
                                                          self.roomForConnect = [swarm getSwarmId];
                                                          [[QBChat instance] createOrJoinRoomWithName:self.roomForConnect
                                                                                          membersOnly:NO
                                                                                           persistent:YES];
                                                      } else {
                                                          //TODO: make error alert here
                                                      }
                                                  }];
    } else if (self.swarm.type == VSSwarmType) {
        [[VSSwarmsModel sharedInstance] connectOrCreateToVsSwarm:self.swarm
                                                         result:^(VSvsSwarm *swarm) {
                                                             if (swarm) {
                                                                 self.roomForConnect = [swarm getSwarmId];
                                                                 [[QBChat instance] createOrJoinRoomWithName:self.roomForConnect
                                                                                                 membersOnly:NO
                                                                                                  persistent:YES];
                                                             } else {
                                                                 //TODO: make error alert here
                                                             }
                                                         }];
    } else if (self.swarm.type == TeamSwarmType) {
        [[VSSwarmsModel sharedInstance] connectOrCreateToTeamSwarm:self.swarm
                                                            result:^(VSTeamSwarm *swarm) {
                                                                if (swarm) {
                                                                    self.roomForConnect = [swarm getSwarmId];
                                                                    [[QBChat instance] createOrJoinRoomWithName:self.roomForConnect
                                                                                                    membersOnly:NO
                                                                                                     persistent:YES];
                                                                } else {
                                                                    //TODO: make error alert here
                                                                }
                                                            }];
    }
}

- (void)afterChatRoomJoinedAction
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    //sending test presence
    [[QBChat instance] sendPresenceWithParameters:@{@"test": @"test"}
                                           toRoom:self.chatRoom];
}

- (void)afterChatRoomOnlineUsersChanged:(NSArray *)onlineUsersArray
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    NSMutableArray *onlineUsers = [onlineUsersArray mutableCopy];
    BOOL isAfterTestPresence = NO;
    
    for (QBChatRoomOccupant *roomOccupant in onlineUsersArray) {
        if ([roomOccupant.nickname integerValue] == [VSSettingsModel currentUser].ID) {
            if ([roomOccupant.parameters objectForKey:@"test"] != nil) {
                isAfterTestPresence = YES;
            }
        }
        if ([[roomOccupant.parameters allKeys] count] < 3) //changable
        {
            [onlineUsers removeObject:roomOccupant];
        }
    }
    
    if (isAfterTestPresence) {
        if (self.swarm.type == PrivateSwarmType) {
            [self connectToCurrentRoom];
        } else if (self.swarm.type == TeamSwarmType) {
            if ([onlineUsers count] >= kMaxMansCount) {
                self.roomForConnect = [self.roomForConnect stringByAppendingString:@"0"];
                [[QBChat instance] leaveRoom:self.chatRoom];
                [[QBChat instance] createOrJoinRoomWithName:self.roomForConnect
                                                membersOnly:NO
                                                 persistent:NO];
            } else {
                [self connectToCurrentRoom];
            }
        } else if (self.swarm.type == VSSwarmType) {
            NSString *team = self.swarm.isMyHomeTeam ? @"true" : @"false";
            NSInteger myTeamCount = 0;
            for (QBChatRoomOccupant *roomOccupant in onlineUsers) {
                if ([roomOccupant.parameters[kIsHomeTeam] isEqualToString:team]) {
                    myTeamCount++;
                }
            }
            if (myTeamCount >= kMaxMansCount / 2) {
                self.roomForConnect = [self.roomForConnect stringByAppendingString:@"0"];
                [[QBChat instance] leaveRoom:self.chatRoom];
                [[QBChat instance] createOrJoinRoomWithName:self.roomForConnect
                                                membersOnly:NO
                                                 persistent:NO];
            } else {
                [self connectToCurrentRoom];
            }
        }
    }
    
    if (self.testPresenceSended) {
        [self updateMansViews:onlineUsersArray];
    }
}

- (void)connectToCurrentRoom
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    self.testPresenceSended = YES;
    [self.chatActivityIndicator setHidden:YES];
    self.connectTime = [NSDate date];
    [self resumeAudioSession];
    [self.presenceTimer invalidate];
    self.presenceTimer = [NSTimer scheduledTimerWithTimeInterval:40
                                                          target:self
                                                        selector:@selector(sendingPresence)
                                                        userInfo:nil
                                                         repeats:YES];
    [self.presenceTimer fire];
}

- (void)sendingPresence
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    [[QBChat instance] sendPresenceWithParameters:@{kConnectTime: [NSString stringWithFormat:@"%f", [self.connectTime timeIntervalSince1970]],
                                                    kFacebookId : [VSSettingsModel currentUser].facebookID,
                                                    kFullName   : [VSSettingsModel currentUser].fullName,
                                                    kIsHomeTeam : self.swarm.isMyHomeTeam ? @"true" : @"false"}
                                           toRoom:self.chatRoom];
}

- (void)updateSwarmScore
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    [self.homeTeamNameLabel setText:[NSString stringWithFormat:@"%@ %@", [[[self.swarm game] homeTeam] teamName], [[[self.swarm game] homeTeam] teamNickname]]];
    [self.homeTeamNameLabel setTextColor:[UIColor whiteColor]];
    [self.homeTeamScoreLabel setText:@""];
    
    [self.awayTeamNameLabel setText:[NSString stringWithFormat:@"%@ %@", [[[self.swarm game] awayTeam] teamName], [[[self.swarm game] awayTeam] teamNickname]]];
    [self.awayTeamNameLabel setTextColor:[UIColor whiteColor]];
    [self.awayTeamScoreLabel setText:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void) showView:(UIView*) aView selectButton:(UIButton*) aButton additionalView:(UIView*) adView {
    [self.chatButton setSelected:NO];
    [self.propsButton setSelected:NO];
    [self.socialButton setSelected:NO];
    [self.statsButton setSelected:NO];
    
    [self.socialContainer setHidden:YES];
    [self.statsContainer setHidden:YES];
    [self.chatContainer setHidden:YES];
    [self.propsContainer setHidden:YES];
    
    [aView setHidden:NO];
    [aButton setSelected:YES];
    [adView setHidden:NO];
    [self webViewCloseAction];
}

- (IBAction) selectChat {
    [Flurry logEvent:@"Swarm Screen Chat Tab Clicked"];
    [self showView:self.chatContainer
      selectButton:self.chatButton
    additionalView:nil];
}

- (IBAction) selectProps {
    [Flurry logEvent:@"Swarm Screen Props Tab Clicked"];
    [self showView:self.propsContainer
      selectButton:self.propsButton
    additionalView:self.chatContainer];
}

- (IBAction) selectSocial {
    [Flurry logEvent:@"Swarm Screen Social Tab Clicked"];
    [self showView:self.socialContainer
      selectButton:self.socialButton
    additionalView:nil];
}

- (IBAction) selectStats {
    [self showView:self.statsContainer
      selectButton:self.statsButton
    additionalView:nil];
}

- (IBAction) showHideProps {
    [Flurry logEvent:@"Swarm Screen Props Tab Clicked"];
    [self.propsContainer setHidden:!self.propsContainer.isHidden];
}

- (IBAction)tweetAction {
    [Flurry logEvent:@"Swarm Screen Tweet Button Clicked"];
    NSURL *url = [NSURL URLWithString:@"https://mobile.twitter.com/compose/tweet"];
    
    if ([self tabBarController] && [[self tabBarController] respondsToSelector:@selector(fullScreenWebView:)]) {
        self.isTwitterAnotherWindow = YES;
        [[self tabBarController] performSelector:@selector(fullScreenWebView:)
                                      withObject:url];
    } else {
        [self showUrl:url];
    }
}

- (IBAction)facebookAction {
    [Flurry logEvent:@"Swarm Screen Facebook Button Clicked"];
    [self showUrl:[NSURL URLWithString:@"https://m.facebook.com/dialog/feed?app_id=141769665866304&redirect_uri=http://api.quickblox.com/auth/facebook/callback"]];
}

- (void) initMansViews {
    for (int i = 0; i < kMaxMansCount; i++) {
        VSSwarmManViewController *manVC = [self.swarmMansArray objectAtIndex:i];
        [manVC.view setHidden:YES];
    }
    
    self.myView = [[self.swarmMansArray objectAtIndex:0] view];
    [self updateMansViewsSizeFor:1];
}

- (void) updateMansViewsSizeFor:(NSInteger)userCount {
    int columnCount = 2;
    int rowCount = 2;
    
    if (userCount == 1) {
        columnCount = 1;
        rowCount = 1;
//        [[[self.swarmMansArray objectAtIndex:0] view] setFrame:CGRectMake(0, 0, self.chatContainer.frame.size.width, self.chatContainer.frame.size.height)];
    }
//    else if (userCount == 2) {
//        columnCount = 1;
//        rowCount = 2;
//        [[[self.swarmMansArray objectAtIndex:0] view] setFrame:CGRectMake(0, 0, self.chatContainer.frame.size.width, self.chatContainer.frame.size.height / 2)];
//        [[[self.swarmMansArray objectAtIndex:1] view] setFrame:CGRectMake(0, self.chatContainer.frame.size.height / 2, self.chatContainer.frame.size.width, self.chatContainer.frame.size.height / 2)];
//    }
    else if (userCount <= 4) {
        columnCount = 2;
        rowCount = 2;
    }
//    else if (userCount <= 6) {
//        columnCount = 2;
//        rowCount = 3;
//    }
    else {
        //default
    }
    
    CGFloat width = self.chatContainer.frame.size.width / columnCount;
    CGFloat height = self.chatContainer.frame.size.height / rowCount;
    for (int i = 0; i < rowCount; ++i) {
        for (int j = 0; j < columnCount; ++j) {
            int index = i * columnCount + j;
            VSSwarmManViewController *manVC = [self.swarmMansArray objectAtIndex:index];
            [manVC.view setFrame:CGRectMake(j * width, i * height, width, height)];
            [manVC updateSpinnerPosition];
            [self.chatContainer addSubview:manVC.view];
            
            if ([[self.propsContainer subviews] count] > index) {
                [[[self.propsContainer subviews] objectAtIndex:index] setCenter:CGPointMake(j * width + width / 2, i * height + height / 2)];
                BOOL isHiddenProps = [manVC.view isHidden];
                if (index == 0) {
                    isHiddenProps = YES;
                }
                [[[self.propsContainer subviews] objectAtIndex:index] setHidden:isHiddenProps];
            }
        }
    }
    
    AVCaptureVideoPreviewLayer *prewLayer = nil;
    for (CALayer *layer in [self.myView.layer sublayers]) {
        if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]]) {
            prewLayer = (AVCaptureVideoPreviewLayer *)layer;
        }
    }
    if (prewLayer) {
        CGRect layerRect = [[self.myView layer] bounds];
        [prewLayer setBounds:layerRect];
        [prewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
    }
}

- (void) updateMansViews:(NSArray *)data {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    NSLog(@"updateMansViews: %@", data);
    
    NSMutableArray *usersInfo = [data mutableCopy];
    for (int i = 0; i < [usersInfo count]; ++i) {
        QBChatRoomOccupant *cro = [usersInfo objectAtIndex:i];
        if ([[cro nickname] integerValue] == [VSSettingsModel currentUser].ID || [[[cro parameters] allKeys] count] < 3) {
            [usersInfo removeObjectAtIndex:i];
            i--;
        }
    }
    
    for (int i = 1; i < kMaxMansCount; ++i) {
        VSSwarmManViewController *manVC = [self.swarmMansArray objectAtIndex:i];
        UIView *addPropsButton = NULL;
        if ([[self.propsContainer subviews] count] > i) {
            addPropsButton = [[self.propsContainer subviews] objectAtIndex:i];
        }
        
        if ([usersInfo count] > i - 1) {
            QBChatRoomOccupant *cro = [usersInfo objectAtIndex:i - 1];
            [manVC updateViewWithFacebookId:[[cro parameters] objectForKey:kFacebookId]
                               opponentName:[[cro parameters] objectForKey:kFullName]
                                 opponentId:[[cro nickname] integerValue]
                             connectionTime:[[[cro parameters] objectForKey:kConnectTime] doubleValue]];
            [manVC.view setHidden:NO];
            
            [addPropsButton setTag:[[cro nickname] integerValue]];
            [[(UIButton *)addPropsButton titleLabel] setText:[[cro parameters] objectForKey:kFullName]];
            [addPropsButton setHidden:NO];
        } else {
            [manVC.view setHidden:YES];
            [addPropsButton setHidden:YES];
        }
    }
    
    [[[self.swarmMansArray objectAtIndex:0] view] setHidden:NO]; //always show self cam view
    [[[self.propsContainer subviews] objectAtIndex:0] setHidden:YES]; //set hidden for self props button
    [self updateMansViewsSizeFor:[usersInfo count] + 1];
}

- (VSSwarmManViewController *) swarmMainVCWithId:(NSUInteger) opponentId
{
    for (VSSwarmManViewController* smvc in self.swarmMansArray) {
        if (smvc.opponentId == opponentId) {
            return smvc;
        }
    }
    return nil;
}

#pragma mark - Props

- (IBAction)givePropsAction:(id)sender {
    [Flurry logEvent:@"Props Try To Give"];
    
    if ([VSSettingsModel propsRest:[self.swarm getSwarmId]] > 0) {
        UIButton *senderButton = (UIButton *) sender;
        NSLog(@"tag %d text %@", [senderButton tag], [[senderButton titleLabel] text]);
        
        if ([[VSSettingsModel currentUser] ID] == [senderButton tag]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"You cannot give props to yourself"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        } else {
            [QBCustomObjects objectsWithClassName:PROPS_CLASS_NAME
                                  extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[senderButton tag]], @"_parent_id", nil]
                                         delegate:self
                                          context:(__bridge void *)([NSArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                                                     [[senderButton titleLabel] text],
                                                                     [NSNumber numberWithInteger:[senderButton tag]], nil])];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"You have no more props in this swarm"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    [self showView:self.chatContainer
      selectButton:self.chatButton
    additionalView:nil];
}

- (void) propsSucceedGived:(NSString *) userName {
    [Flurry logEvent:@"Props Successfully Given"];
    [VSSettingsModel propsIncreaseRest:[self.swarm getSwarmId]];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Props to %@ were given successfully", userName]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) givePropsTest {
    
    [QBCustomObjects objectsWithClassName:PROPS_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[[VSSettingsModel currentUser] ID]], @"_parent_id", nil]
                                 delegate:self];
}

#pragma mark - Facebook

- (void) postFacebookAutoTimeline {
//    return; //TODO: for test disabled
    
    if (![FBSession activeSession] || ![FBSession activeSession].isOpen) {
        NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
        NSString *socialProviderToken = [userDefs objectForKey:@"socialProviderToken"];
        NSDate *socialProviderTokenExpiresAt = [userDefs objectForKey:@"socialProviderTokenExpiresAt"];
        
        FBSession *ses = [[FBSession alloc] initWithAppID:nil
                                              permissions:nil
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
        
        [ses openFromAccessTokenData:[FBAccessTokenData createTokenFromString:socialProviderToken
                                                                  permissions:nil
                                                               expirationDate:socialProviderTokenExpiresAt
                                                                    loginType:FBSessionLoginTypeWebView
                                                                  refreshDate:nil]
                   completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                       NSLog(@"Were are here %@ status %d error %@", session, status, error);
                       NSLog(@"--------------------------------------------------------");
                       
                       [FBSession setActiveSession:session];
                       
                       [self postFacebookAutoTimeline];
                   }];
        return;
    }
    
    [FBRequestConnection startWithGraphPath:@"/me/feed"
                                 parameters:@{ @"message" : [NSString stringWithFormat:@"I've just joined the swarm using Vocal Swarm for %@", [self.swarm getFullDescription]]
     ,@"link": @"http://m.facebook.com/apps/141769665866304/?deeplink=news"
     }
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              NSLog(@"%@ result %@ error %@", connection, result, error);
                              NSLog(@"--------------------------------------------------------");
                          }];
}

#pragma mark - WebView

- (void) showUrl:(NSURL*) url {
    [self.webContainer setHidden:NO];
    [self.webView setHidden:YES];
    [self.webCloseButton setHidden:NO];
    [self.webActivity setHidden:NO];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:60];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *twitterCookie = [storage cookiesForURL:url];
    
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:twitterCookie];
    
    [request setAllHTTPHeaderFields:headers];
    
    NSLog(@"headers %@", headers);
    
    [self.webView loadRequest:request];
}

- (IBAction)webViewCloseAction {
    [self.webContainer setHidden:YES];
}

- (void) showActivity {
    [self.webActivity setHidden:NO];
}

- (void) hideActivity {
    [self.webActivity setHidden:YES];
    [self.webView setHidden:NO];
    [self.webCloseButton setHidden:NO];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSRange domainRange = [[[request URL] host] rangeOfString:@"quickblox.com"];
    if (domainRange.length > 0) {
        [self webViewCloseAction];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    [self showActivity];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    [self hideActivity];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    NSLog(@"%@", error);
    if ([error code] == NSURLErrorCancelled || [error code] == 102)
        return;
    
    //TODD 102 change to appropriate error define Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"])
        return;
    
    [self hideActivity];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please check your internet connection"
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
    [alertView show];
    [self webViewCloseAction];
}

#pragma mark - QBDelegate

- (void)completedWithResult:(Result*)result context:(void *)contextInfo {
    NSArray *contextInfoArray = (__bridge NSArray *)(contextInfo);
    BOOL isFinal = YES;
    if ([contextInfoArray count] > 0) {
        isFinal = [[contextInfoArray objectAtIndex:0] boolValue];
    }
    NSString *targetUser = @"";
    if ([contextInfoArray count] > 1) {
        targetUser = [contextInfoArray objectAtIndex:1];
    }
    NSInteger targetUserId = 0;
    if ([contextInfoArray count] > 2) {
        targetUserId = [[contextInfoArray objectAtIndex:2] integerValue];
    }
    
    if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]] || [result isKindOfClass:[QBCOCustomObjectResult class]]) {
        if (!result.success) {
            if (isFinal) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Error occurred while props giving"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                QBCOCustomObject* co =  [[QBCOCustomObject alloc] init];
                [co setFields:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], PROPS_COLUMN_NAME, nil]];
                [co setParentID:[NSString stringWithFormat:@"%d", [[VSSettingsModel currentUser] ID]]];
                [co setClassName:PROPS_CLASS_NAME];
                
                [QBCustomObjects createObject:co
                                     delegate:self
                                      context:(__bridge void *)([NSArray arrayWithObjects:[NSNumber numberWithBool:YES],
                                                                 targetUser,
                                                                 [NSNumber numberWithInteger:targetUserId], nil])];
            }
        } else { //success result
            if (isFinal) {
                [self propsSucceedGived:targetUser];
            } else {
                QBCOCustomObject* co = nil;
                
                if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]]) {
                    NSArray *coArr = [(QBCOCustomObjectPagedResult*)result objects];
                    if ([coArr count] > 0) {
                        co = [coArr objectAtIndex:0];
                    }
                } else {
                    co = [(QBCOCustomObjectResult*)result object];
                }
                
                if (!co) {
                    QBCOCustomObject* co =  [[QBCOCustomObject alloc] init];
                    [co setFields:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], PROPS_COLUMN_NAME, nil]];
                    [co setParentID:[NSString stringWithFormat:@"%d", targetUserId]];
                    [co setClassName:PROPS_CLASS_NAME];
                    
                    [QBCustomObjects createObject:co
                                         delegate:self
                                          context:(__bridge void *)([NSArray arrayWithObjects:[NSNumber numberWithBool:YES],
                                                                     targetUser,
                                                                     [NSNumber numberWithInteger:targetUserId], nil])];
                } else {
                    NSMutableDictionary *fields = [co fields];
                    
                    int propsCount = 0;
                    
                    if ([fields objectForKey:PROPS_COLUMN_NAME]) {
                        propsCount = [[fields objectForKey:PROPS_COLUMN_NAME] intValue];
                    }
                    
                    propsCount++;
                    
                    [fields setObject:[NSNumber numberWithInteger:propsCount] forKey:PROPS_COLUMN_NAME];
                    
                    [co setFields:fields];
                    
                    [QBCustomObjects updateObject:co
                                         delegate:self
                                          context:(__bridge void *)([NSArray arrayWithObjects:[NSNumber numberWithBool:YES],
                                                                                                targetUser,
                                                                                                [NSNumber numberWithInteger:targetUserId], nil])];
                }
            }
        }
    }
}

#pragma mark - QBChatDelegate

- (void)chatDidLogin
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    if ([self.navigationController topViewController] == self) { //so hard hack
        [self afterChatLoginAction];
    }
}

- (void)chatDidNotLogin
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    //TODO: do something here
}

- (void)chatRoomDidReceiveInformation:(NSDictionary *)information room:(NSString *)roomName
{
    NSLog(@"%@ %@ information:%@ roomName:%@", NSStringFromSelector(_cmd), self, information, roomName);
}

- (void)chatRoomDidEnter:(QBChatRoom *)room
{
    NSLog(@"%@ %@ room:%@", NSStringFromSelector(_cmd), self, room);
    if ([self.navigationController topViewController] == self) { //so hard hack
        self.chatRoom = room;
        [self afterChatRoomJoinedAction];
    }
}

- (void)chatRoomDidNotEnter:(NSString *)roomName error:(NSError *)error
{
    NSLog(@"%@ %@ roomName:%@ error:%@", NSStringFromSelector(_cmd), self, roomName, error);
    //TODO: do something here
}

- (void)chatDidFailWithError:(int)code
{
    NSLog(@"%@ %@ code:%d", NSStringFromSelector(_cmd), self, code);
}

- (void)chatRoomDidLeave:(NSString *)roomName
{
    NSLog(@"%@ %@ roomName:%@", NSStringFromSelector(_cmd), self, roomName);
}

- (void)chatRoomDidChangeOnlineUsers:(NSArray *)onlineUsers room:(NSString *)roomName
{
    NSLog(@"%@ %@ onlineUsers:%@ roomName:%@", NSStringFromSelector(_cmd), self, onlineUsers, roomName);
    if ([self.navigationController topViewController] == self) { //so hard hack
        [self afterChatRoomOnlineUsersChanged:onlineUsers];
    }
}

- (void)chatRoomDidReceiveListOfUsers:(NSArray *)users room:(NSString *)roomName
{
    NSLog(@"%@ %@ users:%@ roomName:%@", NSStringFromSelector(_cmd), self, users, roomName);
}

- (void)chatRoomDidReceiveListOfOnlineUsers:(NSArray *)users room:(NSString *)roomName
{
    NSLog(@"%@ %@ users:%@ roomName:%@", NSStringFromSelector(_cmd), self, users, roomName);
}

#pragma mark - VSSwarmManProtocol

- (NSTimeInterval) connectionTime
{
    return [self.connectTime timeIntervalSince1970];
}

- (BOOL) isSessionEstablished:(NSUInteger) userID
{
    for (NSNumber *user in self.startedSession) {
        if ([user integerValue] == userID) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Capture session

-(void)configureAndStartCaptureSession
{
	self.captureSession = [[AVCaptureSession alloc] init];
	
    // set preset
    [self.captureSession setSessionPreset:AVCaptureSessionPresetLow];
    
    [self addInput];
	
	// Setup Video output
    self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [self.videoCaptureOutput setVideoSettings:videoSettings];
    if([self.captureSession canAddOutput:self.videoCaptureOutput]){
        [self.captureSession addOutput:self.videoCaptureOutput];
    }else{
        NSLog(@"cantAddOutput");
    }
	
	// set FPS
    [self setChoosedFPS];
    
    /*We create a serial queue to handle the processing of our frames*/
    
    dispatch_queue_t callbackQueue = dispatch_queue_create("cameraQueue", NULL);
    [self.videoCaptureOutput setSampleBufferDelegate:self queue:callbackQueue];
	//    dispatch_release(callbackQueue);
	
	// Add preview layer
    AVCaptureVideoPreviewLayer *prewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	[prewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CGRect layerRect = [[self.myView layer] bounds];
	[prewLayer setBounds:layerRect];
	[prewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
    self.myView.hidden = NO;
	[self.myView.layer addSublayer:prewLayer];
    
    /*We start the capture*/
    [self.captureSession startRunning];
}

- (void)addInput
{
    [self.captureSession beginConfiguration];
    
	// Setup the Video input
    self.videoDevice = [VSUtils frontFacingCamera];
    //
    // remove old input
	if (self.captureSession.inputs.count) {
		[self.captureSession removeInput:[self.captureSession inputs][0]];
	}
    
    // add new one
    AVCaptureDeviceInput *captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
    {
        if ([self.captureSession canAddInput:captureVideoInput]){
            [self.captureSession addInput:captureVideoInput];
        }else{
            QBDLogEx(@"cantAddInput");
        }
    }
    
    [self.captureSession commitConfiguration];
}

-(void)setChoosedFPS
{
    int framesPerSecond = 10;
    AVCaptureConnection *conn = [self.videoCaptureOutput connectionWithMediaType:AVMediaTypeVideo];
	if (conn.videoMinFrameDuration.timescale == framesPerSecond){
		return;
	}
	
    if (conn.isVideoMinFrameDurationSupported){
        conn.videoMinFrameDuration = CMTimeMake(1, framesPerSecond);
    }
    if (conn.isVideoMaxFrameDurationSupported){
        conn.videoMaxFrameDuration = CMTimeMake(1, framesPerSecond);
    }
    
    QBDLogEx(@"set FPS: %d", conn.videoMaxFrameDuration.timescale);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
	for (QBVideoChat *videoChat in copyArray){
		[videoChat processVideoChatCaptureVideoSample:sampleBuffer];
	}
}

#pragma mark - Audio Session

-(void)configureAudioSession
{
    TPCircularBufferInit(&circularBuffer, kBufferLength);
    
    [[QBAudioIOService shared] routeToSpeaker];
}

-(void)pauseAudioSession
{
    [[QBAudioIOService shared] setInputBlock:nil];
    [[QBAudioIOService shared] stop];
}

-(void)resumeAudioSession
{
    [[QBAudioIOService shared] setInputBlock:^(AudioBuffer buffer){
        NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
        for (QBVideoChat *videoChat in copyArray){
            [videoChat processVideoChatCaptureAudioBuffer:buffer];
        }
    }];
    
    [[QBAudioIOService shared] start];
}

#pragma mark - QBVideoChatDelegate

-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID withSessionID:(NSString *)sessionID conferenceType:(enum QBVideoChatConferenceType)conferenceType
{
    [self chatDidReceiveCallRequestFromUser:userID withSessionID:sessionID conferenceType:conferenceType customParameters:nil];
}

-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID
                            withSessionID:(NSString *)sessionID
                           conferenceType:(enum QBVideoChatConferenceType)conferenceType
                         customParameters:(NSDictionary *)customParameters
{
    NSLog(@"%@ %d %@ %d %@", NSStringFromSelector(_cmd), userID, sessionID, conferenceType, customParameters);
    // Accept call
    QBVideoChat *videoChat = [[QBChat instance] createAndRegisterVideoChatInstanceWithSessionID:sessionID];
    [videoChat setIsUseCustomVideoChatCaptureSession:YES];
    [videoChat setIsUseCustomAudioChatSession:YES];
    
    [videoChat acceptCallWithOpponentID:userID conferenceType:conferenceType];
    
    // setup connection timeout timer
    //TODO: mb addTimers to instance variable
    NSTimer* reconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                                      target:self
                                                                    selector:@selector(connectTimeout:)
                                                                    userInfo:@{kUserID : [NSNumber numberWithUnsignedInteger:userID]}
                                                                     repeats:NO];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID
{
    [self chatCallDidAcceptByUser:userID customParameters:nil];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID customParameters:(NSDictionary *)customParameters
{
    NSLog(@"%@ %d %@", NSStringFromSelector(_cmd), userID, customParameters);
}

-(void) chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status
{
    [self chatCallDidStopByUser:userID status:status customParameters:nil];
}

-(void) chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status customParameters:(NSDictionary *)customParameters
{
    NSLog(@"%@ %d %@ %@", NSStringFromSelector(_cmd), userID, status, customParameters);
    [self removeStartedSessionWithId:userID];
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID sessionID:(NSString *)sessionID
{
    NSLog(@"%@ %d %@", NSStringFromSelector(_cmd), userID, sessionID);
    [self.startedSession addObject:[NSNumber numberWithUnsignedInteger:userID]];
    NSArray *copyArray = [[QBChat instance].registeredVideoChatInstances copy];
	for (QBVideoChat *videoChat in copyArray) {
        if ([videoChat.sessionID isEqualToString:sessionID]) {
            [videoChat setMicrophoneEnabled:YES];
            [[self swarmMainVCWithId:userID] updateViewWithVideoChat:videoChat];
        }
    }
}

-(void) chatCallUserDidNotAnswer:(NSUInteger)userID
{
    NSLog(@"%@ %d", NSStringFromSelector(_cmd), userID);
    [self removeStartedSessionWithId:userID];
}

-(void) chatCallDidRejectByUser:(NSUInteger)userID
{
    NSLog(@"%@ %d", NSStringFromSelector(_cmd), userID);
    [self removeStartedSessionWithId:userID];
}

-(void) chatTURNServerDidDisconnect
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

-(void) chatTURNServerdidFailWithError:(NSError *)error
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), error);
}

- (void)didReceiveAudioBuffer:(AudioBuffer)buffer {
    // Put audio into circular buffer
    //
    TPCircularBufferProduceBytes(&circularBuffer, buffer.mData, buffer.mDataByteSize);
    
    // Get number of bytes in circular buffer
    //
    int32_t availableBytes;
    TPCircularBufferTail(&circularBuffer, &availableBytes);
    
    // If output block is NIL and we have audio data for 0.5 second
    //
    if([[QBAudioIOService shared] outputBlock] == nil && availableBytes > qbAudioDataSizeForSecods(0.5)){
        
        QBDLogEx(@"Set output block");
        [[QBAudioIOService shared] setOutputBlock:^(AudioBuffer buffer) {
            
            int32_t availableBytesInBuffer;
            void *cbuffer = TPCircularBufferTail(&circularBuffer, &availableBytesInBuffer);
            
            // Read audio data if exist
            if(availableBytesInBuffer > 0){
                int min = MIN(buffer.mDataByteSize, availableBytesInBuffer);
                memcpy(buffer.mData, cbuffer, min);
                TPCircularBufferConsume(&circularBuffer, min);
            }else{
                // No data to play -> mute output
                QBDLogEx(@"No data to play -> mute output");
                [[QBAudioIOService shared] setOutputBlock:nil];
            }
            
            // If there is to much audio data to play -> clear buffer & mute output
            //
            if(availableBytes > qbAudioDataSizeForSecods(3)) {
                QBDLogEx(@"There is to much audio data to play -> clear buffer & mute output");
                TPCircularBufferClear(&circularBuffer);
                
                [[QBAudioIOService shared] setOutputBlock:nil];
            }
        }];
    }
}

@end
