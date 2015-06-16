//
//  VSTeamSwarm.h
//  VocalSwarm
//
//  Created by Alexey on 15.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CO_TEAM_SWARM_CLASS_NAME @"TeamSwarm"

@class VSGame;

@interface VSTeamSwarm : NSObject

@property (strong, nonatomic) VSGame* game;
@property (nonatomic) NSInteger matchId;
@property (nonatomic) BOOL isMyTeamHome;

- (id) initWithCO:(QBCOCustomObject*) co;

- (NSString *) getSwarmId;

- (QBCOCustomObject *) customObject;

@end
