//
//  VSNetworkESPN.m
//  VocalSwarm
//
//  Created by Alexey on 05.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSNetworkESPN.h"

#import "AFNetworking.h"

@interface VSNetworkESPN ()

@property (strong, nonatomic) NSString *cacheDirectory;

@end

@implementation VSNetworkESPN

#define ESPN_API_KEY @"fhay4w8detwff3tjae6a6aa8"

#define ESPN_NEWS_LIMIT @"4"

#define ESPN_SPORTS_REQUEST_STRING [NSString stringWithFormat:@"http://api.espn.com/v1/sports/?apikey=%@", ESPN_API_KEY]

#define ESPN_LEAGUES_REQUEST_STRING [NSString stringWithFormat:@"http://api.espn.com/v1/sports/%%@/teams/?apikey=%@", ESPN_API_KEY]

#define ESPN_TEAMS_REQUEST_STRING [NSString stringWithFormat:@"http://api.espn.com/v1/sports/%%@/%%@/teams/?apikey=%@", ESPN_API_KEY]

#define SPORT_CACHE_FILENAME @"sportCache.json"

#define TEAMS_CACHE_FILENAME @"teamsCache.%@.json"

+ (VSNetworkESPN*) sharedInstance
{
    static dispatch_once_t pred;
    static VSNetworkESPN *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[VSNetworkESPN alloc] init];
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

- (void) sportsRequest:(void (^)(id JSON))result {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:SPORT_CACHE_FILENAME];
    if([fileManager fileExistsAtPath:cachePath]) {
        result([NSDictionary dictionaryWithContentsOfFile:cachePath]);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:ESPN_SPORTS_REQUEST_STRING];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [(NSDictionary*)responseObject writeToFile:cachePath atomically:YES];
        if (result) {
            result(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

- (void) teamsRequest:(NSString *)sportName result:(void (^)(id JSON))result {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:TEAMS_CACHE_FILENAME, sportName]];
    if([fileManager fileExistsAtPath:cachePath]) {
        result([NSDictionary dictionaryWithContentsOfFile:cachePath]);
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:ESPN_LEAGUES_REQUEST_STRING, sportName];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (result) {
            [self teamsSubRequest:sportName data:responseObject result:result];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self teamsRequest:sportName result:result];
    }];

    [operation start];
}

