//
//  VSSportLeague.h
//  VocalSwarm
//
//  Created by Alexey on 06.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSSportLeague : NSObject

@property (nonatomic, copy) NSString *sportName;
@property (nonatomic, copy) NSString *leagueAbbr;

+ (VSSportLeague *) sportLeagueForShortCode:(NSString *)shortCode;
+ (BOOL) isSportLeagueShortCode:(NSString *)shortCode;

- (id) initWithSport:(NSString *)sportName league:(NSString *)leagueAbbr;

- (NSString *) shortCode;

@end
