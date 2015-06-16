//
//  VSSwarmSelectionViewController.m
//  VocalSwarm
//
//  Created by Alexey on 18.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSwarmSelectionViewController.h"
#import "VSSwarm.h"
#import "VSGame.h"
#import "VSSwarmMainViewController.h"
#import "VSSwarmsModel.h"
#import "VSTabBarViewController.h"
#import "VSSettingsModel.h"
#import "VSPrivateSwarm.h"
#import <FacebookSDK/FacebookSDK.h>

@interface VSSwarmSelectionViewController () <UIPickerViewDataSource, UIPickerViewDelegate, FBViewControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *typePicker;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *swarmNameLabel;
@property (weak, nonatomic) IBOutlet UIView *activityContainer;

@property (strong, nonatomic) NSMutableArray *data;

- (IBAction)selectTypeAction;
- (IBAction)joinAction;

@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (nonatomic) BOOL isPrivateSwarmCreationProccess;

- (IBAction)backAction;

@end

@implementation VSSwarmSelectionViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _data = [NSMutableArray arrayWithObjects:@"Team swarm",
                                                @"Versus swarm",
                                                @"Private swarm", nil];
        _isPrivateSwarmCreationProccess = NO;
        _swarm = nil;
        _isJoinAfterCreate = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateJoinButtonState];
    
    [self.swarmNameLabel setText:[self.swarm getFullDescription]];
    [self.activityContainer setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isPrivateSwarmCreationProccess) {
        [self.activityContainer setHidden:NO];
        [self creationCheck];
        return;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) privateSwarmCreationError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"VocalSwarm Error"
                                                        message:@"Error occurred while creating a swarm"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) jointToSwarmError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"VocalSwarm Error"
                                                        message:@"Error occurred while connecting to swarm"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) showFacebookError:(NSError *) error {
    self.isPrivateSwarmCreationProccess = NO;
    [self.activityContainer setHidden:NO];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"VocalSwarm Error"
                                                        message:[NSString stringWithFormat:@"Facebook error occured %@", [error localizedDescription]]
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) finishCreation
{
//    NSLog(@"%@", self.parentViewController);
//    NSLog(@"%@", self.parentViewController.parentViewController);
    if (self.parentViewController && self.parentViewController.parentViewController &&
        [self.parentViewController.parentViewController respondsToSelector:@selector(homeAction)]) {
        NSObject *mainMenuObj = self.parentViewController.parentViewController;
        [mainMenuObj performSelector:@selector(homeAction)];
        if (self.isJoinAfterCreate) {
            [mainMenuObj performSelector:@selector(showSwarm:) withObject:self.swarm];
        }
    } else {
        UITabBarController *tabBarController = self.navigationController.tabBarController;
        if ([tabBarController isKindOfClass:[VSTabBarViewController class]]) {
            if (self.isJoinAfterCreate) {
                [(VSTabBarViewController*)tabBarController liveSwarmJoin:self.swarm];
            } else {
                [(VSTabBarViewController*)tabBarController scheduledSwarmsAction];
            }
        }
    }
}

- (void) updateJoinButtonState {
    self.joinButton.enabled = ![self.typeLabel.text isEqualToString:@"Swarm Type"];
}

- (IBAction)selectTypeAction {
    if (self.typePicker.hidden) {
        [self showPicker];
    } else {
        [self hidePicker];
    }
}

- (IBAction)joinAction {
    [Flurry logEvent:@"Create now clicked"];
    if ([self.typeLabel.text isEqualToString:[self.data objectAtIndex:0]]) {
        [self.swarm setType:TeamSwarmType];
        [Flurry logEvent:@"Create Team Swarm Type"];
    } else if ([self.typeLabel.text isEqualToString:[self.data objectAtIndex:1]]) {
        [self.swarm setType:VSSwarmType];
        [Flurry logEvent:@"Create Versus Swarm Type"];
    } else if ([self.typeLabel.text isEqualToString:[self.data objectAtIndex:2]]) {
        [self.swarm setType:PrivateSwarmType];
        [Flurry logEvent:@"Create Private Swarm Type"];
    }
    
    [self.activityContainer setHidden:NO];
    
    if ([self.swarm type] == PrivateSwarmType) {
        self.isPrivateSwarmCreationProccess = YES;
        [self presentFBFriendPicker];
    } else {
        [self creationCheck];
    }
}

- (void)creationCheck {
    [[VSSwarmsModel sharedInstance] findSwarms:self.swarm forUser:[VSSettingsModel currentUser].facebookID result:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            for (VSSwarm *swarm in swarms) {
                [swarm setGame:self.swarm.game];
                [[VSSwarmsModel sharedInstance] removeSwarm:swarm];
            }
        }
        
        if (self.swarm.type == PrivateSwarmType) {
            [self privateSwarmCreate];
        } else {
            [self createSwarm];
        }
    }];
}

- (void)createSwarm {
    [[VSSwarmsModel sharedInstance] createSwarm:self.swarm
                                        forUser:[VSSettingsModel currentUser].facebookID
                                         result:^(VSSwarm *swarm) {
                                             if (swarm) {
                                                 swarm.game = self.swarm.game;
                                                 self.swarm = swarm;
                                                 VSTeam *myTeam = [self.swarm isMyHomeTeam] ? self.swarm.game.homeTeam : self.swarm.game.awayTeam;
                                                 [Flurry logEvent:@"Create Swarm for Team" withParameters:@{@"Team Name" : [NSString stringWithFormat:@"%@ %@", myTeam.teamName, myTeam.teamNickname]}];
                                                 
                                                 [self finishCreation];
                                             } else {
                                                 [self jointToSwarmError];
                                             }
                                             
                                         }];
}

