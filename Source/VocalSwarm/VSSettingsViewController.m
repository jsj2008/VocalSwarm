//
//  VSSettingsViewController.m
//  VocalSwarm
//
//  Created by Alexey on 03.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsViewController.h"
#import "VSSettingsAddingViewController.h"

#import "VSSettingsModel.h"
#import "VSTeam.h"

#import "VSAppDelegate.h"

#import "UIView+FindSubview.h"
#import <Parse/Parse.h>
#import "config.h"

@interface VSSettingsViewController () <UITableViewDataSource, UITableViewDelegate, QBActionStatusDelegate>

@property (nonatomic, strong) NSString* sessionToken;
@property (nonatomic, strong) NSString* facebookId;
@property (nonatomic, strong) NSString* twitterId;

- (IBAction)homeAction;
- (IBAction)logoutAction;

@property (weak, nonatomic) IBOutlet UITableView *mainSettingsTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mainSettingsActivityIndicator;

@property (strong, nonatomic) NSMutableArray *dataFavoritesSports;
@property (strong, nonatomic) NSMutableArray *dataFavoritesTeams;

@property (strong, nonatomic) NSObject* removeTarget;

@property (nonatomic) BOOL isFacebookLogin;

- (IBAction)twitterLoginAction;
- (IBAction)facebookLoginAction;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation VSSettingsViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dataFavoritesSports = [NSMutableArray array];
        _dataFavoritesTeams = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [(VSAppDelegate *)[[UIApplication sharedApplication] delegate] setupFirstLaunch];
    
    self.versionLabel.text = [NSString stringWithFormat:@"software version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)homeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)logoutAction {
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:nil];
    
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateFavorites];
    [Flurry logEvent:@"Settings Opened"];
}

- (void) updateFavorites {
//    [self.dataFavoritesSports removeAllObjects];
    self.dataFavoritesSports = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_SPORTS];
    NSLog(@"%d", self.dataFavoritesSports.count);
    if(!self.dataFavoritesSports) {
        self.dataFavoritesSports = [NSMutableArray array];
    }
//    [self.dataFavoritesSports addObjectsFromArray:[VSSettingsModel getFavoriteSports]];
    
//    [self.dataFavoritesTeams removeAllObjects];
//    [self.dataFavoritesTeams addObjectsFromArray:[VSSettingsModel getFavoriteTeams]];
    self.dataFavoritesTeams = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_TEAMS];
    if(!self.dataFavoritesTeams) {
        self.dataFavoritesTeams = [NSMutableArray array];
    }
    NSLog(@"%d", self.dataFavoritesTeams.count);
    [self.mainSettingsTableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataFavoritesSports count] + [self.dataFavoritesTeams count] + 4;
//    return [self.dataFavoritesSports count] + [self.dataFavoritesTeams count] + 6;
}

static NSString *existingCellIdentifier = @"SportTeamCell";
static NSString *newCellIdentifier = @"AddSportTeamCell";
static NSString *headerCellIdentifier = @"settingsHeaderCellIdentifier";
//static NSString *socialCellIdentifier = @"SocialCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    if ([indexPath row] == 0 ||
        [indexPath row] == [self.dataFavoritesSports count] + 2) {
//    if ([indexPath row] == 0 ||
//        [indexPath row] == 2 ||
//        [indexPath row] == [self.dataFavoritesSports count] + 4) {
        cell = [tableView dequeueReusableCellWithIdentifier:headerCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:headerCellIdentifier];
        }
    
        UIView *titleLabel = [cell viewWithTag:14000];
        if ([titleLabel isKindOfClass:[UILabel class]]) {
            if ([indexPath row] == 0) {
                [(UILabel*)titleLabel setText:@"Favorite Sports"];
            } else {
                [(UILabel*)titleLabel setText:@"Favorite Teams"];
            }
//            if ([indexPath row] == 0) {
//                [(UILabel*)titleLabel setText:@"Social Networks"];
//            } else if ([indexPath row] == 2) {
//                [(UILabel*)titleLabel setText:@"Favorite Sports"];
//            } else {
//                [(UILabel*)titleLabel setText:@"Favorite Teams"];
//            }
        }
        
        return cell;
    }
    
