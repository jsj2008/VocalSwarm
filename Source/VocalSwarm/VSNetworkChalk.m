//
//  VSNetworkChalk.m
//  VocalSwarm
//
//  Created by Alexey on 05.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSNetworkChalk.h"

#import "VSTeam.h"
#import "VSSportLeague.h"
#import "VSGame.h"
#import "VSHeadline.h"

#import "VSUtils.h"

#import "TBXML.h"
#import "TBXML+HTTP.h"

@interface VSNetworkChalk ()

@property (strong, nonatomic) NSString *cacheDirectory;

@end

#define CHALK_USERNAME @"Mautnhc76D"
#define CHALK_PASSWORD @"kfj3Hufr6sD"

#define CHALK_TEAMLIST_REQUEST_STRING [NSString stringWithFormat:@"http://services.chalkgaming.com/ChalkServices.asmx/TeamList?Username=%@&Password=%@&Sport=%%@&League=%%@", CHALK_USERNAME, CHALK_PASSWORD]

#define CHALK_TEAM_REPORT_REQUEST_STRING [NSString stringWithFormat:@"http://services.chalkgaming.com/ChalkServices.asmx/TeamReport?Username=%@&Password=%@&Sport=%%@&League=%%@&TeamId=%%d", CHALK_USERNAME, CHALK_PASSWORD]

#define CHALK_SCHEDULE_REQUEST_STRING [NSString stringWithFormat:@"http://services.chalkgaming.com/ChalkServices.asmx/Schedule?Username=%@&Password=%@&Sport=%%@&League=%%@&aMonth=%%@", CHALK_USERNAME, CHALK_PASSWORD]

#define CHALK_RECAP_REQUEST_STRING [NSString stringWithFormat:@"http://services.chalkgaming.com/ChalkServices.asmx/Recap?Username=%@&Password=%@&Sport=%%@&League=%%@&GameId=%%d", CHALK_USERNAME, CHALK_PASSWORD]

#define CHALK_SCOREBOARD_REQUEST_STRING [NSString stringWithFormat:@"http://services.chalkgaming.com/ChalkServices.asmx/Scoreboard?Username=%@&Password=%@&Sport=%%@&League=%%@&StartDate=%%@&EndDate=%%@", CHALK_USERNAME, CHALK_PASSWORD]

#define RECAP_CACHE_FILENAME @"recapCache.%@.%@.%d.xml"
#define TEAMS_CACHE_FILENAME @"teamsCache.%@.%@.xml"
#define TEAMS_PREBUILDED_FILENAME @"teamNicknames.%@.%@.plist"
#define SCHEDULE_CACHE_FILENAME @"scheduleCache.%@.%@.%@.xml"
#define SCHEDULE_CACHE_UPDATE_TIME 3600 //1 hour minutes (1 * 60 * 60)
#define SCOREBOARD_CACHE_FILENAME @"scoreboardCache.%@.%@.%@.%@.xml"
#define SCOREBOARD_CACGE_UPDATE_TIME 300 //5 minures (5 * 60)

@implementation VSNetworkChalk

