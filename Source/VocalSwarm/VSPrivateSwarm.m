//
//  VSPrivateSwarm.m
//  VocalSwarm
//
//  Created by Alexey on 19.07.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSPrivateSwarm.h"

@interface VSPrivateSwarm()

@property (strong, nonatomic) QBCOCustomObject* co;

@end

@implementation VSPrivateSwarm

- (id)init
{
    self = [super init];
    if (self) {
        _co = nil;
        
        _participants = [NSArray array];
        
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
        
        _participants = [dict objectForKey:@"participants"];
        
        _matchId = [[dict objectForKey:@"gameId"] intValue];
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
    [self.co.fields setObject:self.participants
                       forKey:@"participants"];
    
    [self.co.fields setObject:[NSNumber numberWithInt:self.matchId]
                       forKey:@"gameId"];
    
    [self.co setClassName:CO_PRIVATE_SWARM_CLASS_NAME];
}

- (NSString *) getSwarmId {
    QBCOCustomObject *co = [self customObject];
    return co.ID;
}

- (NSString *) description {
    return [super description];
}

@end