//    if ([indexPath row] == 1) {
//        cell = [tableView dequeueReusableCellWithIdentifier:socialCellIdentifier];
//        
//        if (cell == nil) {
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:headerCellIdentifier];
//        }
//        
//        return cell;
//    }

    if ([indexPath row] == [self.dataFavoritesSports count] + 1 || [indexPath row] == [self.dataFavoritesSports count] + [self.dataFavoritesTeams count] + 3) {
//    if ([indexPath row] == [self.dataFavoritesSports count] + 3 || [indexPath row] == [self.dataFavoritesSports count] + [self.dataFavoritesTeams count] + 5) {
        //add new cell sport / team
        cell = [tableView dequeueReusableCellWithIdentifier:newCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCellIdentifier];
        }
        
        NSString *titleText = nil;
        SEL addSelector = nil;
        if ([indexPath row] == [self.dataFavoritesSports count] + 1) {
//        if ([indexPath row] == [self.dataFavoritesSports count] + 3) {
            titleText = @"Add a sport";
            addSelector = @selector(addSportAction:);
        } else {
            titleText = @"Add a team";
            addSelector = @selector(addTeamAction:);
        }
        UIView* subView = [cell viewWithTag:15];
        if ([subView isKindOfClass:[UILabel class]]) {
            [(UILabel*)subView  setText:titleText];
        }
        UIView* addButton = [cell viewWithTag:16];
        if ([addButton isKindOfClass:[UIButton class]]) {
            [(UIButton*)addButton addTarget:self
                                     action:addSelector
                           forControlEvents:UIControlEventTouchUpInside];
        }
        
        return cell;
    }
    
    NSInteger correctedIndex = 0;
    if ([indexPath row] < [self.dataFavoritesSports count] + 1) {
        correctedIndex = [indexPath row] - 1;
//    if ([indexPath row] < [self.dataFavoritesSports count] + 3) {
//        correctedIndex = [indexPath row] - 3;
    } else {
        correctedIndex = [indexPath row] - [self.dataFavoritesSports count] - 3;
//        correctedIndex = [indexPath row] - [self.dataFavoritesSports count] - 5;
    }
    
    //existing sport / team
    cell = [tableView dequeueReusableCellWithIdentifier:existingCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:existingCellIdentifier];
    }
    
    NSString *titleText = nil;
    SEL removeSelector = nil;
    NSInteger removeTag = correctedIndex;

    if ([indexPath row] < [self.dataFavoritesSports count] + 1) {
//    if ([indexPath row] < [self.dataFavoritesSports count] + 3) {
        removeSelector = @selector(removeSportAction:);
        NSArray *leagueArray = (NSArray *)[self.dataFavoritesSports objectAtIndex:correctedIndex];
        VSSportLeague* sport = [[VSSportLeague alloc] initWithSport:[leagueArray objectAtIndex:0] league:[leagueArray objectAtIndex:1]];
//        VSSportLeague* sport = (VSSportLeague*)[self.dataFavoritesSports objectAtIndex:correctedIndex];
        titleText = [NSString stringWithFormat:@"%@ %@", [sport leagueAbbr], [sport sportName]];
    } else {
        removeSelector = @selector(removeTeamAction:);
        NSArray *teamArray = (NSArray *)[self.dataFavoritesTeams objectAtIndex:correctedIndex];
        VSSportLeague *sportLeague = [[VSSportLeague alloc] initWithSport:[teamArray objectAtIndex:0] league:[teamArray objectAtIndex:1]];
        VSTeam *team = [[VSTeam alloc] initWithSportLeague:sportLeague];
        [team setTeamId:[[teamArray objectAtIndex:2] integerValue]];
        [team setTeamName:[teamArray objectAtIndex:3]];
        [team setTeamNickname:[teamArray objectAtIndex:4]];
        titleText = [NSString stringWithFormat:@"%@ %@", [team teamName], [team teamNickname]];
    }
    
    UIView* subView = [cell viewWithTag:14000];
    if ([subView isKindOfClass:[UILabel class]]) {
        [(UILabel*)subView  setText:titleText];
    }
    UIView* button = [cell findSubviewOfClass:[UIButton class]];
    if ([button isKindOfClass:[UIButton class]]) {
        [(UIButton*)button setTag:removeTag];
        [(UIButton*)button addTarget:self
                              action:removeSelector
                    forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == 0 ||
        [indexPath row] == [self.dataFavoritesSports count] + 2) {
//    if ([indexPath row] == 0 ||
//        [indexPath row] == 2 ||
//        [indexPath row] == [self.dataFavoritesSports count] + 4) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:headerCellIdentifier];
        return cell.bounds.size.height;
    }
//    else if ([indexPath row] == 1) {
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:socialCellIdentifier];
//        return cell.bounds.size.height;
//    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:existingCellIdentifier];
        if (cell == nil) {
            cell = [tableView dequeueReusableCellWithIdentifier:newCellIdentifier];
        }
        return cell.bounds.size.height;
    }
}

