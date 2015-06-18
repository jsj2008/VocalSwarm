//
//  VSSwarmsModel.m
//  VocalSwarm
//
//  Created by Alexey on 20.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSwarmsModel.h"
#import "VSSwarm.h"
#import "VSTeamSwarm.h"
#import "VSvsSwarm.h"
#import "VSPrivateSwarm.h"
//#import "VSNetworkESPN.h"
#import "VSNetworkChalk.h"
#import "VSGame.h"
#import "VSSettingsModel.h"

typedef void (^VSUsersResultBlock)(NSArray *users);

@interface VSSwarmsModelDelegate : NSObject <QBActionStatusDelegate>

@property (strong, nonatomic) VSSwarmModelResultBlock completeBlock;

- (id) initWithCompletition:(VSSwarmModelResultBlock) result;

@end

@interface VSUsersDelegate : NSObject <QBActionStatusDelegate>

@property (strong, nonatomic) VSUsersResultBlock completeBlock;

- (id) initWithCompletition:(VSUsersResultBlock) result;

@end

@interface VSSwarmsModel()

@property (strong, nonatomic) NSMutableArray *swarmsData;

@end

@implementation VSSwarmsModel

+ (VSSwarmsModel*) sharedInstance
{
    static dispatch_once_t pred;
    static VSSwarmsModel *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[VSSwarmsModel alloc] init];
    });
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    if (self) {
        _swarmsData = [NSMutableArray array];
    }
    return self;
}

//- (void) getSwarmDataWithResult:(VSSwarmModelResultBlock) result {
//    if ([self.swarmsData count] == 0) {
//        [self updateSwarmDataWithResult:result];
//    } else {
//        result([NSArray arrayWithArray:self.swarmsData]);
//    }
//}

- (void) updateSwarmDataWithResult:(VSSwarmModelResultBlock) result {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        //use old games here
        NSArray *oldSwarmsData = [self.swarmsData copy];
        [self.swarmsData removeAllObjects];
        NSMutableArray *swarmsArray = [NSMutableArray array];
        if (swarms) {
            for (QBCOCustomObject *co in swarms) {
                VSSwarm *swarm = [[VSSwarm alloc] initWithCO:co];
                for (VSSwarm *oldSwarm in oldSwarmsData) {
                    if ([swarm matchId] == [oldSwarm matchId]) {
                        [swarm setGame:[oldSwarm game]];
                    }
                }
                if ([swarm game]) {
                    [self.swarmsData addObject:swarm];
                } else {
                    [swarmsArray addObject:swarm];
                }
            }
        }
        [self loadGames:swarmsArray result:^(NSArray *swarms) {
            //remove past swarms
            NSMutableArray *resultArray = [NSMutableArray array];
            for (VSSwarm *swarm in swarms) {
                if (![swarm.game isFinished]) {
                    [resultArray addObject:swarm];
                } else {
                    [self removeSwarm:swarm];
                }
            }
            result([NSArray arrayWithArray:resultArray]);
        }];
    }];
    
    [QBCustomObjects objectsWithClassName:CO_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[VSSettingsModel currentUser].facebookID, @"_parent_id", nil]
                                 delegate:qbDelegate];
}

- (void) loadGames:(NSMutableArray*)swarms result:(VSSwarmModelResultBlock) result {
    if ([swarms count] == 0) {
        [self loadTeamsWithResult:result];
        return;
    }
    
    VSSwarm* swarmToLoad = [swarms lastObject];
    [swarms removeLastObject];
    
    //TODO: look inside for best algorithm
    [[VSNetworkChalk sharedInstance] gameForSportLeague:[VSSportLeague sportLeagueForShortCode:[swarmToLoad sportLeague]]
                                                 gameId:[swarmToLoad matchId]
                                                 result:^(VSGame *game) {
                                                     if (game) {
                                                         [swarmToLoad setGame:game];
                                                         [self.swarmsData addObject:swarmToLoad];
                                                     } else {
                                                         [self removeSwarm:swarmToLoad];
                                                     }
                                                    [self loadGames:swarms result:result];
                                                 }];
}

