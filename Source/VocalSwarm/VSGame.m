//
//  VSGame.m
//  VocalSwarm
//
//  Created by Alexey on 07.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSGame.h"
#import "VSUtils.h"
#import "TBXML.h"

@implementation VSGame

- (id) init
{
    self = [super init];
    if (self) {
        _gameId = 0;
        _homeTeam = nil;
        _awayTeam = nil;
        _homeTeamScore = 0;
        _awayTeamScore = 0;
        _homeTeamId = 0;
        _awayTeamId = 0;
        _gameDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    return self;
}

- (void) updateData:(TBXMLElement *) xmlElement
{
    TBXMLElement *gameElement = xmlElement;
    
    TBXMLElement *gameIdElement = [TBXML childElementNamed:@"GameId" parentElement:gameElement];
    if (gameIdElement) {
        self.gameId = [[TBXML textForElement:gameIdElement] integerValue];
    }
    
    TBXMLElement *gameStatusElement = [TBXML childElementNamed:@"Status" parentElement:gameElement];
    if (gameStatusElement) {
        self.status = [TBXML textForElement:gameStatusElement];
    }
    
    TBXMLElement *awayTeamIdElement = [TBXML childElementNamed:@"AwayId" parentElement:gameElement];
    if (awayTeamIdElement) {
        self.awayTeamId = [[TBXML textForElement:awayTeamIdElement] integerValue];
    }
    awayTeamIdElement = [TBXML childElementNamed:@"AwayTeamId" parentElement:gameElement];
    if (awayTeamIdElement) {
        self.awayTeamId = [[TBXML textForElement:awayTeamIdElement] integerValue];
    }
    
    TBXMLElement *homeTeamIdElement = [TBXML childElementNamed:@"HomeId" parentElement:gameElement];
    if (homeTeamIdElement) {
        self.homeTeamId = [[TBXML textForElement:homeTeamIdElement] integerValue];
    }
    homeTeamIdElement = [TBXML childElementNamed:@"HomeTeamId" parentElement:gameElement];
    if (homeTeamIdElement) {
        self.homeTeamId = [[TBXML textForElement:homeTeamIdElement] integerValue];
    }
    
    TBXMLElement *awayScoreElement = [TBXML childElementNamed:@"AwayScore" parentElement:gameElement];
    if (awayScoreElement) {
        self.awayTeamScore = [[TBXML textForElement:awayScoreElement] integerValue];
    }
    TBXMLElement *homeScoreElement = [TBXML childElementNamed:@"HomeScore" parentElement:gameElement];
    if (homeScoreElement) {
        self.homeTeamScore = [[TBXML textForElement:homeScoreElement] integerValue];
    }
    
    TBXMLElement *gameDataElement = [TBXML childElementNamed:@"GameDate" parentElement:gameElement];
    if (gameDataElement) {
        TBXMLElement *gameTimeElement = [TBXML childElementNamed:@"GameTime" parentElement:gameElement];
        if (gameTimeElement) {
            NSString *dateString = [TBXML textForElement:gameDataElement];
            NSString *timeString = [TBXML textForElement:gameTimeElement];
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
            [format setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
            [format setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
            NSString *formatString = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
            self.gameDate = [format dateFromString:formatString];
        }
    }
}

- (NSString *)description
{
    NSString *result = [super description];
    
    result = [result stringByAppendingString:@" {"];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@"gameId=%d", self.gameId]];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@",gameDate=%@", self.gameDate]];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@",homeTeamId=%d", self.homeTeamId]];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@",awayTeamId=%d", self.awayTeamId]];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@",homeTeamScore=%d", self.homeTeamScore]];
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@",awayTeamScore=%d", self.awayTeamScore]];
    
    if (self.homeTeam) {
        result = [result stringByAppendingString:[self.homeTeam description]];
    }
    
    if (self.awayTeam) {
        result = [result stringByAppendingString:[self.awayTeam description]];
    }
    
    result = [result stringByAppendingString:@"}"];
    
    return result;
}

- (BOOL) isEqual:(id) aObject {
    if ([aObject class] != [self class]) {
        return false;
    }
    
    VSGame *aGame = (VSGame *)aObject;
    if (self.gameId == aGame.gameId)
    {
        return true;
    }
    
    return false;
}

- (BOOL) isLive {    
    NSTimeInterval timeDifference = [self.gameDate timeIntervalSinceNow];
    
    if ([VSUtils isESTDateToday:self.gameDate] && timeDifference < 0 && ![self.status isEqualToString:@"Final"]) {
        return YES;
    }
    
    return NO;
}

- (BOOL) isFinished {
    if ([self.status isEqualToString:@"Final"]) {
        return YES;
    }
    
    if ([VSUtils compareESTDateWith:self.gameDate] == NSOrderedDescending) {
        return YES;
    }
    
//    NSInteger calendarComponents = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
//    
//    NSCalendar *cal = [NSCalendar currentCalendar];
//    NSDateComponents *components = [cal components:calendarComponents fromDate:[NSDate date]];
//    NSDate *today = [cal dateFromComponents:components];
//    components = [cal components:calendarComponents fromDate:self.gameDate];
//    NSDate *otherDate = [cal dateFromComponents:components];
//    
//    NSComparisonResult compres = [today compare:otherDate];
//    
//    if(compres == NSOrderedDescending) {
//        return YES;
//    }
    
    return NO;
}

@end