- (void)addTeamAction:(id) sender {
    [self performSegueWithIdentifier: @"SettingsAddTeamSegue" sender: sender];
}

- (void)addSportAction:(id) sender {
    [self performSegueWithIdentifier: @"SettingsAddSportSegue" sender: sender];
}

- (void)removeTeamAction:(id) sender {
    //TODO CRASH HERE AFTER ADDING NEW ITEM (tested on team)
    UIButton* senderButton = (UIButton*)sender;
    NSArray* teamForRemoveArray = [self.dataFavoritesTeams objectAtIndex:[senderButton tag]];
//    VSTeam* teamForRemove = [self.dataFavoritesTeams objectAtIndex:[senderButton tag]];
    self.removeTarget = senderButton;
    
//    NSString *alertMessage = [NSString stringWithFormat:@"Are you sure want to delete %@ %@ from favorite teams?", [[[teamForRemove objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"location"], [[[teamForRemove objectForKey:@"teams"] objectAtIndex:0] objectForKey:@"name"]];
    NSString *alertMessage = [NSString stringWithFormat:@"Are you sure want to delete %@ %@ from favorite teams?", [teamForRemoveArray objectAtIndex:3], [teamForRemoveArray objectAtIndex:4]];
    
    UIAlertView *confirmAlert = [[UIAlertView alloc] initWithTitle:nil
                                                          message:alertMessage
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Ok", nil];
    confirmAlert.tag = 101;
    [confirmAlert show];
}

- (void)removeSportAction:(id) sender {
    UIButton* senderButton = (UIButton*)sender;
    NSArray* sportForRemoveArray = [self.dataFavoritesSports objectAtIndex:[senderButton tag]];
    
    self.removeTarget = senderButton;
    
    NSString *alertMessage = [NSString stringWithFormat:@"Are you sure want to delete %@ %@ from favorite sports?", [sportForRemoveArray objectAtIndex:0], [sportForRemoveArray objectAtIndex:1]];
    
    UIAlertView *confirmAlert = [[UIAlertView alloc] initWithTitle:nil
                                                           message:alertMessage
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"Ok", nil];
    confirmAlert.tag = 100;
    [confirmAlert show];
}

#pragma mark - UIAlertViewController

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
        if (alertView.tag == 101) {
            UIButton *senderBtn = (UIButton *)self.removeTarget;
            [self.dataFavoritesTeams removeObjectAtIndex:senderBtn.tag];
            [[PFUser currentUser] setObject:self.dataFavoritesTeams forKey:PARSE_FAVORITE_TEAMS];
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [Flurry logEvent:@"Favorite Team Removed"];
                [VSSettingsModel synchronizeAlltoServer:YES
                                               finished:nil];
                
                self.removeTarget = nil;
                [self updateFavorites];
            }];