+ (VSNetworkChalk*) sharedInstance {
    static dispatch_once_t pred;
    static VSNetworkChalk *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[VSNetworkChalk alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    self = [super init];
    if (self) {
        self.cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    return self;
}

- (NSArray *) leaguesForSport:(enum ChalkSports) sport
{
    switch (sport)
    {
        case Football:
            return [NSArray arrayWithObjects:/*@"AFL",*/ @"CFL", @"NCAAF", @"NFL", nil];
            break;
        case Basketball:
            return [NSArray arrayWithObjects:@"NBA", @"NCAAB", @"WNBA", nil];
            break;
        case Baseball:
            return [NSArray arrayWithObjects:@"MLB", nil];
            break;
        case Hockey:
            return [NSArray arrayWithObjects:@"NHL", nil];
            break;
        case UndefinedSport:
            break;
    }
    return nil;
}

#pragma mark - teams

- (void)parseTeamReportXml:(TBXML *)tbxml team:(VSTeam *)team
{
    if (tbxml && [tbxml rootXMLElement]) {
        TBXMLElement* rootElement = [tbxml rootXMLElement];
        if ([[TBXML elementName:rootElement] isEqualToString:@"ChalkResult"]) {
            TBXMLElement* resultSetElement = [TBXML childElementNamed:@"ResultSet" parentElement:rootElement];
            if (resultSetElement) {
                TBXMLElement* teamReportElement = [TBXML childElementNamed:@"TeamReport" parentElement:resultSetElement];
                if (teamReportElement) {
                    [team updateData:(__bridge id)teamReportElement];
                }
            }
        }
    }
}

- (NSArray *) prebuildedTeamsForSportLeague:(VSSportLeague *)sportLeague
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *fileName = [NSString stringWithFormat:TEAMS_PREBUILDED_FILENAME, [[sportLeague sportName] lowercaseString], [[sportLeague leagueAbbr] lowercaseString]];
    NSString *fileString = [[NSBundle mainBundle] pathForResource:fileName ofType:@""];
    for (NSDictionary *teamDict in [[NSArray alloc] initWithContentsOfFile:fileString]) {
        VSTeam *team = [[VSTeam alloc] initWithSportLeague:sportLeague];
        [team setTeamId:[[teamDict objectForKey:@"teamId"] integerValue]];
        [team setTeamName:[teamDict objectForKey:@"teamName"]];
        [team setTeamNickname:[teamDict objectForKey:@"teamNickname"]];
        [result addObject:team];
    }
    return result;
}

- (VSTeam *) prebuildedTeamForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId
{
    for (VSTeam* team in [self prebuildedTeamsForSportLeague:sportLeague]) {
        if ([team teamId] == teamId) {
            return team;
        }
    }
    return nil;
}

- (void) proccessTeamReports:(NSMutableArray *)teamsList result:(void (^)())result
{
    if ([teamsList count] == 0) {
        result();
        return;
    }

    //TODO mb add cache here !!!
    VSTeam *team = [teamsList lastObject];
    [teamsList removeLastObject];
    NSLog(@"proccessTeamNickNames for team %@", team);
    NSString *urlString = [NSString stringWithFormat:CHALK_TEAM_REPORT_REQUEST_STRING, [team.sportLeague sportName], [team.sportLeague leagueAbbr], [team teamId]];
    
    [NSURLConnection tbxmlAsyncRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
                               success:^(NSData *data, NSURLResponse *response) {
                                   NSError* error = nil;
                                   TBXML* tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
                                   [self parseTeamReportXml:tbxml team:team];
                                   NSLog(@"team report proccess success");
                                   [self proccessTeamReports:teamsList result:result];
                               }
                               failure:^(NSData *data, NSError *error) {
                                   NSLog(@"team report proccess failure");
                                   [self proccessTeamReports:teamsList result:result];
                               }];
}

#pragma mark - not used

- (NSArray *)parseTeamsXml:(TBXML *)tbxml sportLeague:(VSSportLeague *)sportLeague
{
    NSMutableArray *resultArray = [NSMutableArray array];
    if (tbxml && [tbxml rootXMLElement]) {
        TBXMLElement* rootElement = [tbxml rootXMLElement];
        if ([[TBXML elementName:rootElement] isEqualToString:@"ChalkResult"]) {
            TBXMLElement* resultSetElement = [TBXML childElementNamed:@"ResultSet" parentElement:rootElement];
            if (resultSetElement) {
                TBXMLElement* teamsElement = [TBXML childElementNamed:@"Teams" parentElement:resultSetElement];
                if (teamsElement) {
                    TBXMLElement* teamElement = [TBXML childElementNamed:@"Team" parentElement:teamsElement];
                    while (teamElement) {
                        VSTeam *team = [[VSTeam alloc] initWithSportLeague:sportLeague];
                        [team updateData:(__bridge id)(teamElement)];
                        [resultArray addObject:team];
                        teamElement = [TBXML nextSiblingNamed:@"Team" searchFromElement:teamElement];
                    }
                }
            }
        }
    }
    return [NSArray arrayWithArray:resultArray];
}

- (void) teamsRequestForSportLeague:(VSSportLeague*) sportLeague result:(void (^)(NSArray *teamArray))result
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:TEAMS_CACHE_FILENAME, [sportLeague sportName], [sportLeague leagueAbbr]]];
    if([fileManager fileExistsAtPath:cachePath]) {
        NSError* error = nil;
        TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
        result([self parseTeamsXml:tbxml sportLeague:sportLeague]);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:CHALK_TEAMLIST_REQUEST_STRING, [sportLeague sportName], [sportLeague leagueAbbr]];
    
    [NSURLConnection tbxmlAsyncRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
                               success:^(NSData *data, NSURLResponse *response) {
                                   [data writeToFile:cachePath atomically:YES];
                                   NSError* error = nil;
                                   TBXML* tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
                                   result([self parseTeamsXml:tbxml sportLeague:sportLeague]);
                               }
                               failure:^(NSData *data, NSError *error) {
                                   result(nil);
                               }];
}