- (void) teamsSubRequest:(NSString*) sportName data:(id) data result:(void (^)(id JSON))result {
    BOOL isAllTeam = YES;
    for (NSDictionary* leagueDict in [[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"]) {
        if (![leagueDict objectForKey:@"teams"]) {
            
            NSString *leagueAbbreviation = [leagueDict objectForKey:@"abbreviation"];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/?apikey=%@",
                                                    [[[[leagueDict objectForKey:@"links"] objectForKey:@"api"] objectForKey:@"teams"] objectForKey:@"href"],
                                                    ESPN_API_KEY]];
            NSLog(@"%@", url);
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            operation.responseSerializer = [AFJSONResponseSerializer serializer];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary* updatedLeagueData = [[[[responseObject objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] objectAtIndex:0];
                for (int i = 0; i < [[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] count]; i++) {
                    NSDictionary* oldLeagueData = [[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] objectAtIndex:i];
                    if ([[oldLeagueData objectForKey:@"abbreviation"] isEqualToString:leagueAbbreviation]) {
                        NSMutableArray *mutableLeagues = [NSMutableArray arrayWithArray:[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"]];
                        [mutableLeagues replaceObjectAtIndex:i withObject:updatedLeagueData];
                        NSMutableDictionary *mutableSport = [NSMutableDictionary dictionaryWithDictionary:[[data objectForKey:@"sports"] objectAtIndex:0]];
                        [mutableSport setObject:mutableLeagues forKey:@"leagues"];
                        NSMutableArray *mutableSports = [NSMutableArray arrayWithArray:[data objectForKey:@"sports"]];
                        [mutableSports replaceObjectAtIndex:0 withObject:mutableSport];
                        NSMutableDictionary *mutableData = [NSMutableDictionary dictionaryWithDictionary:data];
                        [mutableData setObject:mutableSports forKey:@"sports"];
                        
                        [self teamsSubRequest:sportName data:mutableData result:result];
                        break;
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    //update team info with empty array
                    for (int i = 0; i < [[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] count]; i++) {
                        NSDictionary* oldLeagueData = [[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] objectAtIndex:i];
                        if ([[oldLeagueData objectForKey:@"abbreviation"] isEqualToString:leagueAbbreviation]) {
                            NSMutableDictionary *mutableLeague = [NSMutableDictionary dictionaryWithDictionary:[[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"] objectAtIndex:i]];
                            [mutableLeague setObject:[NSArray array] forKey:@"teams"];
                            NSMutableArray *mutableLeagues = [NSMutableArray arrayWithArray:[[[data objectForKey:@"sports"] objectAtIndex:0] objectForKey:@"leagues"]];
                            [mutableLeagues replaceObjectAtIndex:i withObject:mutableLeague];
                            NSMutableDictionary *mutableSport = [NSMutableDictionary dictionaryWithDictionary:[[data objectForKey:@"sports"] objectAtIndex:0]];
                            [mutableSport setObject:mutableLeagues forKey:@"leagues"];
                            NSMutableArray *mutableSports = [NSMutableArray arrayWithArray:[data objectForKey:@"sports"]];
                            [mutableSports replaceObjectAtIndex:0 withObject:mutableSport];
                            NSMutableDictionary *mutableData = [NSMutableDictionary dictionaryWithDictionary:data];
                            [mutableData setObject:mutableSports forKey:@"sports"];
                            
                            [self teamsSubRequest:sportName data:mutableData result:result];
                            break;
                        }
                }
            }];
            [operation start];
            
            isAllTeam = NO;
            break;
        }
    }
    if (isAllTeam) {
        NSLog(@"done");
        
        NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:TEAMS_CACHE_FILENAME, sportName]];
        [(NSDictionary*)data writeToFile:cachePath atomically:YES];
        
        if (result) {
            result(data);
        }
    }
}

- (void) headlineRequest:(NSArray *)favoriteSports teams:(NSArray*)favoriteTeams result:(void (^)(id JSON))result {
    NSLog(@"%@\n%@", favoriteSports, favoriteTeams);
    return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self headlineSubRequest:[NSMutableArray arrayWithArray:favoriteSports] teams:[NSMutableArray arrayWithArray:favoriteTeams] data:[NSMutableArray array] result:result];
    });
}

- (void) headlineSubRequest:(NSMutableArray *)favoriteSports teams:(NSMutableArray *)favoriteTeams data:(NSMutableArray *)data result:(void (^)(id JSON))result {
    //for every teams
    if ([favoriteTeams count] > 0) {
        NSDictionary* teamData = [favoriteTeams objectAtIndex:[favoriteTeams count] - 1];
        [favoriteTeams removeLastObject];
        
        NSString* newsString = [[[[[[teamData objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"links"] objectForKey:@"api"] objectForKey:@"news"] objectForKey:@"href"];
        NSString* correctedNewsString = [NSString stringWithFormat:@"%@/?apikey=%@&limit=%@", newsString, ESPN_API_KEY, ESPN_NEWS_LIMIT];
        
        NSURL *url = [NSURL URLWithString:correctedNewsString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            for (NSDictionary* headlineDict in [responseObject objectForKey:@"headlines"]) {
                NSMutableDictionary* mutableHeadlineDict = [NSMutableDictionary dictionaryWithDictionary:headlineDict];
                
                NSString *teamName = [[[teamData objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"name"];
                NSString *teamLocation = [[[teamData objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"location"];
                
                [mutableHeadlineDict setObject:[NSString stringWithFormat:@"%@ %@", teamLocation, teamName] forKey:@"mainTitle"];
                
                [data addObject:mutableHeadlineDict];
            }
            
            [self headlineSubRequest:favoriteSports
                               teams:favoriteTeams
                                data:data
                              result:result];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self headlineSubRequest:favoriteSports
                               teams:favoriteTeams
                                data:data
                              result:result];
        }];

        [operation start];
        
    }
    //for every sport
    else if ([favoriteSports count] > 0) {
        NSDictionary* sportData = [favoriteSports objectAtIndex:[favoriteSports count] - 1];
        [favoriteSports removeLastObject];
        
        NSLog(@"%@", sportData);
        
        NSString* newsString = [[[[sportData objectForKey:@"links"] objectForKey:@"api"] objectForKey:@"sports"] objectForKey:@"href"];
        NSString* leagueAbbreviation = [[[sportData objectForKey:@"leagues"] objectAtIndex:0] objectForKey:@"abbreviation"];
        NSString* correctedNewsString = [NSString stringWithFormat:@"%@/%@/news/?apikey=%@&limit=%@", newsString, leagueAbbreviation, ESPN_API_KEY, ESPN_NEWS_LIMIT];
        
        NSURL *url = [NSURL URLWithString:correctedNewsString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            for (NSDictionary* headlineDict in [responseObject objectForKey:@"headlines"]) {
                NSMutableDictionary* mutableHeadlineDict = [NSMutableDictionary dictionaryWithDictionary:headlineDict];
                
                NSString *sportName = [sportData objectForKey:@"name"];
                NSString *sportLeague = [[[sportData objectForKey:@"leagues"] objectAtIndex:0] objectForKey:@"shortName"];
                
                [mutableHeadlineDict setObject:[NSString stringWithFormat:@"%@ %@", sportLeague, sportName] forKey:@"mainTitle"];
                
                [data addObject:mutableHeadlineDict];
            }
            
            [self headlineSubRequest:favoriteSports
                               teams:favoriteTeams
                                data:data
                              result:result];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self headlineSubRequest:favoriteSports
                               teams:favoriteTeams
                                data:data
                              result:result];

        }];
        
        [operation start];

    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            result(data);
        });
    }
}

@end
