//
//  VSHeadline.m
//  VocalSwarm
//
//  Created by Alexey on 12.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSHeadline.h"

#import "TBXML.h"

@implementation VSHeadline

- (void) updateData:(TBXMLElement *)xmlElement
{
    if ([[TBXML elementName:xmlElement] isEqualToString:@"Game"]) {
        TBXMLElement *gameElement = xmlElement;
        
        TBXMLElement *gameIdElement = [TBXML childElementNamed:@"GameId" parentElement:gameElement];
        if (gameIdElement) {
            self.gameId = [[TBXML textForElement:gameIdElement] integerValue];
        }
        TBXMLElement *headlineElement = [TBXML childElementNamed:@"Headline" parentElement:gameElement];
        if (headlineElement) {
            self.headlineHeader = [TBXML textForElement:headlineElement];
        }
        TBXMLElement *headlineTypeElement = [TBXML childElementNamed:@"HeadlineType" parentElement:gameElement];
        if (headlineTypeElement) {
            self.headlineType = [TBXML textForElement:headlineTypeElement];
        }
    } else if ([[TBXML elementName:xmlElement] isEqualToString:@"Recap"]) {
        TBXMLElement *recapElement = xmlElement;
        
        TBXMLElement *storyElement = [TBXML childElementNamed:@"Story" parentElement:recapElement];
        if (storyElement) {
            TBXMLElement *bodyElement = [TBXML childElementNamed:@"Body" parentElement:storyElement];
            if (bodyElement) {
                self.body = [TBXML textForElement:bodyElement];
            }
            
            TBXMLElement *gameDataElement = [TBXML childElementNamed:@"GameDate" parentElement:storyElement];
            if (gameDataElement) {
                TBXMLElement *gameTimeElement = [TBXML childElementNamed:@"GameTime" parentElement:storyElement];
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
    }
}

@end
