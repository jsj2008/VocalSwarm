//
//  VSSwarm.h
//  VocalSwarm
//
//  Created by Alexey on 20.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CO_SWARM_CLASS_NAME @"Swarm"

@class VSGame;

enum SwarmType {
    UndefinedType,
    TeamSwarmType,
    VSSwarmType,
    PrivateSwarmType
};

@interface VSSwarm : NSObject

@property (nonatomic) BOOL isMyHomeTeam;
@property (strong, nonatomic) VSGame* game;
@property (nonatomic) NSInteger matchId;
@property (nonatomic) enum SwarmType type;
@property (nonatomic) NSString* sportLeague;

+ (NSString *)swarmTypeStringFrom:(enum SwarmType) type;
+ (enum SwarmType)swarmTypeFrom:(NSString *) typeString;

- (id) initWithCO:(QBCOCustomObject*) co;

- (QBCOCustomObject *) customObject;

- (NSString *) getSwarmId;

- (NSString *) getFullDescription;

- (NSDate *) gameDate;

- (BOOL) isMine;

@end