- (void) loadTeamsWithResult:(VSSwarmModelResultBlock) result {
    NSInteger teamToLoad = 0;
    VSSportLeague *sportLeague = nil;
    for (VSSwarm *swarm in self.swarmsData) {
        if ([swarm.game homeTeam] == nil) {
            teamToLoad = [swarm.game homeTeamId];
            sportLeague = [VSSportLeague sportLeagueForShortCode:swarm.sportLeague];
            break;
        }
        if ([swarm.game awayTeam] == nil) {
            teamToLoad = [swarm.game awayTeamId];
            sportLeague = [VSSportLeague sportLeagueForShortCode:swarm.sportLeague];
            break;
        }
    }
    
    if (teamToLoad == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            result([NSArray arrayWithArray:self.swarmsData]);
        });
        return;
    } else {
        VSTeam *team = [[VSNetworkChalk sharedInstance] prebuildedTeamForSportLeague:sportLeague
                                                                              teamId:teamToLoad];
        for (VSSwarm *swarm in self.swarmsData) {
            if ([swarm.game homeTeamId] == [team teamId]) {
                [swarm.game setHomeTeam:team];
            }
            if ([swarm.game awayTeamId] == [team teamId]) {
                [swarm.game setAwayTeam:team];
            }
        }
        [self loadTeamsWithResult:result];
    }
}

#pragma mark - Swarm creating

- (void) createSwarm:(VSSwarm*) swarm forUser:(NSString *)userId result:(VSSwarmModelSingleResultBlock) result {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            VSSwarm *newSwarm = [[VSSwarm alloc] initWithCO:[swarms objectAtIndex:0]];
            result(newSwarm);
            return;
        } else {
            result(nil);
        }
    }];
    
    QBCOCustomObject *co = [swarm customObject];
    [co setParentID:userId];
    [QBCustomObjects createObject:co
                         delegate:qbDelegate];
}

- (void) findSwarms:(VSSwarm*) swarm forUser:(NSString *)userId result:(VSSwarmModelResultBlock) result {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            NSMutableArray *resultArray = [NSMutableArray array];
            for (QBCOCustomObject *qbCoCustomObject in swarms) {
                [resultArray addObject:[[VSSwarm alloc] initWithCO:qbCoCustomObject]];
            }
            result([NSArray arrayWithArray:resultArray]);
        } else {
            result(nil);
        }
    }];
    
    [QBCustomObjects objectsWithClassName:CO_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [swarm.game gameId]], @"gameId",
                                                                                                                                            userId, @"_parent_id", nil]
                                 delegate:qbDelegate];
}

- (void) removeSwarm:(VSSwarm *) swarm {
    if ([swarm type] == PrivateSwarmType && [swarm isMine]) {
        [self findPrivateSwarm:[NSString stringWithFormat:@"%d", swarm.game.gameId] result:^(VSPrivateSwarm *innerSwarm) {
            if (innerSwarm) {
                [self privateSwarmRemoveProccessFor:swarm participants:[[innerSwarm participants] mutableCopy]];
            } else { //can't actually happens
                [self forceRemoveSwarm:[swarm getSwarmId]];
            }
        }];
    } else {
        [self forceRemoveSwarm:[swarm getSwarmId]];
    }
}

- (void) privateSwarmRemoveProccessFor:(VSSwarm *) swarm participants:(NSMutableArray *) participants {
    if ([participants count] == 0) {
        [self forceRemoveSwarm:[swarm getSwarmId]];
        return;
    }
    NSString *pariticpant = [participants lastObject];
    [participants removeLastObject];
    
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            for (QBCOCustomObject *qbCoCustomObject in swarms) {
                [self forceRemoveSwarm:[qbCoCustomObject ID]];
            }
            [self privateSwarmRemoveProccessFor:swarm participants:participants];
        } else {
            [self privateSwarmRemoveProccessFor:swarm participants:participants];
        }
    }];
    
    [QBCustomObjects objectsWithClassName:CO_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", [swarm.game gameId]], @"gameId",
                                                                              pariticpant, @"_parent_id",
                      [NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID], @"user_id",
                                           [VSSwarm swarmTypeStringFrom:PrivateSwarmType], @"swarmType", nil]
                                 delegate:qbDelegate];
}

