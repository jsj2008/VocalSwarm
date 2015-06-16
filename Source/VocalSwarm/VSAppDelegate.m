//
//  VSAppDelegate.m
//  VocalSwarm
//
//  Created by Alexey on 31.05.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSAppDelegate.h"
#import "VSSettingsNavigationController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <Parse/Parse.h>
#import "config.h"
#import "UserParseHelper.h"
#import <ooVooSDK-iOS/ooVooSDK-iOS.h>
@interface VSAppDelegate() <FlurryAdDelegate>
{
    UserParseHelper *userStart;
    BOOL transmitWasStoppedByResignActive;
}
@property (nonatomic,strong)  UserParseHelper *userStart;

@end

@implementation VSAppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:appIdparse
                  clientKey:appKeyparse];
    [PFFacebookUtils initializeFacebook];

//    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    //Set the status bar to black color.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    
    //Change @"menubar.png" to the file name of your image.
    UIImage *navBar = [UIImage imageNamed:@"yellow-title-bar.png"];
    UIImage *navBarLandscape = [UIImage imageNamed:@"yellow-title-bar-landscape.png"];
//    UIImage *navBarSettings = [UIImage imageNamed:@"settingsNavigationBar.png"];
    
//    [[UINavigationBar appearance] setBackgroundImage:navBar forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBar forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarLandscape forBarMetrics:UIBarMetricsLandscapePhone];

//    [[UINavigationBar appearanceWhenContainedIn:[VSSettingsNavigationController class], nil] setBackgroundImage:navBarSettings
//                                                                                                  forBarMetrics:UIBarMetricsDefault];
    
    [self settingQB];
    
    [self settingFlurry];
    
    if ([PFUser currentUser]) {
        PFQuery *usr = [UserParseHelper query];
        [usr whereKey:@"objectId" equalTo:[UserParseHelper currentUser].objectId];
        [usr findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.userStart = [UserParseHelper alloc];
            self.userStart = objects.firstObject;
            self.userStart.online = @"yes";
            [self.userStart saveEventually];
            
        }];
    }
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        // Register for Push Notifications before iOS 8
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // oovoo
        [ooVooController setLogLevel:[[NSNumber numberWithInt:ooVooDebug] integerValue]];
        ooVooInitResult result = [[ooVooController sharedController] initSdk:DEFAULT_APP_ID
                                                            applicationToken:DEFAULT_APP_TOKEN
                                                                     baseUrl:DEFAULT_BACK_END_URL];
