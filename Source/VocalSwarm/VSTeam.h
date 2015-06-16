//
//  VSTeam.h
//  VocalSwarm
//
//  Created by Alexey on 05.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSSportLeague.h"

@interface VSTeam : NSObject

@property (nonatomic, strong) VSSportLeague* sportLeague;

@property (nonatomic) NSUInteger teamId;
@property (nonatomic, copy) NSString *teamName;
@property (nonatomic, copy) NSString *teamNickname;
@property (nonatomic, copy) NSString *league;
@property (nonatomic, copy) NSString *division;
@property (nonatomic, copy) NSString *teamNewspaperLink;
@property (nonatomic, strong) NSMutableArray *headlines;

+ (BOOL) isTeamShortCode:(NSString *) shortCode;
+ (NSUInteger) sportFromShortCode:(NSString *) shortCode;
+ (NSString *) leagueAbbrFromShortCode:(NSString *) shortCode;
+ (NSUInteger) teamIdFromShortCode:(NSString *) shortCode;

- (id) initWithSportLeague:(VSSportLeague*) sportLeague;

- (void) updateData:(id) xmlElement;

- (NSString *) shortCode;

@end