- (void)privateSwarmCreate {
    NSMutableArray *participantsIDs = [NSMutableArray array];
    for (NSObject<FBGraphUser>* user in self.friendPickerController.selection) {
        [participantsIDs addObject:[user id]];
    }
    
    [[VSSwarmsModel sharedInstance] createPrivateSwarm:self.swarm
                                          participants:participantsIDs
                                                result:^(VSPrivateSwarm *swarm) {
                                                    self.isPrivateSwarmCreationProccess = NO;
                                                    if (swarm) {
                                                        [self privateSwarmCreationProcessFor:[swarm.participants mutableCopy]];
                                                    } else {
                                                        [self.activityContainer setHidden:YES];
                                                        [self privateSwarmCreationError];
                                                    }
                                                }];
}

- (void)privateSwarmCreationProcessFor:(NSMutableArray *)users
{
    if ([users count] > 0) {
        [[VSSwarmsModel sharedInstance] createSwarm:self.swarm
                                            forUser:[users lastObject]
                                             result:^(VSSwarm *swarm) {
                                                [users removeLastObject];
                                                [self privateSwarmCreationProcessFor:users];
                                            }];
    } else {
        [self finishCreation];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"swarmChatSegue"]) {
        VSSwarmMainViewController *destVC = segue.destinationViewController;
        
        [destVC setSwarm:self.swarm];
    }
}

- (void) showPicker {
    CGRect pickerFrame = self.typePicker.frame;
    pickerFrame.origin.y = self.view.frame.size.height;
    self.typePicker.frame = pickerFrame;
    self.typePicker.alpha = 0.0;
    self.typePicker.hidden = NO;
    self.view.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         CGRect pickerFrame = self.typePicker.frame;
                         pickerFrame.origin.y = self.container.frame.size.height +
                         self.container.frame.origin.y;
                         self.typePicker.frame = pickerFrame;
                         self.typePicker.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (self.typePicker.frame.origin.y + self.typePicker.frame.size.height > self.view.frame.size.height) {
                             [UIView animateWithDuration:0.2
                                              animations:^{
                                                  CGRect pickerFrame = self.typePicker.frame;
                                                  pickerFrame.origin.y = self.view.frame.size.height - pickerFrame.size.height;
                                                  self.typePicker.frame = pickerFrame;
                                                  CGRect containerFrame = self.container.frame;
                                                  containerFrame.origin.y = self.typePicker.frame.origin.y - containerFrame.size.height;
                                                  self.container.frame = containerFrame;
                                              }
                                              completion:^(BOOL finished) {
                                                  self.view.userInteractionEnabled = YES;
                                              }];
                         } else {
                             self.view.userInteractionEnabled = YES;
                         }
                     }];
}

- (void) hidePicker {
    self.view.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.container.center = self.view.center;
                         
                         CGRect pickerFrame = self.typePicker.frame;
                         pickerFrame.origin.y = self.container.frame.origin.y + self.container.frame.size.height;
                         self.typePicker.frame = pickerFrame;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              CGRect pickerFrame = self.typePicker.frame;
                                              pickerFrame.origin.y = self.view.frame.size.height;
                                              self.typePicker.frame = pickerFrame;
                                              self.typePicker.alpha = 0.0;
                                          }
                                          completion:^(BOOL finished) {
                                              self.typePicker.hidden = YES;
                                              self.view.userInteractionEnabled = YES;
                                          }];
                     }];
}

#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.data count] + 1;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return @"";
    } else {
        return [self.data objectAtIndex:row - 1];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        [self.typeLabel setText:@"Swarm Type"];
    } else {
        [self.typeLabel setText:[self.data objectAtIndex:row - 1]];
    }
    [self updateJoinButtonState];
}

- (void) presentFBFriendPicker {
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
                       
                       if (error) {
                           [self showFacebookError:error];
                       } else {
                           [self presentFBFriendPicker];
                       }
                   }];
        return;
    }
    
    if (self.friendPickerController == nil) {
        self.friendPickerController = [[FBFriendPickerViewController alloc] init];
        //        self.friendPickerController.title = @"Pick Friends";
        self.friendPickerController.delegate = self;
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    
    if (self.tabBarController && self.tabBarController.navigationController) {
        [self.tabBarController.navigationController pushViewController:self.friendPickerController animated:YES];
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:self.friendPickerController animated:YES];
    }
    
//    [self.friendPickerController.navigationItem.backBarButtonItem setTitle:@"Cancel"];
}

- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error {
    [self showFacebookError:error];
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    if (self.tabBarController && self.tabBarController.navigationController) {
        [self.tabBarController.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    [self postPrivateSwarmFeed:self.friendPickerController.selection]; //TODO: for test here
    
    if (self.tabBarController && self.tabBarController.navigationController) {
        [self.tabBarController.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)postPrivateSwarmFeed:(NSArray *)friends {
    if (friends && [friends count] > 0) {
        
        NSString *resultFriendList = @"";
        for (NSObject<FBGraphUser>* user in friends) {
            resultFriendList = [NSString stringWithFormat:@"%@,%@", resultFriendList, user.id];
        }
        resultFriendList = [resultFriendList substringFromIndex:1];
        
        [FBRequestConnection startWithGraphPath:@"/me/feed"
                                     parameters:@{ @"message" : [NSString stringWithFormat:@"I've just created the private swarm using Vocal Swarm for %@ ", [self.swarm getFullDescription]]
         ,@"link": @"http://m.facebook.com/apps/141769665866304/?deeplink=news"
         ,@"place": @"230285946792"
         ,@"tags" : resultFriendList
         }
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  NSLog(@"%@ result %@ error %@", connection, result, error);
                                  NSLog(@"--------------------------------------------------------");
                              }];
    }
}

- (IBAction)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