- (void) teamsRequestForSport:(enum ChalkSports) sport league:(NSString *) league result:(void (^)(NSArray *teamArray))result
{
    [self teamsRequestForSportLeague:[[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:sport] league:league] result:result];
}

- (VSTeam *) teamFromCacheForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:TEAMS_CACHE_FILENAME, [sportLeague sportName], [sportLeague leagueAbbr]]];
    if([fileManager fileExistsAtPath:cachePath]) {
        NSError* error = nil;
        TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
        for (VSTeam *team in [self parseTeamsXml:tbxml sportLeague:sportLeague]) {
            if ([team teamId] == teamId) {
                return team;
            }
        }
    }
    return nil;
}

- (void) teamForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId reesult:(void (^)(VSTeam *team))result
{
    [self teamsRequestForSportLeague:sportLeague result:^(NSArray *teamArray) {
        for (VSTeam *inTeam in teamArray) {
            if ([inTeam teamId] == teamId) {
                result(inTeam);
                return;
            }
        }
    }];
}

#pragma mark - headlines

- (void) headlinesForTeams:(NSArray *)teams result:(void (^)())result
{
    [self proccessTeamReports:[NSMutableArray arrayWithArray:teams] result:^{
        [self proccessHeadLinesTeams:[NSMutableArray arrayWithArray:teams] result:result];
    }];
}

- (void) proccessHeadLinesTeams:(NSMutableArray *) teams result:(void (^)())result
{
    if ([teams count] == 0) {
        result();
        return;
    }
    
    VSTeam *team = [teams lastObject];
    [teams removeLastObject];
    
    [self proccessHeadLines:[NSMutableArray arrayWithArray:[team headlines]] sportLeague:[team sportLeague] result:^{
        [self proccessHeadLinesTeams:teams result:result];
    }];
}

- (void) proccessHeadLines:(NSMutableArray *) headlines sportLeague:(VSSportLeague *)sportLeague result:(void (^)())result
{
    if ([headlines count] == 0) {
        result();
        return;
    }
    
    VSHeadline* headline = [headlines lastObject];
    [headlines removeLastObject];

    if ([[headline headlineType] isEqualToString:@"Recap"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:RECAP_CACHE_FILENAME, [sportLeague sportName], [sportLeague leagueAbbr], [headline gameId]]];
        if([fileManager fileExistsAtPath:cachePath]) {
            NSError* error = nil;
            TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
            [self parseRecapXml:tbxml headline:headline];
            [self proccessHeadLines:headlines sportLeague:sportLeague result:result];
            return;
        }
        
        NSString *urlString = [NSString stringWithFormat:CHALK_RECAP_REQUEST_STRING, [sportLeague sportName], [sportLeague leagueAbbr], [headline gameId]];
        
        [NSURLConnection tbxmlAsyncRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
                                   success:^(NSData *data, NSURLResponse *response) {
                                       [data writeToFile:cachePath atomically:YES];
                                       NSError* error = nil;
                                       TBXML* tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
                                       [self parseRecapXml:tbxml headline:headline];
                                       NSLog(@"recap proccess success");
                                       [self proccessHeadLines:headlines sportLeague:sportLeague result:result];
                                   }
                                   failure:^(NSData *data, NSError *error) {
                                       NSLog(@"recap proccess failure");
                                       [self proccessHeadLines:headlines sportLeague:sportLeague result:result];
                                   }];
    } else {
        [self proccessHeadLines:headlines sportLeague:sportLeague result:result];
    }
}

