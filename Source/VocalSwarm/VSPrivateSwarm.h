//
//  VSPrivateSwarm.h
//  VocalSwarm
//
//  Created by Alexey on 19.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CO_PRIVATE_SWARM_CLASS_NAME @"PrivateSwarm"

@interface VSPrivateSwarm : NSObject

@property (strong, nonatomic) NSArray *participants;

@property (nonatomic) NSInteger matchId;

- (id) initWithCO:(QBCOCustomObject*) co;

- (NSString *) getSwarmId;

- (QBCOCustomObject *) customObject;

@end
