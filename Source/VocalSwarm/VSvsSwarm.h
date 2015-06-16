//
//  VSvsSwarm.h
//  VocalSwarm
//
//  Created by Alexey on 15.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CO_VS_SWARM_CLASS_NAME @"vsSwarm"

@class VSGame;

@interface VSvsSwarm : NSObject

@property (strong, nonatomic) VSGame* game;
@property (nonatomic) NSInteger matchId;
@property (nonatomic) BOOL isMyTeamHome;

- (id) initWithCO:(QBCOCustomObject*) co;

- (NSString *) getSwarmId;

- (QBCOCustomObject *) customObject;

@end