- (void) parseRecapXml:(TBXML *)tbxml headline:(VSHeadline *)headline
{
    if (tbxml && [tbxml rootXMLElement]) {
        TBXMLElement* rootElement = [tbxml rootXMLElement];
        if ([[TBXML elementName:rootElement] isEqualToString:@"ChalkResult"]) {
            TBXMLElement* resultSetElement = [TBXML childElementNamed:@"ResultSet" parentElement:rootElement];
            if (resultSetElement) {
                TBXMLElement* recapElement = [TBXML childElementNamed:@"Recap" parentElement:resultSetElement];
                if (recapElement) {
                    [headline updateData:(__bridge id)(recapElement)];
                }
            }
        }
    }
}

#pragma mark - schedule

- (NSArray *) parseScheduleXml:(TBXML *)tbxml
{
    NSMutableArray *resultArray = [NSMutableArray array];
    if (tbxml && [tbxml rootXMLElement]) {
        TBXMLElement* rootElement = [tbxml rootXMLElement];
        if ([[TBXML elementName:rootElement] isEqualToString:@"ChalkResult"]) {
            TBXMLElement* resultSetElement = [TBXML childElementNamed:@"ResultSet" parentElement:rootElement];
            if (resultSetElement) {
                TBXMLElement* scheduleElement = [TBXML childElementNamed:@"Schedule" parentElement:resultSetElement];
                if (scheduleElement) {
                    TBXMLElement* gameElement = [TBXML childElementNamed:@"Game" parentElement:scheduleElement];
                    while (gameElement) {
                        VSGame *game = [[VSGame alloc] init];
                        [game updateData:(__bridge id)(gameElement)];
                        [resultArray addObject:game];
                        gameElement = [TBXML nextSiblingNamed:@"Game" searchFromElement:gameElement];
                    }
                }
            }
        }
    }
    return [NSArray arrayWithArray:resultArray];
}

- (NSArray *) parseScoreboardXml:(TBXML *)tbxml
{
    NSMutableArray *resultArray = [NSMutableArray array];
    if (tbxml && [tbxml rootXMLElement]) {
        TBXMLElement* rootElement = [tbxml rootXMLElement];
        if ([[TBXML elementName:rootElement] isEqualToString:@"ChalkResult"]) {
            TBXMLElement* resultSetElement = [TBXML childElementNamed:@"ResultSet" parentElement:rootElement];
            if (resultSetElement) {
                TBXMLElement* scheduleElement = [TBXML childElementNamed:@"Scoreboard" parentElement:resultSetElement];
                if (scheduleElement) {
                    TBXMLElement* gameElement = [TBXML childElementNamed:@"Game" parentElement:scheduleElement];
                    while (gameElement) {
                        VSGame *game = [[VSGame alloc] init];
                        [game updateData:(__bridge id)(gameElement)];
                        [resultArray addObject:game];
                        gameElement = [TBXML nextSiblingNamed:@"Game" searchFromElement:gameElement];
                    }
                }
            }
        }
    }
    return [NSArray arrayWithArray:resultArray];
}

- (void) scheduleRequestForSport:(enum ChalkSports) sport league:(NSString *) league month:(NSString *)month result:(void (^)(NSArray *gamesArray))result
{
    [self scheduleRequestForSportLeague:[[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:sport] league:league]
                                  month:month
                                 result:result];
}

