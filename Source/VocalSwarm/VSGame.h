//
//  VSGame.h
//  VocalSwarm
//
//  Created by Alexey on 07.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSTeam.h"

@interface VSGame : NSObject

@property (nonatomic, strong) VSTeam* homeTeam;
@property (nonatomic, strong) VSTeam* awayTeam;
@property (nonatomic) NSUInteger gameId;
@property (nonatomic) NSUInteger homeTeamScore;
@property (nonatomic) NSUInteger awayTeamScore;
@property (nonatomic, strong) NSDate* gameDate;

@property (nonatomic) NSUInteger awayTeamId;
@property (nonatomic) NSUInteger homeTeamId;

@property (nonatomic, copy) NSString *status;

- (void) updateData:(id) xmlElement;

- (BOOL) isFinished;
- (BOOL) isLive;

@end