//            [VSSettingsModel removeFavoriteTeam:(VSTeam*)self.removeTarget];
        } else if (alertView.tag == 100) {
            UIButton *senderBtn = (UIButton *)self.removeTarget;
            [self.dataFavoritesSports removeObjectAtIndex:[senderBtn tag]];
            [[PFUser currentUser] setObject:self.dataFavoritesSports forKey:PARSE_FAVORITE_SPORTS];
//            [VSSettingsModel removeFavoriteSport:(VSSportLeague*)self.removeTarget];
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [VSSettingsModel synchronizeAlltoServer:YES
                                               finished:nil];
                
                self.removeTarget = nil;
                [self updateFavorites];
            }];
        }
    }
}

#pragma mark - Login

- (IBAction)twitterLoginAction {
    NSLog(@"---------TOKEN %@ ------------", [[QBBaseModule sharedModule] token]);
    [self setSessionToken:[[QBBaseModule sharedModule] token]];
    [self setIsFacebookLogin:NO];
    
    [[QBBaseModule sharedModule] setToken:nil];
    
    [QBAuth createSessionWithDelegate:self];
}

- (IBAction)facebookLoginAction {
    NSLog(@"---------TOKEN %@ ------------", [[QBBaseModule sharedModule] token]);
    [self setSessionToken:[[QBBaseModule sharedModule] token]];
    [self setIsFacebookLogin:YES];
    
    [[QBBaseModule sharedModule] setToken:nil];

    [QBAuth createSessionWithDelegate:self];
}

- (void) updateUser {
    QBUUser *user = [VSSettingsModel currentUser];
    
    [[QBBaseModule sharedModule] setToken:self.sessionToken];
    
    NSLog(@"---------TOKEN %@ ------------", [[QBBaseModule sharedModule] token]);
    
    [QBUsers updateUser:user delegate:self];
    
    [Flurry logEvent:@"User Logged In With Twitter"];
}

#pragma mark - QBDelegate

- (void)completedWithResult:(Result*)result {
    // QuickBlox User authenticate result
    
    if([result isKindOfClass:[QBUUserLogInResult class]]) {
//        [self hideLoading];
		
        // Success result
        if(result.success) {
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            
            if ([VSSettingsModel currentUser].ID == res.user.ID)
                return;
            
            [self setTwitterId:[res.user twitterID]];
            [self setFacebookId:[res.user facebookID]];
            
            [QBUsers deleteUserWithID:res.user.ID delegate:self];
            
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errors"
                                                            message:[result.errors description]
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles: nil];
            alert.tag = 1;
            [alert show];
        }
    } else if([result isKindOfClass:[QBUUserResult class]]) {
        QBUUserResult *res = (QBUUserResult *)result;
        NSLog(@"%@ %@", res, [res user]);
        
        if ([res user] == nil) { //after delete
            QBUUser *user = [VSSettingsModel currentUser];
            
            if (self.twitterId) {
                [user setTwitterID:self.twitterId];
            }
            if (self.facebookId) {
                [user setFacebookID:self.facebookId];
            }
            
            [VSSettingsModel setCurrentUser:user];
            
            [self performSelector:@selector(updateUser) withObject:nil afterDelay:0.1];
        } else { //after update
            NSLog(@"gawdfawf");
        }
    }
    
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]) {
        // Success result
        if (result.success) {
            if ([self isFacebookLogin]) {
                [QBUsers logInWithSocialProvider:@"facebook"
                                           scope:nil
                                        delegate:self];
            } else {
                [QBUsers logInWithSocialProvider:@"twitter"
                                           scope:nil
                                        delegate:self];
            }
            
            // show Errors
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "")
                                                            message:[result.errors description]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", "")
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

@end
