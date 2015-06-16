//
//  VSNetworkESPN.h
//  VocalSwarm
//
//  Created by Alexey on 05.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSNetworkESPN : NSObject

+ (VSNetworkESPN*) sharedInstance;

- (void) sportsRequest:(void (^)(id JSON))result;

- (void) teamsRequest:(NSString *)sportName result:(void (^)(id JSON))result;

- (void) headlineRequest:(NSArray *)favoriteSports teams:(NSArray*)favoriteTeams result:(void (^)(id JSON))result;

@end
