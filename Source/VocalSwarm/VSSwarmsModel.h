//
//  VSSwarmsModel.h
//  VocalSwarm
//
//  Created by Alexey on 20.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VSSwarm;
@class VSTeamSwarm;
@class VSvsSwarm;
@class VSPrivateSwarm;

typedef void (^VSSwarmModelResultBlock)(NSArray *swarms);

typedef void (^VSSwarmModelSingleResultBlock)(VSSwarm *swarm);

typedef void (^VSSwarmModelTeamResultBlock)(VSTeamSwarm *swarm);

typedef void (^VSSwarmModelvsResultBlock)(VSvsSwarm *swarm);

typedef void (^VSSwarmModelPrivateResultBlock)(VSPrivateSwarm *swarm);

@interface VSSwarmsModel : NSObject

//@property (strong, nonatomic) QBUUser* user;

+ (VSSwarmsModel*) sharedInstance;

//- (void) getSwarmDataWithResult:(VSSwarmModelResultBlock) result;

- (void) updateSwarmDataWithResult:(VSSwarmModelResultBlock) result;


- (void) createSwarm:(VSSwarm*) swarm forUser:(NSString *)userId result:(VSSwarmModelSingleResultBlock) result;

- (void) findSwarms:(VSSwarm*) swarm forUser:(NSString *)userId result:(VSSwarmModelResultBlock) result;

- (void) removeSwarm:(VSSwarm *) swarm;


- (void) connectOrCreateToTeamSwarm:(VSSwarm *) game result:(VSSwarmModelTeamResultBlock) resultBlock;

- (void) connectOrCreateToVsSwarm:(VSSwarm *) game result:(VSSwarmModelvsResultBlock) resultBlock;

- (void) findPrivateSwarm:(NSString *)gameId result:(VSSwarmModelPrivateResultBlock) resultBlock;

- (void) createPrivateSwarm:(VSSwarm *)swarmPrototype participants:(NSArray *) participants result:(VSSwarmModelPrivateResultBlock) resultBlock;

@end
