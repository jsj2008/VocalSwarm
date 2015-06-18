//
//  VSLoginViewController.m
//  VocalSwarm
//
//  Created by Alexey on 03.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSLoginViewController.h"

#import "VSSettingsModel.h"
#import "VSPrivateSwarm.h"
#import "VSAppDelegate.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "config.h"
#import "AFNetworking.h"
#import "AFURLResponseSerialization.h"
#import <Parse/Parse.h>
@interface VSLoginViewController () <QBActionStatusDelegate>

- (IBAction)facebookAction;

@property (weak, nonatomic) IBOutlet UIView *activityContainer;
@property (weak, nonatomic) IBOutlet UILabel *syncLabel;

@property (nonatomic) BOOL sessionCreationProccess;

@property (nonatomic) BOOL isFacebookLogin;

@end

@implementation VSLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sessionCreationProccess = YES;
    [QBAuth createSessionWithDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutAction) name:kLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoading) name:QuickbloxSocialDialogDidCloseNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	[self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) logoutAction
{
    [Flurry logEvent:@"User Logged Out"];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    NSMutableArray *cookiesArray = [NSMutableArray array];
    
    for (NSHTTPCookie *cookie in [storage cookies]) {
        NSString* domainName = [cookie domain];
        NSRange domainRange = [domainName rangeOfString:@"twitter"];
        if(domainRange.length > 0){
            [cookiesArray addObject:cookie];
        }
        domainRange = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0){
            [cookiesArray addObject:cookie];
        }
    }
    
    for (NSHTTPCookie *cookie in cookiesArray) {
        [storage deleteCookie:cookie];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showLoading {
    [self.activityContainer setHidden:NO];
}

- (void)hideLoading {
    [self.activityContainer setHidden:YES];
}

- (IBAction)facebookAction {
    
    [self showLoading];
    
    [PFFacebookUtils logInWithPermissions:@[@"publish_actions"] block:^(PFUser *user, NSError *error)
     {
         if (user != nil)
         {
             if (user[PF_USER_FACEBOOKID] == nil)
             {
                 [self requestFacebook:user];
             }
             else [self userLoggedIn:user];
         }
         else {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook Login Fail Error!" message:@"Facebook login is failed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
             [alertView show];
             [self hideLoading];
         }
     }];
    
//    if (!self.sessionCreationProccess) {
//        self.isFacebookLogin = YES;
//        [QBUsers logInWithSocialProvider:@"facebook"
//                                   scope:@[@"publish_actions"]
//                                delegate:self];
//    } else {
//        [self performSelector:_cmd
//                   withObject:nil
//                   afterDelay:3];
//    }
}

- (void)requestFacebook:(PFUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             user[@"first_name"] = userData[@"first_name"];
             user[@"gender"] = userData[@"gender"];
             user[@"facebookID"] = userData[@"id"];
             user[@"last_name"] = userData[@"last_name"];
             user[@"username"] = userData[@"name"];
             user[PF_USER_FACEBOOKID] = userData[@"id"];
             [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
              {
                  if (error == nil)
                  {
                      [self userLoggedIn:user];
                  }
                  else
                  {
                      [PFUser logOut];
                  }
              }];
         }
         else
         {
             [PFUser logOut];
         }
     }];
}

- (void)userLoggedIn:(PFUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    [self synchronizationHide];
    if ([(VSAppDelegate *)[[UIApplication sharedApplication] delegate] isFirstLaunch]) {
        [self performSegueWithIdentifier:@"FirstLaunchSegue" sender:self];
    } else {
        NSMutableArray *favoriteSportsArray = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_SPORTS];
        NSMutableArray *favoriteTeamsArray = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_TEAMS];
        if(!favoriteTeamsArray || !favoriteSportsArray) {
            [self performSegueWithIdentifier:@"SettingPageSegue" sender:self];
        }else{
            if(favoriteSportsArray.count > 0 && favoriteTeamsArray.count > 0) {
                [self performSegueWithIdentifier:@"LoginSegue" sender:self];
            }else{
                [self performSegueWithIdentifier:@"SettingPageSegue" sender:self];
            }
        }
    }
    [Flurry setUserID:[NSString stringWithFormat:@"%@", [VSSettingsModel currentUser].facebookID]];
    