- (void) scheduleRequestForSportLeague:(VSSportLeague *) sportLeague month:(NSString *)month result:(void (^)(NSArray *gamesArray))result
{
    static bool isInProgress = NO;
    
    if (!isInProgress)
    {
        isInProgress = YES;
        [self scheduleSubRequestForSportLeague:sportLeague month:month result:^(NSArray *gamesArray) {
            //replace current day matches with extended info
            if ([month isEqualToString:[VSUtils currentMonth]]) {
                //TODO change date to EST date
                [self gamesForSportLeague:sportLeague gameDate:[NSDate date] result:^(NSArray *games) {
                    NSMutableArray *finalArray = [NSMutableArray arrayWithArray:gamesArray];
                    for (VSGame *inGame in games) {
                        for (int i = 0; i < [gamesArray count]; i++) {
                            VSGame *game = [gamesArray objectAtIndex:i];
                            if ([inGame isEqual:game]) {
                                [finalArray replaceObjectAtIndex:i withObject:inGame];
                                break;
                            }
                        }
                    }
                    result (finalArray);
                    isInProgress = NO;
                }];
            } else {
                result(gamesArray);
                isInProgress = NO;
            }
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(scheduleRequestRetry:)
                       withObject:@[sportLeague, month, result]
                       afterDelay:1];
        });
    }
}

- (void) scheduleRequestRetry:(NSArray *)arr
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        VSSportLeague *sportLeague = [arr objectAtIndex:0];
        NSString *month = [arr objectAtIndex:1];
        arrayBlock block = [arr objectAtIndex:2];
        [self scheduleRequestForSportLeague:sportLeague
                                      month:month
                                     result:block];
    });
}

- (void) scheduleSubRequestForSportLeague:(VSSportLeague *) sportLeague month:(NSString *)month result:(void (^)(NSArray *gamesArray))result
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:SCHEDULE_CACHE_FILENAME, [sportLeague sportName], [sportLeague leagueAbbr], month]];
    if([fileManager fileExistsAtPath:cachePath]) {
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:cachePath error:nil];
        NSDate *date = [attributes fileModificationDate];
        
        NSInteger calendarComponents = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:calendarComponents fromDate:[NSDate date]];
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:calendarComponents fromDate:date];
        NSDate *otherDate = [cal dateFromComponents:components];
        
        if ([today isEqualToDate:otherDate]) {
            NSError* error = nil;
            TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
            result([self parseScheduleXml:tbxml]);
            return;
        }
    }
    
    NSString *urlString = [NSString stringWithFormat:CHALK_SCHEDULE_REQUEST_STRING, [sportLeague sportName], [sportLeague leagueAbbr], month];
    
    [NSURLConnection tbxmlAsyncRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
                               success:^(NSData *data, NSURLResponse *response) {
                                   [data writeToFile:cachePath atomically:YES];
                                   NSError* error = nil;
                                   TBXML* tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
                                   result([self parseScheduleXml:tbxml]);
                               }
                               failure:^(NSData *data, NSError *error) {
                                   result(nil);
                               }];
}