//        if (result != ooVooInitResultOk)
//        {
//            NSLog(@"ooVoo SDK initialization failed with result %d", result);
//            
//            NSString *reason;
//            if (result == ooVooInitResultAppIdNotValid) {
//                reason = @"AppID invalid, might be empty.\n\nGet your App ID and App Token at http://developer.oovoo.com.\nGo to Settings->ooVooSample screen and set the values, or set @DEFAULT_APP_ID and @DEFAULT_APP_TOKEN constants in code.";
//            } else if(result == ooVooInitResultInvalidToken) {
//                reason = @"Token invalid, might be empty.\n\nGet your App ID and App Token at http://developer.oovoo.com.\nGo to Settings->ooVooSample screen and set the values, or set @DEFAULT_APP_ID and @DEFAULT_APP_TOKEN constants in code.";
//            } else {
//                reason = [[ooVooController sharedController] errorMessageForOoVooInitResult:result];
//            }
//            
//            double delayInSeconds = 0.75;
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                
//                [[[UIAlertView alloc] initWithTitle:@"Init ooVoo Sdk"
//                                            message:[NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), reason]
//                                           delegate:nil
//                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
//                                  otherButtonTitles:nil] show];
//            });
//        }
    });


    return YES;
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    //  Push notification received while the app is running
    [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    
    NSLog(@"Received notification: %@", userInfo);
    
    NSString *alertText = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    
    [[[UIAlertView alloc] initWithTitle:@"Vocal Swarm" message:alertText delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if ([ooVooController sharedController].transmitEnabled)
    {
        [ooVooController sharedController].transmitEnabled = NO;
        transmitWasStoppedByResignActive = YES;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (transmitWasStoppedByResignActive && [ooVooController sharedController].cameraEnabled)
    {
        // sends "Turned on camera" to other participants so they can resume displaying our video
        [ooVooController sharedController].transmitEnabled = YES;
        transmitWasStoppedByResignActive = NO;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [FBAppCall handleDidBecomeActive];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [FBSession.activeSession close];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
    
    NSUInteger orientations =UIInterfaceOrientationMaskAllButUpsideDown;
    if(self.window.rootViewController) {
        UIViewController *presentedViewController = [[(UINavigationController *)self.window.rootViewController viewControllers] lastObject];
        orientations = [presentedViewController supportedInterfaceOrientations];
    }
    return orientations;
}

- (void) settingQB {
    [QBApplication sharedApplication].applicationId = 2231;
    [QBConnection registerServiceKey:@"MCw5VQSAs9KV4hK"];
    [QBConnection registerServiceSecret:@"9SHxmb4S3QCG4cG"];
    [QBSettings setAccountKey:@"RKAP7SMJycKk8W4zJERD"];
    /*[QBSettings setApplicationID:2231];
    [QBSettings setAuthorizationKey:@"MCw5VQSAs9KV4hK"];
    [QBSettings setAuthorizationSecret:@"9SHxmb4S3QCG4cG"];
#ifndef DEBUG
    [QBSettings useProductionEnvironmentForPushNotifications:YES];
#endif*/
//    [QBSettings setServerChatDomain:@"chatvideu.quickblox.com"]; //TODO: for chat testing
}

- (void) settingFlurry {
//    [Flurry startSession:@"68WXDSX36FC5R6DG3TPN"];
//    [Flurry setDebugLogEnabled:YES];
//    [Flurry setLogLevel:FlurryLogLevelAll];
    [Flurry setBackgroundSessionEnabled:NO];
    [Flurry startSession:@"VTQJMHM7KVRDXZ984796"];
    [FlurryAds setAdDelegate:self];
//    [FlurryAds enableTestAds:YES];
    [FlurryAds initialize:self.window.rootViewController];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // attempt to extract a token from the url
    
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
                        // If there is an active session
                        if (FBSession.activeSession.isOpen) {
                            // Check the incoming link
                            [self handleAppLinkData:call.appLinkData];
                        } else if (call.accessTokenData) {
                            // If token data is passed in and there's
                            // no active session.
                            if ([self handleAppLinkToken:call.accessTokenData]) {
                                // Attempt to open the session using the
                                // cached token and if successful then
                                // check the incoming link
                                [self handleAppLinkData:call.appLinkData];
                            }
                        }
                    }];
}

#pragma mark - Helper methods

/**
 * Helper method for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

/*
 * Helper method to handle incoming request app link
 */
- (void) handleAppLinkData:(FBAppLinkData *)appLinkData {
    NSString *targetURLString = appLinkData.originalQueryParameters[@"target_url"];
    if (targetURLString) {
        NSURL *targetURL = [NSURL URLWithString:targetURLString];
        NSDictionary *targetParams = [self parseURLParams:[targetURL query]];
        NSString *ref = [targetParams valueForKey:@"ref"];
        // Check for the ref parameter to check if this is one of
        // our incoming news feed link, otherwise it can be an
        // an attribution link
        if ([ref isEqualToString:@"notif"]) {
            // Get the request id
//            NSString *requestIDParam = targetParams[@"request_ids"];
//            NSArray *requestIDs = [requestIDParam
//                                   componentsSeparatedByString:@","];
            
            // Get the request data from a Graph API call to the
            // request id endpoint
//            [self notificationGet:requestIDs[0]];
        }
    }
}

/*
 * Helper method to check incoming token data
 */
- (BOOL)handleAppLinkToken:(FBAccessTokenData *)appLinkToken {
    // Initialize a new blank session instance...
    FBSession *appLinkSession = [[FBSession alloc] initWithAppID:nil
                                                     permissions:nil
                                                 defaultAudience:FBSessionDefaultAudienceNone
                                                 urlSchemeSuffix:nil
                                              tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance] ];
    [FBSession setActiveSession:appLinkSession];
    // ... and open it from the App Link's Token.
    return [appLinkSession openFromAccessTokenData:appLinkToken
                                 completionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error) {
                                     // Log any errors
                                     if (error) {
                                         NSLog(@"Error using cached token to open a session: %@",
                                               error.localizedDescription);
                                     }
                                 }];
}

#pragma mark - Flurry here

- (void) spaceDidReceiveAd:(NSString*)adSpace
{
	// Show the ad if desired
    NSLog(@"flurry %@ %@", NSStringFromSelector(_cmd), adSpace);
//    [FlurryAds displayAdForSpace:[self myAdSpace] onView:[self view]];
}

- (void) spaceDidFailToReceiveAd:(NSString*)adSpace error:(NSError *)error
{
    NSLog(@"flurry %@ %@ %@", NSStringFromSelector(_cmd), adSpace, error);
	// Handle failure to receive ad
}

- (BOOL) spaceShouldDisplay:(NSString*)adSpace interstitial:(BOOL)interstitial
{
    NSLog(@"flurry %@ %@ %@", NSStringFromSelector(_cmd), adSpace, (interstitial ? @"true" : @"false"));
	// Decide if the Ad should be displayed
	return true;
}

- (void) spaceDidFailToRender:(NSString *)space error:(NSError *)error
{
    NSLog(@"flurry %@ %@ %@", NSStringFromSelector(_cmd), space, error);
	// Handle a failure to render the ad
}

- (void)spaceWillDismiss:(NSString *)adSpace
{
    NSLog(@"flurry %@ %@", NSStringFromSelector(_cmd), adSpace);
	// Handle the user dismissing the ad
}

- (void)spaceDidDismiss:(NSString *)adSpace
{
    NSLog(@"flurry %@ %@", NSStringFromSelector(_cmd), adSpace);
	// Handle the closing of the ad
}

- (void)spaceWillLeaveApplication:(NSString *)adSpace
{
    NSLog(@"flurry %@ %@", NSStringFromSelector(_cmd), adSpace);
	// Handle the user leaving the application
}

- (BOOL) isFirstLaunch
{
    NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
    id isFirstLaunch = [userDefs objectForKey:@"kIsFirstLaunch"];
    return (isFirstLaunch == nil);
}

- (void) setupFirstLaunch
{
    NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
    [userDefs setObject:[NSNumber numberWithBool:NO] forKey:@"kIsFirstLaunch"];
    [userDefs synchronize];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    
#if (TARGET_IPHONE_SIMULATOR)
    
#else
    NSLog(@"updating pf installation");
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation.channels = @[@"global"];
    [currentInstallation saveInBackground];
    NSLog(@"finish");
#endif
    
    
    
}

@end