//    [QBMessages TRegisterSubscriptionWithDelegate:self];
    
    [Flurry logEvent:@"User Logged In"];
}

- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    NSString *link = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
//         UIImage *image = (UIImage *)responseObject;
//         //-----------------------------------------------------------------------------------------------------------------------------------------
//         //-----------------------------------------------------------------------------------------------------------------------------------------
//         PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(image, 0.9)];
//         [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
//          {
//          }];
//         //-----------------------------------------------------------------------------------------------------------------------------------------
//         //-----------------------------------------------------------------------------------------------------------------------------------------
//         PFFile *fileThumbnail = [PFFile fileWithName:@"thumbnail.jpg" data:UIImageJPEGRepresentation(image, 0.9)];
//         [fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
//          {
//          }];
//         //-----------------------------------------------------------------------------------------------------------------------------------------
//         NSLog(@"UDATE - %@",userData);
         
         user[@"first_name"] = userData[@"first_name"];
         user[@"gender"] = userData[@"gender"];
         user[@"facebookID"] = userData[@"id"];
         user[@"last_name"] = userData[@"last_name"];
         user[@"username"] = userData[@"name"];
         
//         user[@"username"] = userData[@"id"];
//         //user[@"password"] = userData[@"id"];
//         user[@"nickname"] = userData[@"first_name"];
//         user[@"distance"] = [NSNumber numberWithInt:100];
//         user[@"sexuality"] = [NSNumber numberWithInt:2];
//         user[@"age"] = [NSNumber numberWithInt:30];
//         user[@"isMale"] = @"true";
//         user[@"desc"] = @"Hi all))) I am now with you !!!";
//         user[@"photo"] = filePicture;
         user[PF_USER_FACEBOOKID] = userData[@"id"];
         //  user[PF_USER_FULLNAME] = userData[@"name"];
         // user[PF_USER_FULLNAME_LOWER] = [userData[@"name"] lowercaseString];
         // user[PF_USER_FACEBOOKID] = userData[@"id"];
         // user[PF_USER_PICTURE] = filePicture;
//         user[@"photo_thumb"] = fileThumbnail;
         [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
          {
              if (error == nil)
              {
                  //  [self dismissViewControllerAnimated:YES completion:nil];
                  [self userLoggedIn:user];
                  //  _startScreen =[[MainViewController alloc]initWithNibName:@"Main" bundle:nil];
                  // [self presentViewController:_startScreen animated:YES completion:nil];
              }
              else
              {
                  [PFUser logOut];
              }
          }];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [PFUser logOut];
     }];
    //-----------------------------------------------------------------------------------------------------------------------------------------
    [[NSOperationQueue mainQueue] addOperation:operation];
}

- (void) afterLogin:(BOOL) isFirstLogin {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"isFirstLogin %@", (isFirstLogin ? @"true" : @"false"));
    
    [self synchronizationHide];
    
    if ([(VSAppDelegate *)[[UIApplication sharedApplication] delegate] isFirstLaunch]) {
        [self performSegueWithIdentifier:@"FirstLaunchSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    }
    
    [Flurry setUserID:[NSString stringWithFormat:@"%@", [VSSettingsModel currentUser].facebookID]];
    
    [QBMessages TRegisterSubscriptionWithDelegate:self];
    
    [Flurry logEvent:@"User Logged In"];
}

- (void) synchronizationShow {
    [self.activityContainer setHidden:NO];
    [self.syncLabel setHidden:NO];
}

- (void) synchronizationHide {
    [self.activityContainer setHidden:YES];
    [self.syncLabel setHidden:YES];
}

- (void) tryRecreateSession:(NSInteger) tryCount {
    if (tryCount == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "")
                                                        message:@"Error login"
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", "")
                                              otherButtonTitles:nil];
        [alert show];
        
        [self hideLoading];
        
        return;
    }
    
    [self showLoading];
    
    [[QBBaseModule sharedModule] setToken:nil];
    [QBAuth createSessionWithDelegate:self context:(__bridge void *)([NSNumber numberWithInteger:tryCount])];
}