- (void) scoreRequestForTeam:(VSTeam *) team result:(void (^)(NSArray *scoresArray))result
{
    NSMutableArray *resultArr = [NSMutableArray array];
    [self scheduleRequestForSportLeague:team.sportLeague
                                  month:[VSUtils currentMonth]
                                 result:^(NSArray *gamesArray) {
                                     for (int i = [gamesArray count] - 1; i >= 0; --i) {
                                         VSGame *game = [gamesArray objectAtIndex:i];
                                         if ([game homeTeamId] == team.teamId || [game awayTeamId] == team.teamId) {
                                             NSLog(@"%@", [game gameDate]);
                                             NSLog(@"%@", [[NSDate alloc] init]);
                                             NSLog(@"%f", [[game gameDate] timeIntervalSinceNow]);
                                             NSTimeInterval ti = [[game gameDate] timeIntervalSinceNow];
                                             if (ti < 0) {
                                                 [resultArr insertObject:game atIndex:0];
//                                                 if ([resultArr count] == 4) {
//                                                     break;
//                                                 }
                                             }
                                         }
                                     }
                                     
//                                     if ([resultArr count] < 4) {
                                         [self scheduleRequestForSportLeague:team.sportLeague
                                                                       month:[VSUtils prevMonth]
                                                                      result:^(NSArray *gamesArray) {
                                                                          for (int i = [gamesArray count] - 1; i >= 0; --i) {
                                                                              VSGame *game = [gamesArray objectAtIndex:i];
                                                                              if ([game homeTeamId] == team.teamId || [game awayTeamId] == team.teamId) {
                                                                                  [resultArr insertObject:game atIndex:0];
//                                                                                  if ([resultArr count] == 4) {
//                                                                                      break;
//                                                                                  }
                                                                              }
                                                                          }
                                                                          
                                                                          [self proccessTeamsForGames:resultArr
                                                                                          sportLeague:[team sportLeague]
                                                                                               result:result];
                                                                      }];
//                                     } else {
//                                         [self proccessTeamsForGames:resultArr
//                                                         sportLeague:[team sportLeague]
//                                                              result:result];
//                                     }[
                                 }];
}

- (void) upcomingGamesForTeam:(VSTeam *) team result:(void (^)(NSArray *scoresArray))result {
    NSMutableArray *resultArr = [NSMutableArray array];
    [self scheduleRequestForSportLeague:team.sportLeague
                                  month:[VSUtils currentMonth]
                                 result:^(NSArray *gamesArray) {
                                     for (int i = 0; i < [gamesArray count]; ++i) {
                                         VSGame *game = [gamesArray objectAtIndex:i];
                                         if ([game homeTeamId] == team.teamId || [game awayTeamId] == team.teamId) {
                                             NSLog(@"%@", [game gameDate]);
                                             NSLog(@"%@", [[NSDate alloc] init]);
                                             NSLog(@"%f", [[game gameDate] timeIntervalSinceNow]);
                                             NSTimeInterval ti = [[game gameDate] timeIntervalSinceNow];
                                             if (ti > 0) {
                                                 [resultArr addObject:game];
//                                                 if ([resultArr count] == 4) {
//                                                     break;
//                                                 }
                                             }
                                         }
                                     }
                                     
//                                     if ([resultArr count] < 4) {
                                         [self scheduleRequestForSportLeague:team.sportLeague
                                                                       month:[VSUtils nextMonth]
                                                                      result:^(NSArray *gamesArray) {
                                                                          for (int i = 0; i < [gamesArray count]; ++i) {
                                                                              VSGame *game = [gamesArray objectAtIndex:i];
                                                                              if ([game homeTeamId] == team.teamId || [game awayTeamId] == team.teamId) {
                                                                                  [resultArr addObject:game];
//                                                                                  if ([resultArr count] == 4) {
//                                                                                      break;
//                                                                                  }
                                                                              }
                                                                          }
                                                                          
                                                                          [self proccessTeamsForGames:resultArr
                                                                                          sportLeague:[team sportLeague]
                                                                                               result:result];
                                                                      }];
//                                     } else {
//                                         [self proccessScoreRequestArray:resultArr team:team result:result];
//                                     }
                                 }];
}

- (void) proccessScoreRequestArray:(NSMutableArray *)scoresArray team:(VSTeam *) team result:(void (^)(NSArray *scoresArray))result
{
    NSLog(@"before proccessScoreRequestArray %@", scoresArray);
    for (VSGame* game in scoresArray) {
        if ([game homeTeamId] == [team teamId]) {
            [game setHomeTeam:team];
            [game setAwayTeam:[self prebuildedTeamForSportLeague:[team sportLeague] teamId:[game awayTeamId]]];
        }
        if ([game awayTeamId] == [team teamId]) {
            [game setAwayTeam:team];
            [game setHomeTeam:[self prebuildedTeamForSportLeague:[team sportLeague] teamId:[game homeTeamId]]];
        }
    }
    NSLog(@"after proccessScoreRequestArray %@", scoresArray);
    result(scoresArray);
}

