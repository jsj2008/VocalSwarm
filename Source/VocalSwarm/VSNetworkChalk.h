//
//  VSNetworkChalk.h
//  VocalSwarm
//
//  Created by Alexey on 05.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^arrayBlock)(NSArray *gamesArray);

@class VSGame;
@class VSTeam;
@class VSSportLeague;

enum ChalkSports {
    Football = 0,
    Basketball = 1,
    Baseball = 2,
    Hockey = 3,
    UndefinedSport = 255
};

@interface VSNetworkChalk : NSObject

+ (VSNetworkChalk*) sharedInstance;

+ (enum ChalkSports) sport:(NSString *) sportName;
+ (NSString *) sportName:(enum ChalkSports) sport;

- (NSArray *) leaguesForSport:(enum ChalkSports) sport;

- (void) headlinesForTeams:(NSArray *)teams result:(void (^)())result;

//- (void) teamsRequestForSport:(enum ChalkSports) sport league:(NSString *) league result:(void (^)(NSArray *teamArray))result;
//- (void) teamsRequestForSportLeague:(VSSportLeague*) sportLeague result:(void (^)(NSArray *teamArray))result;
//- (void) teamForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId reesult:(void (^)(VSTeam *team))result;
//- (VSTeam *) teamFromCacheForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId;

- (NSArray *) prebuildedTeamsForSportLeague:(VSSportLeague *)sportLeague;
- (VSTeam *) prebuildedTeamForSportLeague:(VSSportLeague *)sportLeague teamId:(NSInteger)teamId;

- (void) scheduleRequestForSport:(enum ChalkSports) sport league:(NSString *) league month:(NSString *)month result:(void (^)(NSArray *gamesArray))result;
- (void) scheduleRequestForSportLeague:(VSSportLeague *) sportLeague month:(NSString *)month result:(void (^)(NSArray *gamesArray))result;

- (void) scoreRequestForTeam:(VSTeam *) team result:(void (^)(NSArray *scoresArray))result;
- (void) upcomingGamesForTeam:(VSTeam *) team result:(void (^)(NSArray *gamesArray))result;

- (void) gameForSportLeague:(VSSportLeague *) sportLeague gameId:(NSUInteger)gameId result:(void (^)(VSGame *game))result;

- (void) gamesForSportLeague:(VSSportLeague *) sportLeague gameDateString:(NSString *)gameDateString result:(void (^)(NSArray *games)) result;
- (void) gamesForSportLeague:(VSSportLeague *) sportLeague gameDate:(NSDate *)gameDate result:(void (^)(NSArray *games)) result;

- (void) liveMatchesForSportLeague:(VSSportLeague *) sportLeague result:(void (^)(NSArray *games)) result;
- (void) lastWeekMatchesForSportLeague:(VSSportLeague *) sportLeague result:(void (^)(NSArray *games)) result;

@end