#pragma mark - QBDelegate

- (void)completedWithResult:(Result*)result {
    // QuickBlox application authorization result
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        
        // Success result
        if(result.success) {
            
            // show Errors
        } else {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "")
//                                                            message:[result.errors description]
//                                                           delegate:nil
//                                                  cancelButtonTitle:NSLocalizedString(@"OK", "")
//                                                  otherButtonTitles:nil];
//            [alert show];
        }
        self.sessionCreationProccess = NO;
    }
    
    // QuickBlox User authenticate result
    if ([result isKindOfClass:[QBUUserLogInResult class]]) {
        [self hideLoading];
		
        // Success result
        if (result.success) {
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            if (res.user && res.user.facebookID && [res.user.facebookID length]) {
                NSLog(@"socialProviderToken %@", [res socialProviderToken]);
                NSLog(@"socialProviderTokenExpiresAt %@", [res socialProviderTokenExpiresAt]);
                
                NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
                [userDefs setObject:[res socialProviderToken] forKey:@"socialProviderToken"];
                [userDefs setObject:[res socialProviderTokenExpiresAt] forKey:@"socialProviderTokenExpiresAt"];
                [userDefs synchronize];
                
                // save current user
                [VSSettingsModel setCurrentUser:res.user];
                
                [self synchronizationShow];
                
                [VSSettingsModel synchronizeAlltoServer:NO
                                               finished:^(QBCOCustomObject *co) {
                                                   NSLog(@"after synchronization %@", co);
                                                   [self afterLogin:[[[res user] createdAt] isEqualToDate:[[res user] updatedAt]]];
                                               }];
            } else {
                [self tryRecreateSession:3];
            }
        } else {
            [self tryRecreateSession:3];
        }
    }
    
    if ([result isKindOfClass:[QBMRegisterSubscriptionTaskResult class]]) {
        NSLog(@"QBMRegisterSubscriptionTaskResult errors %@", result.errors);
    }
}

-(void)completedWithResult:(Result*)result context:(void*)contextInfo {
    NSInteger tryCount = [(__bridge NSNumber *)contextInfo integerValue];
    
    if ([result isKindOfClass:[QBAAuthSessionCreationResult class]]) {
        if (result.success) {
            if (self.isFacebookLogin) {
                [QBUsers logInWithSocialProvider:@"facebook"
                                           scope:@[@"publish_actions"]
                                        delegate:self
                                         context:contextInfo];
            } else {
                [QBUsers logInWithSocialProvider:@"twitter"
                                           scope:nil
                                        delegate:self
                                         context:contextInfo];
            }
        } else {
            tryCount--;
            [self tryRecreateSession:tryCount];
        }
    }
    
    // QuickBlox User authenticate result
    if ([result isKindOfClass:[QBUUserLogInResult class]]) {
        [self hideLoading];
		
        // Success result
        if (result.success) {
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            
            if (res.user && res.user.facebookID && [res.user.facebookID length]) {
                NSLog(@"socialProviderToken %@", [res socialProviderToken]);
                NSLog(@"socialProviderTokenExpiresAt %@", [res socialProviderTokenExpiresAt]);
                
                NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
                [userDefs setObject:[res socialProviderToken] forKey:@"socialProviderToken"];
                [userDefs setObject:[res socialProviderTokenExpiresAt] forKey:@"socialProviderTokenExpiresAt"];
                [userDefs synchronize];
                
                // save current user
                [VSSettingsModel setCurrentUser:res.user];
                
                [self synchronizationShow];
                
                [VSSettingsModel synchronizeAlltoServer:NO
                                               finished:^(QBCOCustomObject *co) {
                                                   NSLog(@"after synchronization %@", co);
                                                   [self afterLogin:[[[res user] createdAt] isEqualToDate:[[res user] updatedAt]]];
                                               }];
            } else {
                tryCount--;
                [self tryRecreateSession:tryCount];
            }
        } else {
            tryCount--;
            [self tryRecreateSession:tryCount];
        }
    }
}


@end
