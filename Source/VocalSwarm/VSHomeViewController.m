//
//  VSHomeViewController.m
//  VocalSwarm
//
//  Created by Alexey on 10.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSHomeViewController.h"

#import "VSTabBarViewController.h"
#import "VSSettingsModel.h"
#import "VSNetworkChalk.h"
#import "VSGame.h"
#import "VSSwarm.h"
#import "VSSwarmsModel.h"

@interface VSHomeViewController () <UITableViewDataSource, UITableViewDelegate, QBActionStatusDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSInteger propsCount;
@property (nonatomic, strong) NSArray *liveMatchesData;

@property (nonatomic, strong) NSTimer *updateTimer;

@property (weak, nonatomic) IBOutlet UIView *activityView;

- (IBAction)scheduleSwarmAction;
- (IBAction)alertsMessagesAction;
- (IBAction)homeAction;
- (IBAction)joinLiveAction:(id)sender;

@end

@implementation VSHomeViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _displayType = displayTypeDefault;
        _propsCount = 0;
        _liveMatchesData = [NSArray array];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60*4
                                                        target:self
                                                      selector:@selector(updateLiveMatches)
                                                      userInfo:nil
                                                       repeats:YES];
    [self.updateTimer fire];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.updateTimer fire];
    
    [self updatePropsCount];
    
    [self.activityView setHidden:YES];
}

- (void)updateLiveMatches {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self proccessLiveMatchesForFavoriteTeams:[NSMutableArray arrayWithArray:[VSSettingsModel getFavoriteTeams]] resultData:[NSMutableArray array]];
    });
}

- (void)proccessLiveMatchesForFavoriteTeams:(NSMutableArray *)favoriteTeams resultData:(NSMutableArray *)result {
    if ([favoriteTeams count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.liveMatchesData = [NSArray arrayWithArray:result];
            [self.tableView reloadData];
        });
    } else {
        VSSportLeague *sportLeague = [(VSTeam *)[favoriteTeams lastObject] sportLeague];
        NSMutableArray *teamsLooks = [NSMutableArray array];
        for (int i = 0; i < [favoriteTeams count]; ++i) {
            VSTeam *team = [favoriteTeams objectAtIndex:i];
            if ([[team sportLeague] isEqual:sportLeague]) {
                [teamsLooks addObject:team];
                [favoriteTeams removeObjectAtIndex:i];
                i--;
            }
        }
        
//        [[VSNetworkChalk sharedInstance] lastWeekMatchesForSportLeague:sportLeague
//                                                                result:^(NSArray *games) {
//                                                                    for (VSTeam *team in teamsLooks) {
//                                                                        for (VSGame *game in games) {
//                                                                            if ([[game homeTeam] isEqual:team] || [[game awayTeam] isEqual:team]) {
//                                                                                [result addObject:@{@"team" : team, @"game" : game}];
//                                                                                break;
//                                                                            }
//                                                                        }
//                                                                    }
//                                                                    
//                                                                    [self proccessLiveMatchesForFavoriteTeams:favoriteTeams resultData:result];
//                                                                }];
        [[VSNetworkChalk sharedInstance] liveMatchesForSportLeague:sportLeague result:^(NSArray *games) {
            for (VSTeam *team in teamsLooks) {
                for (VSGame *game in games) {
                    if ([[game homeTeam] isEqual:team] || [[game awayTeam] isEqual:team]) {
                        [result addObject:@{@"team" : team, @"game" : game}];
                        break;
                    }
                }
            }
            
            [self proccessLiveMatchesForFavoriteTeams:favoriteTeams resultData:result];
        }];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)scheduleSwarmAction {
    [Flurry logEvent:@"Create Swarm Button Clicked"];
    if (self.parentViewController &&
        [self.parentViewController respondsToSelector:@selector(showScheduleAction)]) {
        [self.parentViewController performSelector:@selector(showScheduleAction)];
    } else {
        UITabBarController *tabBarController = self.navigationController.tabBarController;
        if ([tabBarController isKindOfClass:[VSTabBarViewController class]]) {
            [(VSTabBarViewController*)tabBarController scheduleSwarmAction];
        }
    }
}