- (void) proccessTeamsForGames:(NSMutableArray *)gamesArray sportLeague:(VSSportLeague *)sportLeague result:(void (^)(NSArray *scoresArray))result
{
    for (VSGame *game in gamesArray) {
        if (![game homeTeam]) {
            [game setHomeTeam:[self prebuildedTeamForSportLeague:sportLeague teamId:[game homeTeamId]]];
        }
        if (![game awayTeam]) {
            [game setAwayTeam:[self prebuildedTeamForSportLeague:sportLeague teamId:[game awayTeamId]]];
        }
    }
    result(gamesArray);
}

- (void) lastWeekMatchesForSportLeague:(VSSportLeague *) sportLeague result:(void (^)(NSArray *games)) result
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
    NSString *startDate = [df stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970] - 604800]]; //1 week = 60 * 60 * 24 * 7
    NSString *endDate = [df stringFromDate:[NSDate date]];
    [self gamesForSportLeague:sportLeague startGameDateString:startDate endGameDateString:endDate result:^(NSArray *games) {
        NSMutableArray *resultArr = [NSMutableArray array];
        for (VSGame *game in games) {
            NSLog(@"%@", [game gameDate]);
            NSLog(@"%@", [NSDate date]);
            NSLog(@"%f", [[game gameDate] timeIntervalSinceNow]);
            NSTimeInterval ti = [[game gameDate] timeIntervalSinceNow];
            if (ti < 0) {
                [resultArr addObject:game];
            }
        }

        [self proccessTeamsForGames:resultArr sportLeague:sportLeague result:result];
    }];
}

- (void) liveMatchesForSportLeague:(VSSportLeague *) sportLeague result:(void (^)(NSArray *games)) result
{
    [self gamesForSportLeague:sportLeague
                     gameDate:[NSDate date]
                       result:^(NSArray *games) {
                           NSMutableArray *liveMatches = [NSMutableArray array];
                           for (VSGame *game in games) {
                               if ([game isLive]) {
                                   [liveMatches addObject:game];
                               }
                           }
                           [self proccessTeamsForGames:liveMatches
                                           sportLeague:sportLeague
                                                result:result];
                       }];
}

- (void) gameForSportLeague:(VSSportLeague *) sportLeague gameId:(NSUInteger)gameId result:(void (^)(VSGame *game))result
{
    [self scheduleRequestForSportLeague:sportLeague
                                  month:[VSUtils currentMonth]
                                 result:^(NSArray *gamesArray) {
                                     for (VSGame *game in gamesArray) {
                                         if ([game gameId] == gameId) {
                                             result(game);
                                             return;
                                         }
                                     }
                                     
                                     [self scheduleRequestForSportLeague:sportLeague
                                                                   month:[VSUtils nextMonth]
                                                                  result:^(NSArray *gamesArray) {
                                                                      for (VSGame *game in gamesArray) {
                                                                          if ([game gameId] == gameId) {
                                                                              result(game);
                                                                              return;
                                                                          }
                                                                      }
                                                                      
                                                                      [self scheduleRequestForSportLeague:sportLeague
                                                                                                    month:[VSUtils prevMonth]
                                                                                                   result:^(NSArray *gamesArray) {
                                                                                                       for (VSGame *game in gamesArray) {
                                                                                                           if ([game gameId] == gameId) {
                                                                                                               result(game);
                                                                                                               return;
                                                                                                           }
                                                                                                       }
                                                                                                       result(nil);
                                                                                                   }];
                                                                  }];
                                 }];
}

