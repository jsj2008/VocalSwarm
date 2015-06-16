//
//  VSTeamSwarm.m
//  VocalSwarm
//
//  Created by Alexey on 15.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSTeamSwarm.h"

@interface VSTeamSwarm()

@property (strong, nonatomic) QBCOCustomObject* co;

@end

@implementation VSTeamSwarm

- (id)init
{
    self = [super init];
    if (self) {
        _co = nil;
        _game = nil;
        _matchId = 0;
    }
    return self;
}

- (id) initWithCO:(QBCOCustomObject*) co
{
    self = [super init];
    if (self) {
        _co = co;
        NSDictionary *dict = [co fields];
        _game = nil;
        _isMyTeamHome = [[dict objectForKey:@"isHomeTeam"] boolValue];
        _matchId      = [[dict objectForKey:@"gameId"] intValue];
    }
    return self;
}

- (QBCOCustomObject *) customObject
{
    if (self.co == nil) {
        self.co = [[QBCOCustomObject alloc] init];
    }
    [self updateCO];
    
    return self.co;
}

- (void) updateCO
{
    [self.co.fields setObject:[NSNumber numberWithBool:self.isMyTeamHome]
                       forKey:@"isHomeTeam"];
    [self.co.fields setObject:[NSNumber numberWithInt:self.matchId]
                       forKey:@"gameId"];
    
    [self.co setClassName:CO_TEAM_SWARM_CLASS_NAME];
}

- (NSString *) getSwarmId {
    QBCOCustomObject *co = [self customObject];
    return co.ID;
}

@end