- (IBAction)alertsMessagesAction {
    if (self.parentViewController &&
        [self.parentViewController respondsToSelector:@selector(showMessagesAction)]) {
        [self.parentViewController performSelector:@selector(showMessagesAction)];
    }
}

- (IBAction)homeAction {
    [Flurry logEvent:@"Scheduled Swarms Button Clicked"];
    if (self.parentViewController &&
        [self.parentViewController respondsToSelector:@selector(homeAction)]) {
        [self.parentViewController performSelector:@selector(homeAction)];
        [self updatePropsCount];
    } else {
        UITabBarController *tabBarController = self.navigationController.tabBarController;
        if ([tabBarController isKindOfClass:[VSTabBarViewController class]]) {
            [(VSTabBarViewController*)tabBarController scheduledSwarmsAction];
        }
    }
}

- (IBAction)joinLiveAction:(id)sender {
    NSInteger index = [(UIButton*)sender tag];
    [self joinLive:index];
}

- (void)joinLive:(NSInteger) index {
    NSDictionary *gameTeamDict = [self.liveMatchesData objectAtIndex:index];
    VSGame *game = [gameTeamDict objectForKey:@"game"];
    VSTeam *team = [gameTeamDict objectForKey:@"team"];
    NSLog(@"join to team %@ game %@", team, game);
    
    if (self.parentViewController && [self.parentViewController respondsToSelector:@selector(liveSwarmShowActivityIndicator)]) {
        [self.parentViewController performSelector:@selector(liveSwarmShowActivityIndicator)];
    } else {
        [self.activityView setHidden:NO];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[VSSwarmsModel sharedInstance] updateSwarmDataWithResult:^(NSArray *swarms) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //TODO current take first of appropriate swarm, but we can have few for same game
                VSSwarm *swarm = nil;
                for (VSSwarm *sw in swarms) {
                    if ([sw.game isEqual:game]) {
                        swarm = sw;
                        break;
                    }
                }
                
                if (swarm) { //join to existing
                    if (self.parentViewController &&
                        [self.parentViewController respondsToSelector:@selector(showSwarm:)]) { //iPad
                        [self.parentViewController performSelector:@selector(showSwarm:) withObject:swarm];
                    } else { //iPhone
                        UITabBarController *tabBarController = self.navigationController.tabBarController;
                        if ([tabBarController isKindOfClass:[VSTabBarViewController class]]) {
                            [(VSTabBarViewController*)tabBarController liveSwarmJoin:swarm];
                        }
                    }
                } else { //create new one
                    swarm = [[VSSwarm alloc] init];
                    [swarm setGame:game];
                    [swarm setSportLeague:[[team sportLeague] shortCode]];
                    if ([team isEqual:[game homeTeam]]) {
                        [swarm setIsMyHomeTeam:YES];
                    } else {
                        [swarm setIsMyHomeTeam:NO];
                    }

                    
                    if (self.parentViewController &&
                        [self.parentViewController respondsToSelector:@selector(selectTypeForSwarm:)]) { //iPad
                        [self.parentViewController performSelector:@selector(selectTypeForSwarm:) withObject:swarm];
                    } else { //iPhone
                        UITabBarController *tabBarController = self.navigationController.tabBarController;
                        if ([tabBarController isKindOfClass:[VSTabBarViewController class]]) {
                            [(VSTabBarViewController*)tabBarController liveSwarmCreate:swarm];
                        }
                    }
                }
                
                if (self.parentViewController && [self.parentViewController respondsToSelector:@selector(liveSwarmHideActivityIndicator)]) {
                    [self.parentViewController performSelector:@selector(liveSwarmHideActivityIndicator)];
                } else {
                    [self.activityView setHidden:YES];
                }
            });
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if ([self.displayType isEqualToString:displayTypeiPad]) {
//        return 5  + [self.liveMatchesData count];
//    }
    return 3 + [self.liveMatchesData count];
}

