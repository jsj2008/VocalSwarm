//
//  VSSettingsModel.m
//  VocalSwarm
//
//  Created by Alexey on 05.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsModel.h"
#import "VSNetworkESPN.h"
#import "VSNetworkChalk.h"
#import "VSTeam.h"
#import "VSUtils.h"

#define FAVORITE_SPORTS_KEY @"kFAVORITE_SPORTS_KEY"
#define FAVORITE_TEAMS_KEY @"kFAVORITE_TEAMS_KEY"
#define PROPS_REST_KEY @"kPROPS_REST_KEY"
#define PROPS_MAX_COUNT 3

@interface VSSettingsModelDelegate : NSObject <QBActionStatusDelegate>

@property (strong, nonatomic) QBCOResultBlock completeBlock;

- (id) initWithCompletition:(QBCOResultBlock) result;

@end

//TODO make cache in memory

static QBUUser *currentUser = 0;

@implementation VSSettingsModel

#pragma mark - QBUUser

+ (void) setCurrentUser:(QBUUser*)user {
    currentUser = user;
}

+ (QBUUser*) currentUser {
    return currentUser;
}

#pragma mark - Sports

+ (NSArray*) getFavoriteSports {
    NSMutableArray *resultArray = [NSMutableArray array];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* favoriteSportsArray = [userDefaults arrayForKey:FAVORITE_SPORTS_KEY];
    for (NSData *data in favoriteSportsArray) {
        VSSportLeague *sport = (VSSportLeague *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        [resultArray addObject:sport];
    }
    return [NSArray arrayWithArray:resultArray];
}

+ (void) addFavoriteSport:(VSSportLeague*) sport {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* favoriteSportsArray = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:FAVORITE_SPORTS_KEY]];
    BOOL isHave = NO;
    for (NSData* data in favoriteSportsArray) {
        VSSportLeague *csport = (VSSportLeague *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([csport isEqual:sport]) {
            isHave = YES;
            break;
        }
    }
    if (!isHave) {
        NSData *encodedSport = [NSKeyedArchiver archivedDataWithRootObject:sport];
        [favoriteSportsArray addObject:encodedSport];
        [userDefaults setObject:favoriteSportsArray forKey:FAVORITE_SPORTS_KEY];
        [userDefaults synchronize];
    }
}

+ (void) removeFavoriteSport:(VSSportLeague*) sport {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* favoriteSportsArray = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:FAVORITE_SPORTS_KEY]];
    for (int i = 0; i < [favoriteSportsArray count]; i++) {
        NSData* data = [favoriteSportsArray objectAtIndex:i];
        VSSportLeague* csport = (VSSportLeague *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([csport isEqual:sport]) {
            [favoriteSportsArray removeObject:data];
            break;
        }
    }
    
    [userDefaults setObject:favoriteSportsArray forKey:FAVORITE_SPORTS_KEY];
    [userDefaults synchronize];
}

#pragma mark - Teams

+ (NSArray*) getFavoriteTeams {
    NSMutableArray *resultArray = [NSMutableArray array];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* favoriteTeamsArray = [userDefaults arrayForKey:FAVORITE_TEAMS_KEY];
    for (NSData *data in favoriteTeamsArray) {
        VSTeam *team = (VSTeam *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        [resultArray addObject:team];
    }
    return [NSArray arrayWithArray:resultArray];
}

+ (void) addFavoriteTeam:(VSTeam*) team {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* favoriteTeamsArray = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:FAVORITE_TEAMS_KEY]];
    BOOL isHave = NO;
    for (NSData* data in favoriteTeamsArray) {
        VSTeam *cteam = (VSTeam *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([cteam isEqual:team]) {
            isHave = YES;
            break;
        }
    }
    if (!isHave) {
        NSData *encodedTeam = [NSKeyedArchiver archivedDataWithRootObject:team];
        [favoriteTeamsArray addObject:encodedTeam];
        [userDefaults setObject:favoriteTeamsArray forKey:FAVORITE_TEAMS_KEY];
        [userDefaults synchronize];
    }
}

