//
//  VSHeadline.h
//  VocalSwarm
//
//  Created by Alexey on 12.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSTeam;

@interface VSHeadline : NSObject

@property (nonatomic) NSInteger gameId;
@property (nonatomic, copy) NSString *headlineHeader;
@property (nonatomic, copy) NSString *headlineType;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, weak) VSTeam *team;
@property (nonatomic, strong) NSDate *gameDate;

- (void) updateData:(id) xmlElement;

@end