static NSString* homeCustomEventCellIdentifier = @"homeCustomEventCellIdentifier";
static NSString* homeNewSwarmCellIdentifier = @"homeNewSwarmCellIdentifier";
static NSString* homePropsCellIdentifier = @"homePropsCellIdentifier";
static NSString* homeLiveCellIdentifier = @"homeLiveCellIdentifier";
static NSString* homeSwarmsCellIdentifier = @"homeSwarmsCellIdentifier";
static NSString* homeMessagesCellIdentifier = @"homeMessagesCellIdentifier";

- (NSString *) identifierForIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == 0) {
        return homeCustomEventCellIdentifier;
    } else if ([indexPath row] == 1) {
        return homeNewSwarmCellIdentifier;
    } else if ([indexPath row] - 2 < [self.liveMatchesData count] && [indexPath row] - 2 >= 0) {
        return homeLiveCellIdentifier;
    } else if ([indexPath row] - [self.liveMatchesData count] == 2) {
        return homeSwarmsCellIdentifier;
    } else if ([indexPath row] - [self.liveMatchesData count] == 3) {
        return homeMessagesCellIdentifier;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:[self identifierForIndexPath:indexPath]];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:[self identifierForIndexPath:indexPath]];
    }
    
    UIView *propsCountButton = [cell viewWithTag:13000];
    if ([propsCountButton isKindOfClass:[UIButton class]]) {
        [[(UIButton*)propsCountButton titleLabel] setText:[NSString stringWithFormat:@"%d", self.propsCount]];
    }
    
    UIView *liveMatchLabel = [cell viewWithTag:13001];
    if ([liveMatchLabel isKindOfClass:[UILabel class]]) {
        NSDictionary *gameTeamDict = [self.liveMatchesData objectAtIndex:[indexPath row] - 2];
//        VSGame *game = [gameTeamDict objectForKey:@"game"];
        VSTeam *team = [gameTeamDict objectForKey:@"team"];
        [(UILabel*)liveMatchLabel setText:[NSString stringWithFormat:@"%@ %@ LIVE GAME", [team teamName], [team teamNickname]]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:[self identifierForIndexPath:indexPath]];
    
    return cell.bounds.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([[self identifierForIndexPath:indexPath] isEqualToString:homeNewSwarmCellIdentifier]) {
        [self scheduleSwarmAction];
    } else if ([[self identifierForIndexPath:indexPath] isEqualToString:homeSwarmsCellIdentifier]) {
        [self homeAction];
    } else if ([[self identifierForIndexPath:indexPath] isEqualToString:homeMessagesCellIdentifier]) {
        [self alertsMessagesAction];
    } else if ([[self identifierForIndexPath:indexPath] isEqualToString:homeLiveCellIdentifier]) {
        [self joinLive:[indexPath row] - 2];
    }
}

- (void)updatePropsCount {
    [QBCustomObjects objectsWithClassName:PROPS_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID], @"_parent_id", nil]
                                 delegate:self];
}

#pragma mark - QBDelegate

- (void)completedWithResult:(Result*)result {
    if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]]) {
        if (result.success) {
            QBCOCustomObject* co = nil;
            NSArray *coArr = [(QBCOCustomObjectPagedResult*)result objects];
            if ([coArr count] > 0) {
                co = [coArr objectAtIndex:0];
            }
            if (co) {
                NSMutableDictionary *fields = [co fields];
                if ([fields objectForKey:PROPS_COLUMN_NAME]) {
                    self.propsCount = [[fields objectForKey:PROPS_COLUMN_NAME] integerValue];
                    [self.tableView reloadData];
                }
            }
        }
    }
}

@end
