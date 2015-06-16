//
//  VSSettingsModel.h
//  VocalSwarm
//
//  Created by Alexey on 05.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROPS_CLASS_NAME @"Props"
#define PROPS_COLUMN_NAME @"PropsCount"

@class VSTeam;
@class VSSportLeague;

typedef void (^QBCOResultBlock)(QBCOCustomObject* co);

@interface VSSettingsModel : NSObject

+ (void) setCurrentUser:(QBUUser*)user;
+ (QBUUser*) currentUser;

+ (NSArray*) getFavoriteSports;
+ (void) addFavoriteSport:(VSSportLeague*) sport;
+ (void) removeFavoriteSport:(VSSportLeague*) sport;

+ (NSArray*) getFavoriteTeams;
+ (void) addFavoriteTeam:(VSTeam*) team;
+ (void) removeFavoriteTeam:(VSTeam*) team;

+ (NSString*) stringForTeam:(NSDictionary*) teamDict;

+ (NSInteger) propsRest:(NSString *)swarmId;
+ (void) propsIncreaseRest:(NSString *)swarmId;

+ (void) synchronizeAlltoServer:(BOOL)ifToServer finished:(QBCOResultBlock)result;

@end
