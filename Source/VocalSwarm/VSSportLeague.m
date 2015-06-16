//
//  VSSportLeague.m
//  VocalSwarm
//
//  Created by Alexey on 06.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSportLeague.h"
#import "VSNetworkChalk.h"

@implementation VSSportLeague

+ (BOOL)isSportLeagueShortCode:(NSString *)shortCode
{
    return ([shortCode length] > 0 && [shortCode characterAtIndex:0] == 's');
}

+ (VSSportLeague *) sportLeagueForShortCode:(NSString *)shortCode {
    if ([shortCode length] == 0 || [shortCode characterAtIndex:0] != 's') {
        return nil;
    }
    shortCode = [shortCode substringFromIndex:1];
    if ([shortCode rangeOfString:@"-"].location == NSNotFound) {
        return nil;
    }
    
    NSString *sportCode = [shortCode substringToIndex:[shortCode rangeOfString:@"-"].location];
    NSString *leagueAbbr = [shortCode substringFromIndex:[shortCode rangeOfString:@"-"].location + 1];
    
    return [[VSSportLeague alloc] initWithSport:[VSNetworkChalk sportName:[sportCode integerValue]] league:leagueAbbr];
}

- (id) initWithSport:(NSString *)sportName league:(NSString *)leagueAbbr
{
    self = [super init];
    if (self) {
        _sportName = [[VSNetworkChalk sportName:[VSNetworkChalk sport:sportName]] copy];
        _leagueAbbr = [leagueAbbr copy];
    }
    return self;
}

- (NSString *) shortCode {
    return [NSString stringWithFormat:@"s%d-%@", [VSNetworkChalk sport:self.sportName], self.leagueAbbr];
}

- (NSString *)description {
    NSString *result = [super description];
    result = [result stringByAppendingString:@" {"];
    if (![self.sportName isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@"sportName = %@", self.sportName];
    }
    
    if (![self.leagueAbbr isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@" leagueAbbr = %@", self.leagueAbbr];
    }
    
    result = [result stringByAppendingString:@"}"];
    
    return result;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.sportName forKey:@"sportName"];
    [encoder encodeObject:self.leagueAbbr forKey:@"leagueAbbr"];
}

- (id) initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.sportName = [decoder decodeObjectForKey:@"sportName"];
        self.leagueAbbr = [decoder decodeObjectForKey:@"leagueAbbr"];
    }
    return self;
}

- (BOOL) isEqual:(id) aObject {
    if ([aObject class] != [self class]) {
        return false;
    }
    
    VSSportLeague *aTeam = (VSSportLeague *)aObject;
    if ([self.sportName isEqualToString:aTeam.sportName] &&
        [self.leagueAbbr isEqualToString:aTeam.leagueAbbr])
    {
        return true;
    }
    
    return false;
}


@end
