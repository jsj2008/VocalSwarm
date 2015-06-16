//
//  VSUtils.m
//  VocalSwarm
//
//  Created by Alexey on 07.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSUtils.h"

@interface VSUtils()

+ (NSString *) monthName:(NSInteger) month;

@end

@implementation VSUtils

+ (NSString *) currentMonth {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM"];
    
    NSString *monthString = [df stringFromDate:[NSDate date]];
    
    return [VSUtils monthName:[monthString integerValue]];
}

+ (NSString *) nextMonth {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM"];
    
    NSString *monthString = [df stringFromDate:[NSDate date]];
    
    NSInteger monthNumber = [monthString integerValue];
    if (monthNumber == 12)
        monthNumber = 1;
    else
        monthNumber++;
    
    return [VSUtils monthName:monthNumber];
}

+ (NSString *) prevMonth {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM"];
    
    NSString *monthString = [df stringFromDate:[NSDate date]];
    NSInteger monthNumber = [monthString integerValue];
    if (monthNumber == 1)
        monthNumber = 12;
    else
        monthNumber--;
    
    return [VSUtils monthName:monthNumber];
}

+ (NSString *) monthName:(NSInteger) month {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    NSString *monthName = [[df monthSymbols] objectAtIndex:(month - 1)];
    return monthName;
}

+ (BOOL) isESTDateToday:(NSDate *)date {
    return ([VSUtils compareESTDateWith:date] == NSOrderedSame);
}

+ (NSComparisonResult) compareESTDateWith:(NSDate *)date {
    NSInteger calendarComponents = (NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit);
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *currentEST = [NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970] + [[NSTimeZone timeZoneWithName:@"EST"] secondsFromGMT] - [[NSTimeZone systemTimeZone] secondsFromGMT]];
    NSDateComponents *components = [cal components:calendarComponents fromDate:currentEST];
    NSDate *today = [cal dateFromComponents:components];
    
    NSDate *tmpDate = [NSDate dateWithTimeIntervalSince1970:[date timeIntervalSince1970] + [[NSTimeZone timeZoneWithName:@"EST"] secondsFromGMT] - [[NSTimeZone systemTimeZone] secondsFromGMT]];
    components = [cal components:calendarComponents fromDate:tmpDate];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    NSComparisonResult compares = [today compare:otherDate];
    
    return compares;
}

+ (void) parseNicknamesFile:(NSString *)filename toFile:(NSString *)destinationFilename
{
    NSLog(@"%@ started", NSStringFromSelector(_cmd));
    
    NSString *fileFullPath = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    NSString *fileContent = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:fileFullPath] encoding:NSASCIIStringEncoding];
    fileContent = [fileContent stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *line in [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        NSString *teamId = @"0";
        NSString *teamName = @"";
        NSString *teamNickname = @"";
        NSArray *components = [line componentsSeparatedByString:@","];
        if ([components count] > 0) {
            teamId = [components objectAtIndex:0];
        }
        if ([components count] > 1) {
            teamName = [components objectAtIndex:1];
        }
        if ([components count] > 2) {
            teamNickname = [components objectAtIndex:2];
        }
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:teamId, @"teamId", teamName, @"teamName", teamNickname, @"teamNickname", nil]];
    }
    
    NSString *outputFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:destinationFilename];
    [array writeToFile:outputFile atomically:YES];
    
    NSLog(@"%@ finished", NSStringFromSelector(_cmd));
}

+ (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

+ (AVCaptureDevice *) backFacingCamera
{
    return [[self class] cameraWithPosition:AVCaptureDevicePositionBack];
}

+ (AVCaptureDevice *) frontFacingCamera
{
    return [[self class] cameraWithPosition:AVCaptureDevicePositionFront];
}


@end