- (void) forceRemoveSwarm:(NSString *) swarmId {
    [QBCustomObjects deleteObjectWithID:swarmId
                              className:CO_SWARM_CLASS_NAME
                               delegate:nil];
}

#pragma mark - Team Swarms

- (void) createNewTeamSwarm:(VSSwarm *) game result:(VSSwarmModelTeamResultBlock) resultBlock {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            resultBlock([[VSTeamSwarm alloc] initWithCO:[swarms lastObject]]);
        } else {
            resultBlock(nil);
        }
    }];
    
    VSTeamSwarm* teamSwarm = [[VSTeamSwarm alloc] init];
    [teamSwarm setMatchId:[game.game gameId]];
    [teamSwarm setIsMyTeamHome:[game isMyHomeTeam]];
    
    QBCOCustomObject *co = [teamSwarm customObject];
    [QBCustomObjects createObject:co delegate:qbDelegate];
}

- (void) connectOrCreateToTeamSwarm:(VSSwarm *) game result:(VSSwarmModelTeamResultBlock) resultBlock {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) { //already have one
            VSTeamSwarm *teamSwarm = [[VSTeamSwarm alloc] initWithCO:[swarms objectAtIndex:0]];
            [teamSwarm setIsMyTeamHome:[game isMyHomeTeam]];
            resultBlock(teamSwarm);
        } else { //create new
            [self createNewTeamSwarm:game result:resultBlock];
        }
    }];
    
    [QBCustomObjects objectsWithClassName:CO_TEAM_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [game.game gameId]], @"gameId",
                                           ([game isMyHomeTeam] ? @"true" : @"false"), @"isHomeTeam", nil]
                                 delegate:qbDelegate];
}

#pragma mark - vs Swarms

- (void) createNewvsSwarm:(VSSwarm *)game result:(VSSwarmModelvsResultBlock) resultBlock {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            VSvsSwarm *createdVsSwarm = [[VSvsSwarm alloc] initWithCO:[swarms lastObject]];
            [createdVsSwarm setIsMyTeamHome:[game isMyHomeTeam]];
            resultBlock(createdVsSwarm);
        } else {
            resultBlock(nil);
        }
    }];
    
    VSvsSwarm* vsSwarm = [[VSvsSwarm alloc] init];
    [vsSwarm setMatchId:[game.game gameId]];
    
    QBCOCustomObject *co = [vsSwarm customObject];
    [QBCustomObjects createObject:co delegate:qbDelegate];
}

- (void) connectOrCreateToVsSwarm:(VSSwarm *) game result:(VSSwarmModelvsResultBlock) resultBlock {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) { //already have one
            VSvsSwarm *createdVsSwarm = [[VSvsSwarm alloc] initWithCO:[swarms objectAtIndex:0]];
            [createdVsSwarm setIsMyTeamHome:[game isMyHomeTeam]];
            resultBlock(createdVsSwarm);
        } else { //create new
            [self createNewvsSwarm:game result:resultBlock];
        }
    }];
    
    [QBCustomObjects objectsWithClassName:CO_VS_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [game.game gameId]], @"gameId", nil]
                                 delegate:qbDelegate];
}

#pragma mark - Private Swarms

- (void) findPrivateSwarm:(NSString *)gameId result:(VSSwarmModelPrivateResultBlock) resultBlock {
    VSSwarmsModelDelegate *qbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            resultBlock([[VSPrivateSwarm alloc] initWithCO:[swarms lastObject]]);
        } else {
            resultBlock(nil);
        }
    }];
    
    [QBCustomObjects objectsWithClassName:CO_PRIVATE_SWARM_CLASS_NAME
                          extendedRequest:[NSMutableDictionary dictionaryWithObjectsAndKeys:gameId, @"gameId",
                                                          [VSSettingsModel currentUser].facebookID, @"participants[in]", nil]
                                 delegate:qbDelegate];
}