+ (void) removeFavoriteTeam:(VSTeam*) team {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* favoriteTeamsArray = [NSMutableArray arrayWithArray:[userDefaults arrayForKey:FAVORITE_TEAMS_KEY]];
    for (int i = 0; i < [favoriteTeamsArray count]; i++) {
        NSData* data = [favoriteTeamsArray objectAtIndex:i];
        VSTeam* cteam = (VSTeam *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([cteam isEqual:team]) {
            [favoriteTeamsArray removeObject:data];
            break;
        }
    }
    
    [userDefaults setObject:favoriteTeamsArray forKey:FAVORITE_TEAMS_KEY];
    [userDefaults synchronize];
}

#pragma mark - Synchronization

static NSString* favoriteCOClassName = @"Favorite";
static NSString* favoriteCOFieldDataName = @"FavData";

+ (void) synchronizeAlltoServer:(BOOL)ifToServer finished:(QBCOResultBlock) result {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        [VSUtils parseNicknamesFile:@"NCAAF_Team_Ids.txt" toFile:@"teamNicknamesNew.plist"];
//        [[VSNetworkChalk sharedInstance] gamesForSportLeague:[[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:Baseball] league:[[[VSNetworkChalk sharedInstance] leaguesForSport:Baseball] objectAtIndex:0]]
//                                                    gameDate:[NSDate date]
//                                                      result:^(NSArray *games) {
//                                                          NSLog(@"today games %@", games);
//                                                      }];
//        VSSportLeague *sportLeague = [[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:Football] league:[[[VSNetworkChalk sharedInstance] leaguesForSport:Football] objectAtIndex:0]];
//        [[VSNetworkChalk sharedInstance] prebuildedTeamsForSportLeague:sportLeague];
        
        if (ifToServer) {
            [self synchorizeAllToServer:[self currentUser] finished:result];
        } else {
            [self synchorizeAllFromServer:[self currentUser] finished:result];
        }
    });
}

+ (void) synchorizeAllFromServer:(QBUUser*)user finished:(QBCOResultBlock)result {
    VSSettingsModelDelegate *resultDelegate = [[VSSettingsModelDelegate alloc] initWithCompletition:^(QBCOCustomObject *co) {
        if (co) {
            NSArray *favoriteSports = [self getFavoriteSports];
            for (VSSportLeague *sportLeague in favoriteSports) {
                [self removeFavoriteSport:sportLeague];
            }
            
            NSMutableArray *favoriteTeams = [NSMutableArray arrayWithArray:[self getFavoriteTeams]];

            NSMutableArray *needTeamsToLoad = [NSMutableArray array];
            if ([[co fields] objectForKey:favoriteCOFieldDataName] && ![[[co fields] objectForKey:favoriteCOFieldDataName] isKindOfClass:NSNull.class]) {
                for (NSString *favorite in [[co fields] objectForKey:favoriteCOFieldDataName]) {
                    if ([VSSportLeague isSportLeagueShortCode:favorite]) {
                        [self addFavoriteSport:[VSSportLeague sportLeagueForShortCode:favorite]];
                    } else if ([VSTeam isTeamShortCode:favorite]) {
                        BOOL isHave = NO;
                        for (int i = 0; i < [favoriteTeams count]; i++) {
                            VSTeam *team = [favoriteTeams objectAtIndex:i];
                            if ([favorite isEqualToString:[team shortCode]]) {
                                isHave = YES;
                                [favoriteTeams removeObjectAtIndex:i];
                                break;
                            }
                        }
                        if (!isHave) {
                            [needTeamsToLoad addObject:favorite];
                        }
                    }
                }
            }
            
            //remove not used
            for (VSTeam *team in favoriteTeams) {
                [self removeFavoriteTeam:team];
            }
            
            NSLog(@"needTeamsToLoad %@", needTeamsToLoad);
            
            [self loadTeams:needTeamsToLoad co:co result:result];
        } else {
            //remove local
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults removeObjectForKey:FAVORITE_TEAMS_KEY];
            [userDefaults removeObjectForKey:FAVORITE_SPORTS_KEY];
            [userDefaults synchronize];
            dispatch_async(dispatch_get_main_queue(), ^{
                result(nil);
            });
        }
    }];
    
    [QBCustomObjects objectsWithClassName:favoriteCOClassName
                          extendedRequest:[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:user.ID] forKey:@"user_id"]
                                 delegate:resultDelegate];
}

+ (void) loadTeams:(NSMutableArray *) teams co:(QBCOCustomObject*) co result:(QBCOResultBlock)result {
    if ([teams count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            result(co);
        });
        return;
    } else {
        NSString *teamToLoad = [teams lastObject];
        [teams removeLastObject];
        
        VSTeam *team = [[VSNetworkChalk sharedInstance] prebuildedTeamForSportLeague:[[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:[VSTeam sportFromShortCode:teamToLoad]]
                                                                                                    league:[VSTeam leagueAbbrFromShortCode:teamToLoad]]
                                                                              teamId:[VSTeam teamIdFromShortCode:teamToLoad]];
        [self addFavoriteTeam:team];
        
        [self loadTeams:teams co:co result:result];
    }
}

