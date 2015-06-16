//
//  VSvsSwarm.m
//  VocalSwarm
//
//  Created by Alexey on 15.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSvsSwarm.h"

@interface VSvsSwarm()

@property (strong, nonatomic) QBCOCustomObject* co;

@end

@implementation VSvsSwarm

- (id)init
{
    self = [super init];
    if (self) {
        _co = nil;

        _matchId = 0;
        _game = nil;
    }
    return self;
}

- (id) initWithCO:(QBCOCustomObject*) co
{
    self = [super init];
    if (self) {
        _co = co;
        NSDictionary *dict = [co fields];
        
        _matchId = [[dict objectForKey:@"gameId"] intValue];
        _game = nil;
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
    [self.co.fields setObject:[NSNumber numberWithInt:self.matchId]
                       forKey:@"gameId"];
    
    [self.co setClassName:CO_VS_SWARM_CLASS_NAME];
}

- (NSString *) getSwarmId {
    QBCOCustomObject *co = [self customObject];
    return co.ID;
}

@end