- (void) createPrivateSwarm:(VSSwarm *)swarmPrototype participants:(NSArray *) participants result:(VSSwarmModelPrivateResultBlock) resultBlock {
    VSUsersDelegate* qbDelegate = [[VSUsersDelegate alloc] initWithCompletition:^(NSArray *users) {
        if (users && [users count] > 0) {
            NSMutableArray *pushParticipants = [NSMutableArray array];
            
            for (QBUUser *user in users) {
                [pushParticipants addObject:[NSString stringWithFormat:@"%d", [user ID]]];
            }
            if ([pushParticipants count]) {
                [self sendPushMessageToSwarm:swarmPrototype participants:pushParticipants];
            }
        }
        
        //creating new private swarm
        VSSwarmsModelDelegate *innerQbDelegate = [[VSSwarmsModelDelegate alloc] initWithCompletition:^(NSArray *innerSwarms) {
            if (innerSwarms && [innerSwarms count] > 0) {
                resultBlock([[VSPrivateSwarm alloc] initWithCO:[innerSwarms lastObject]]);
            } else {
                resultBlock(nil);
            }
        }];
        
        NSMutableArray *finalParticipants = [participants mutableCopy];
        [finalParticipants addObject:[VSSettingsModel currentUser].facebookID];
        VSPrivateSwarm *privateSwarm = [[VSPrivateSwarm alloc] init];
        [privateSwarm setParticipants:finalParticipants];
        [privateSwarm setMatchId:[swarmPrototype matchId]];
        [QBCustomObjects createObject:[privateSwarm customObject] delegate:innerQbDelegate];
    }];
    
    [QBUsers usersWithFacebookIDs:participants delegate:qbDelegate];
}

- (void) sendPushMessageToSwarm:(VSSwarm *)swarm participants:(NSArray *)participants {
    NSString *resultString = @"";
    for (NSString *participant in participants) {
        if ([resultString length]) {
            resultString = [resultString stringByAppendingString:@","];
        }
        resultString = [resultString stringByAppendingString:participant];
    }
    
    NSLog(@"sending pushes to %@", resultString);
    
    [QBMessages TSendPushWithText:[NSString stringWithFormat:@"You are invited to %@", [swarm getFullDescription]] toUsers:resultString delegate:nil];
}

@end

#pragma mark - QB Delegate

@implementation VSSwarmsModelDelegate

- (id) initWithCompletition:(VSSwarmModelResultBlock) result {
    self = [super init];
    if (self) {
        _completeBlock = result;
    }
    return self;
}

-(void)completedWithResult:(Result*)result {
    if ([result isKindOfClass:[QBCOCustomObjectResult class]]) {
        QBCOCustomObjectResult *res = (QBCOCustomObjectResult *)result;
        if (self.completeBlock) {
            if (res.object) {
                self.completeBlock([NSArray arrayWithObject:res.object]);
            } else {
                self.completeBlock(nil);
            }
        }
    } else
    if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]]) {
        QBCOCustomObjectPagedResult *res = (QBCOCustomObjectPagedResult *)result;
        if ([res.objects count] > 0) {
            if (self.completeBlock) {
                self.completeBlock(res.objects);
            }
        } else {
            if (self.completeBlock) {
                self.completeBlock(nil);
            }
        }
    }
}

@end


@implementation VSUsersDelegate

- (id) initWithCompletition:(VSUsersResultBlock) result {
    self = [super init];
    if (self) {
        _completeBlock = result;
    }
    return self;
}

- (void) completedWithResult:(Result *)result {
    if ([result isKindOfClass:[QBUUserResult class]]) {
        QBUUserResult *res = (QBUUserResult *)result;
        if (self.completeBlock) {
            if (res.user) {
                self.completeBlock([NSArray arrayWithObject:res.user]);
            } else {
                self.completeBlock(nil);
            }
        }
    } else
        if ([result isKindOfClass:[QBUUserPagedResult class]]) {
            QBUUserPagedResult *res = (QBUUserPagedResult *)result;
            if ([res.users count] > 0) {
                if (self.completeBlock) {
                    self.completeBlock(res.users);
                }
            } else {
                if (self.completeBlock) {
                    self.completeBlock(nil);
                }
            }
        }
}

@end
