//
//  VSSwarm.m
//  VocalSwarm
//
//  Created by Alexey on 20.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSwarm.h"
#import "VSGame.h"

#import "VSSettingsModel.h"

@interface VSSwarm()

@property (strong, nonatomic) QBCOCustomObject* co;

@end

@implementation VSSwarm

+ (NSString *)swarmTypeStringFrom:(enum SwarmType) type {
    switch (type) {
        case UndefinedType:
            return @"undefinedType";
            break;
        case VSSwarmType:
            return @"versusType";
            break;
        case PrivateSwarmType:
            return @"privateType";
            break;
        case TeamSwarmType:
            return @"teamType";
            break;
    }
    return nil; //cannot be
}

+ (enum SwarmType)swarmTypeFrom:(NSString *) typeString {
    if (typeString) {
        if ([typeString isEqualToString:@"versusType"]) {
            return VSSwarmType;
        } else if ([typeString isEqualToString:@"privateType"]) {
            return PrivateSwarmType;
        } else if ([typeString isEqualToString:@"teamType"]) {
            return TeamSwarmType;
        }
    }
    
    return UndefinedType;
}

- (id)init
{
    self = [super init];
    if (self) {
        _type = UndefinedType;
        _co = nil;
        _matchId = 0;
        _game = nil;
        _isMyHomeTeam = NO;
        _sportLeague = @"";
    }
    return self;
}

- (id) initWithCO:(QBCOCustomObject*) co
{
    self = [super init];
    if (self) {
        _co = co;
        NSDictionary *dict = [co fields];
        _type         = [VSSwarm swarmTypeFrom:[dict objectForKey:@"swarmType"]];
        _matchId      = [[dict objectForKey:@"gameId"] intValue];
        _isMyHomeTeam = [[dict objectForKey:@"myTeamHome"] boolValue];
        _sportLeague  = [dict objectForKey:@"sportLeague"];
        _game = nil;
    }
    return self;
}

- (void)setGame:(VSGame *)game
{
    if (_game != game) {
        _game = game;
        _matchId = [game gameId];
    }
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
    [self.co.fields setObject:[NSNumber numberWithBool:self.isMyHomeTeam]
                       forKey:@"myTeamHome"];
    [self.co.fields setObject:self.sportLeague
                       forKey:@"sportLeague"];
    [self.co.fields setObject:[VSSwarm swarmTypeStringFrom:self.type]
                       forKey:@"swarmType"];
    
    [self.co setClassName:CO_SWARM_CLASS_NAME];
}

- (NSString *) getSwarmId {
    QBCOCustomObject *co = [self customObject];
    return co.ID;
}

- (NSString *) getFullDescription {
//    VSTeam *myTeam = self.isMyHomeTeam ? self.game.homeTeam : self.game.awayTeam;
//    VSTeam *opponentTeam = self.isMyHomeTeam ? self.game.awayTeam : self.game.homeTeam;
    VSTeam *myTeam = self.game.homeTeam;
    VSTeam *opponentTeam = self.game.awayTeam;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"eee MM/dd h:mma 'est'"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
    [df setAMSymbol:@"am"];
    [df setPMSymbol:@"pm"];
    NSString *gameFormattedDate = [df stringFromDate:[self.game gameDate]];
    
//    NSString *titleString = [NSString stringWithFormat:@"%@ VS %@ %@", [myTeam teamName], [opponentTeam teamName], gameFormattedDate];
    NSString *titleString = [NSString stringWithFormat:@"%@ VS %@ %@", [myTeam teamNickname], [opponentTeam teamNickname], gameFormattedDate];
    
    
    
    return titleString;
}

- (NSDate *) gameDate {
    return [self.game gameDate];
}

- (BOOL) isMine {
    if (self.co) {
//        return [self.co.parentID isEqualToString:[VSSettingsModel currentUser].facebookID];
        return self.co.userID == [VSSettingsModel currentUser].ID;
    }
    return YES;
}

@end