- (void) gamesForSportLeague:(VSSportLeague *) sportLeague startGameDateString:(NSString *)startDate endGameDateString:(NSString *)endDate result:(void (^)(NSArray *games)) result
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:SCOREBOARD_CACHE_FILENAME, [sportLeague sportName], [sportLeague leagueAbbr], [startDate stringByReplacingOccurrencesOfString:@"/" withString:@"."], [endDate stringByReplacingOccurrencesOfString:@"/" withString:@"."]]];
    if([fileManager fileExistsAtPath:cachePath]) {
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:cachePath error:nil];
        NSDate *date = [attributes fileModificationDate];
        
        NSInteger calendarComponents = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:calendarComponents fromDate:[NSDate date]];
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:calendarComponents fromDate:date];
        NSDate *otherDate = [cal dateFromComponents:components];
        
        NSTimeInterval lastUpdate = [date timeIntervalSinceNow];
        
        NSComparisonResult compres = [today compare:otherDate];
        
        if (compres == NSOrderedSame && lastUpdate < -SCOREBOARD_CACGE_UPDATE_TIME && ![startDate isEqualToString:endDate]) {
            NSError* error = nil;
            TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
            [self gamesForSportLeague:sportLeague
                             gameDate:[NSDate date]
                               result:^(NSArray *games) {
                                   NSMutableArray *finalArray = [NSMutableArray arrayWithArray:[self parseScoreboardXml:tbxml]];
                                   for (VSGame *inGame in games) {
                                       for (int i = 0; i < [finalArray count]; i++) {
                                           VSGame *game = [finalArray objectAtIndex:i];
                                           if ([inGame isEqual:game]) {
                                               [finalArray replaceObjectAtIndex:i withObject:inGame];
                                               break;
                                           }
                                       }
                                   }
                                   result (finalArray);
                               }];
            return;
        }
        
        if(compres == NSOrderedDescending || lastUpdate > -SCOREBOARD_CACGE_UPDATE_TIME) {
            NSError* error = nil;
            TBXML* tbxml = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:cachePath] error:&error];
            result([self parseScoreboardXml:tbxml]);
            return;
        }
    }
    
    NSString *urlString = [NSString stringWithFormat:CHALK_SCOREBOARD_REQUEST_STRING, [sportLeague sportName], [sportLeague leagueAbbr], startDate, endDate];
    
    [NSURLConnection tbxmlAsyncRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
                               success:^(NSData *data, NSURLResponse *response) {
                                   [data writeToFile:cachePath atomically:YES];
                                   NSError* error = nil;
                                   TBXML* tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
                                   result([self parseScoreboardXml:tbxml]);
                               }
                               failure:^(NSData *data, NSError *error) {
                                   result(nil);
                               }];
}

- (void) gamesForSportLeague:(VSSportLeague *) sportLeague gameDateString:(NSString *)gameDateString result:(void (^)(NSArray *games)) result
{
    [self gamesForSportLeague:sportLeague startGameDateString:gameDateString endGameDateString:gameDateString result:result];
}

- (void) gamesForSportLeague:(VSSportLeague *) sportLeague gameDate:(NSDate *)gameDate result:(void (^)(NSArray *games)) result {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
    [self gamesForSportLeague:sportLeague gameDateString:[df stringFromDate:gameDate] result:result];
}

+ (NSString *) sportName:(enum ChalkSports) sport
{
    switch (sport)
    {
        case Football:
            return @"Football";
            break;
        case Basketball:
            return @"Basketball";
            break;
        case Baseball:
            return @"Baseball";
            break;
        case Hockey:
            return @"Hockey";
            break;
        case UndefinedSport:
            break;
    }
    return @"";
}

+ (enum ChalkSports) sport:(NSString *) sportName
{
    if ([[sportName lowercaseString] isEqualToString:@"football"]) {
        return Football;
    } else if ([[sportName lowercaseString] isEqualToString:@"baseball"]) {
        return Baseball;
    } else if ([[sportName lowercaseString] isEqualToString:@"basketball"]) {
        return Basketball;
    } else if ([[sportName lowercaseString] isEqualToString:@"hockey"]) {
        return Hockey;
    }
    
    return UndefinedSport;
}

@end
