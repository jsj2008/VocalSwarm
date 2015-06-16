//
//  VSTeam.m
//  VocalSwarm
//
//  Created by Alexey on 05.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSTeam.h"
#import "VSNetworkChalk.h"
#import "VSHeadline.h"

#import "TBXML.h"

@implementation VSTeam

+ (BOOL) isTeamShortCode:(NSString *) shortCode
{
    return ([shortCode length] > 0 && [shortCode characterAtIndex:0] == 't');
}

+ (NSUInteger) sportFromShortCode:(NSString *) shortCode
{
    shortCode = [shortCode substringFromIndex:1];
    NSString *sport = [shortCode substringToIndex:[shortCode rangeOfString:@"-"].location];
    return [sport integerValue];
}

+ (NSString *) leagueAbbrFromShortCode:(NSString *) shortCode
{
    NSString *league = [shortCode substringFromIndex:[shortCode rangeOfString:@"-"].location + 1];
    league = [league substringToIndex:[league rangeOfString:@"-"].location];
    return league;
}

+ (NSUInteger) teamIdFromShortCode:(NSString *) shortCode
{
    NSString *teamId = [shortCode substringFromIndex:[shortCode rangeOfString:@"-" options:NSBackwardsSearch].location + 1];
    return [teamId integerValue];
}

- (id) initWithSportLeague:(VSSportLeague*) sportLeague
{
    self = [super init];
    if (self) {
        self.sportLeague = sportLeague;
        _teamId = 0;
        _teamName = @"";
        _teamNickname = @"";
        _league = @"";
        _division = @"";
    }
    return self;
}

- (NSMutableArray *)headlines {
    if (_headlines == nil) {
        _headlines = [NSMutableArray array];
    }
    return _headlines;
}

- (void) updateData:(TBXMLElement *)xmlElement
{
    if ([[TBXML elementName:xmlElement] isEqualToString:@"Team"]) {
        TBXMLElement *teamElement = xmlElement;
        TBXMLElement *teamNameElement = [TBXML childElementNamed:@"TeamName" parentElement:teamElement];
        if (teamNameElement) {
            self.teamName = [TBXML textForElement:teamNameElement];
        }
        TBXMLElement *teamIdElement = [TBXML childElementNamed:@"TeamId" parentElement:teamElement];
        if (teamIdElement) {
            self.teamId = [[TBXML textForElement:teamIdElement] integerValue];
        }
        TBXMLElement *leagueElement = [TBXML childElementNamed:@"League" parentElement:teamElement];
        if (leagueElement) {
            self.league = [TBXML textForElement:leagueElement];
        }
        TBXMLElement *divisionElement = [TBXML childElementNamed:@"Division" parentElement:teamElement];
        if (divisionElement) {
            self.division = [TBXML textForElement:divisionElement];
        }
    } else if ([[TBXML elementName:xmlElement] isEqualToString:@"TeamReport"]) {
        TBXMLElement *teamReportElement = xmlElement;
        TBXMLElement *teamHeaderElement = [TBXML childElementNamed:@"TeamHeader" parentElement:teamReportElement];
        if (teamHeaderElement) {
            TBXMLElement *headerElement = [TBXML childElementNamed:@"Header" parentElement:teamHeaderElement];
            if (headerElement) {
//                TBXMLElement *teamNicknameElement = [TBXML childElementNamed:@"TeamNickname" parentElement:headerElement];
//                if (teamNicknameElement) {
//                    self.teamNickname = [TBXML textForElement:teamNicknameElement];
//                }
                TBXMLElement *teamNewspaperLinkElement = [TBXML childElementNamed:@"NewspaperLink" parentElement:headerElement];
                if (teamNewspaperLinkElement) {
                    self.teamNewspaperLink = [TBXML textForElement:teamNewspaperLinkElement];
                }
            }
        }
        TBXMLElement *teamHeadlinesElement = [TBXML childElementNamed:@"Headlines" parentElement:teamReportElement];
        if (teamHeadlinesElement) {
            //TODO headlines parsing here
            TBXMLElement *gameElement = [TBXML childElementNamed:@"Game" parentElement:teamHeadlinesElement];
            while (gameElement) {
                VSHeadline *headline = [[VSHeadline alloc] init];
                [headline updateData:(__bridge id)(gameElement)];
                [headline setTeam:self];
                if ([[headline headlineType] isEqualToString:@"Recap"]) {
                    [self.headlines addObject:headline];
                }
                gameElement = [TBXML nextSiblingNamed:@"Game" searchFromElement:gameElement];
            }
        }
    }
}

- (NSString *) shortCode {
    return [NSString stringWithFormat:@"t%d-%@-%d", [VSNetworkChalk sport:[self.sportLeague sportName]], [self.sportLeague leagueAbbr], self.teamId];
}

#pragma mark - methods override

- (NSString *) description
{
    NSString* result = [super description];
    
    result = [result stringByAppendingString:@" {"];
    
    if (self.sportLeague != nil) {
        result = [result stringByAppendingString:[self.sportLeague description]];
    }
    
    if (self.teamId != 0) {
        result = [result stringByAppendingFormat:@" teamId = %d", self.teamId];
    }
    
    if (![self.teamName isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@" teamName = %@", self.teamName];
    }
    
    if (![self.teamNickname isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@" teamNickName = %@", self.teamNickname];
    }
    
    if (![self.league isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@" league = %@", self.league];
    }
    
    if (![self.division isEqualToString:@""]) {
        result = [result stringByAppendingFormat:@" division = %@", self.division];
    }
    
    result = [result stringByAppendingString:@"}"];
    
    return result;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.sportLeague forKey:@"sportLeague"];
    [encoder encodeInteger:self.teamId forKey:@"teamId"];
    [encoder encodeObject:self.teamName forKey:@"teamName"];
    [encoder encodeObject:self.teamNickname forKey:@"teamNickname"];
    [encoder encodeObject:self.league forKey:@"league"];
    [encoder encodeObject:self.division forKey:@"division"];
}

- (id) initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.sportLeague = [decoder decodeObjectForKey:@"sportLeague"];
        self.teamId = [decoder decodeIntegerForKey:@"teamId"];
        self.teamName = [decoder decodeObjectForKey:@"teamName"];
        self.teamNickname = [decoder decodeObjectForKey:@"teamNickname"];
        self.league = [decoder decodeObjectForKey:@"league"];
        self.division = [decoder decodeObjectForKey:@"division"];
    }
    return self;
}

- (BOOL) isEqual:(id) aObject {
    if ([aObject class] != [self class]) {
        return false;
    }
    
    VSTeam *aTeam = (VSTeam *)aObject;
    if (self.teamId == aTeam.teamId && [self.sportLeague isEqual:aTeam.sportLeague])
    {
        return true;
    }
    
    return false;
}

@end
