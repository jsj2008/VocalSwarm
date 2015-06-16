//
//  VSUtils.h
//  VocalSwarm
//
//  Created by Alexey on 07.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSUtils : NSObject

+ (NSString *) currentMonth;
+ (NSString *) nextMonth;
+ (NSString *) prevMonth;

+ (BOOL) isESTDateToday:(NSDate *)date;
+ (NSComparisonResult) compareESTDateWith:(NSDate *)date;

+ (void) parseNicknamesFile:(NSString *)filename toFile:(NSString *)destinationFilename;

+ (AVCaptureDevice *) backFacingCamera;
+ (AVCaptureDevice *) frontFacingCamera;

@end