+ (void) synchorizeAllToServer:(QBUUser*)user finished:(QBCOResultBlock)result {
    NSMutableArray *resultArray = [NSMutableArray array];
    for (VSTeam *team in [self getFavoriteTeams]) {
        NSString *teamString = [team shortCode];
        [resultArray addObject:teamString];
    }
    for (VSSportLeague *sport in [self getFavoriteSports]) {
        NSString *sportString = [sport shortCode];
        [resultArray addObject:sportString];
    }
    [user setTags:resultArray];
    
    VSSettingsModelDelegate *resultDelegate = [[VSSettingsModelDelegate alloc] initWithCompletition:^(QBCOCustomObject *co) {
        VSSettingsModelDelegate *subResultDelegate = [[VSSettingsModelDelegate alloc] initWithCompletition:result];
        
        if (co) {
            [co setFields:[NSMutableDictionary dictionaryWithObject:resultArray forKey:favoriteCOFieldDataName]];
            
            [QBCustomObjects updateObject:co delegate:subResultDelegate];
        } else {
            QBCOCustomObject *customObject = [[QBCOCustomObject alloc] init];
            [customObject setClassName:favoriteCOClassName];
            [customObject setFields:[NSMutableDictionary dictionaryWithObject:resultArray forKey:favoriteCOFieldDataName]];
            
            [QBCustomObjects createObject:customObject delegate:subResultDelegate];
        }
    }];
    
    [QBCustomObjects objectsWithClassName:favoriteCOClassName
                          extendedRequest:[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:user.ID] forKey:@"user_id"]
                                 delegate:resultDelegate];
}

+ (NSString*) stringForTeam:(NSDictionary*) teamDict {
    NSLog(@"%@", teamDict);
    NSMutableString *resultString = [NSMutableString stringWithString:@"t"];
    [resultString appendString:[teamDict objectForKey:@"sportName"]];
    if ([teamDict objectForKey:@"id"]) {
        [resultString appendFormat:@"-i%d", [[teamDict objectForKey:@"id"] intValue]];
    } else if ([teamDict objectForKey:@"groupId"]) {
        [resultString appendFormat:@"-g%d", [[teamDict objectForKey:@"groupId"] intValue]];
    } else {
        return @"";
    }
    
    if ([[[teamDict objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"id"]) {
        [resultString appendFormat:@"-i%d", [[[[teamDict objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"id"] intValue]];
    } else if ([[[teamDict objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"groupId"]) {
        [resultString appendFormat:@"-g%d", [[[[teamDict objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"groupId"] intValue]];
    } else {
        return @"";
    }
    
    return resultString;
}

+ (NSInteger) propsRest:(NSString *)swarmId {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* propsRestDict = [userDefaults dictionaryForKey:PROPS_REST_KEY];
    NSLog(@"%@", propsRestDict);
    if (propsRestDict) {
        NSDictionary *propsRestCurrent = [propsRestDict objectForKey:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID]];
        if (propsRestCurrent) {
            NSNumber *propsRestNumber = [propsRestCurrent objectForKey:swarmId];
            if (propsRestNumber) {
                return PROPS_MAX_COUNT - [propsRestNumber integerValue];
            }
        }
    }
    return PROPS_MAX_COUNT;
}

+ (void) propsIncreaseRest:(NSString *)swarmId {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* propsRestDict = [userDefaults dictionaryForKey:PROPS_REST_KEY];
    NSLog(@"%@", propsRestDict);
    if (propsRestDict) {
        NSMutableDictionary *propsRestMutableDict = [NSMutableDictionary dictionaryWithDictionary:propsRestDict];
        NSDictionary *propsRestCurrent = [propsRestDict objectForKey:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID]];
        if (propsRestCurrent) {
            NSMutableDictionary *propsRestCurrentMutable = [NSMutableDictionary dictionaryWithDictionary:propsRestCurrent];
            NSNumber *propsRestNumber = [propsRestCurrent objectForKey:swarmId];
            if (propsRestNumber) {
                NSInteger count = [propsRestNumber integerValue];
                count++;
                [propsRestCurrentMutable setObject:[NSNumber numberWithInteger:count] forKey:swarmId];
            } else {
                [propsRestCurrentMutable setObject:[NSNumber numberWithInteger:1] forKey:swarmId];
            }
            [propsRestMutableDict setObject:propsRestCurrentMutable forKey:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID]];
            [userDefaults setObject:propsRestMutableDict forKey:PROPS_REST_KEY];
        } else {
            NSDictionary *propsRestCurrent = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:1] forKey:swarmId];
            [propsRestMutableDict setObject:propsRestCurrent forKey:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID]];
            [userDefaults setObject:propsRestMutableDict forKey:PROPS_REST_KEY];
        }
    } else {
        NSDictionary *propsRestCurrent = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:1] forKey:swarmId];
        NSDictionary *propsRestDict = [NSDictionary dictionaryWithObject:propsRestCurrent forKey:[NSString stringWithFormat:@"%d", [VSSettingsModel currentUser].ID]];
        [userDefaults setObject:propsRestDict forKey:PROPS_REST_KEY];
    }
    
    [userDefaults synchronize];
}

@end

@implementation VSSettingsModelDelegate

- (id) initWithCompletition:(QBCOResultBlock) result {
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
            self.completeBlock(res.object);
        }
    } else if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]]) {
        QBCOCustomObjectPagedResult *res = (QBCOCustomObjectPagedResult *)result;
        if ([res.objects count] > 0) {
            if (self.completeBlock) {
                self.completeBlock([res.objects objectAtIndex:0]);
            }
        } else {
            if (self.completeBlock) {
                self.completeBlock(nil);
            }
        }
    }
}

@end
