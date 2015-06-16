//
//  VSScheduleSwarm3ViewController.m
//  VocalSwarm
//
//  Created by Alexey on 13.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSScheduleSwarm3ViewController.h"
#import "VSSwarm.h"
#import "VSGame.h"
#import "VSNetworkChalk.h"
#import "VSSwarmsModel.h"
#import "VSSettingsModel.h"
#import "VSTabBarViewController.h"
#import "VSSwarmSelectionViewController.h"

@interface VSScheduleSwarm3ViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *activityContainer;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (strong, nonatomic) NSMutableArray *data;

@property (strong, nonatomic) VSSwarm *swarm;

- (IBAction)backAction;

@end

@implementation VSScheduleSwarm3ViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _firstTeam = nil;
        _data = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setHidden:YES];
//    [self.headerView setHidden:YES];
    [self.headerLabel setHidden:YES];
    
    [self updateData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) updateData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.data removeAllObjects];
        
        [[VSNetworkChalk sharedInstance] upcomingGamesForTeam:self.firstTeam
                                                       result:^(NSArray *gamesArray) {
                                                           [self.data addObjectsFromArray:gamesArray];
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               [self.tableView reloadData];
                                                               [self finishUpdate];
                                                           });
                                                       }];
    });
}

- (void) finishUpdate {
    [self.activityContainer setHidden:YES];
    [self.tableView setHidden:NO];
    if ([self.data count] == 0) {
        UIAlertView *emptyAlert = [[UIAlertView alloc] initWithTitle:nil
                                                             message:[NSString stringWithFormat:@"There are no upcoming games available for %@ %@ team.", [self.firstTeam teamName], [self.firstTeam teamNickname]]
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
        emptyAlert.tag = 125;
        [emptyAlert show];
    } else {
        [self.headerLabel setHidden:NO];
    }
}

- (IBAction)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 125) {
        [self backAction];
    } else {
        [self.activityContainer setHidden:YES];
        if (buttonIndex == [alertView cancelButtonIndex]) { //Yes button -
            [self performSegueWithIdentifier:@"selectSwarmTypeSegue" sender:self.swarm];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

static NSString *scheduleVSTeamCellIdentifier = @"scheduleVSTeamCellIdentifier";


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleVSTeamCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:scheduleVSTeamCellIdentifier];
    }
    
    UIView *titleLabel = [cell viewWithTag:13001];
    if ([titleLabel isKindOfClass:[UILabel class]]) {
        VSGame *game = [self.data objectAtIndex:[indexPath row]];
//        VSTeam *myTeam = self.firstTeam;
        VSTeam *myTeam = [game homeTeam];
        VSTeam *opponentTeam = [game awayTeam];
//        VSTeam *opponentTeam = nil;
//        if ([[game homeTeam] isEqual:self.firstTeam]) {
//            opponentTeam = [game awayTeam];
//        } else {
//            opponentTeam = [game homeTeam];
//        }
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"eee MM/dd h:mma 'est'"];
        [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [df setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
        [df setAMSymbol:@"am"];
        [df setPMSymbol:@"pm"];
        NSString *gameFormattedDate = [df stringFromDate:[game gameDate]];
        
        NSString *titleString = [NSString stringWithFormat:@"%@ VS %@ %@", [myTeam teamNickname], [opponentTeam teamNickname], gameFormattedDate];
        
        [(UILabel*)titleLabel setText:titleString];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleVSTeamCellIdentifier];
    
    return cell.bounds.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.activityContainer setHidden:NO];
    
    VSGame* game = [self.data objectAtIndex:[indexPath row]];

    VSSwarm *swarm = [[VSSwarm alloc] init];
    [swarm setGame:game];
    [swarm setSportLeague:[[self.firstTeam sportLeague] shortCode]];
    if ([self.firstTeam isEqual:[game homeTeam]]) {
        [swarm setIsMyHomeTeam:YES];
    } else {
        [swarm setIsMyHomeTeam:NO];
    }
    self.swarm = swarm;
    
    [[VSSwarmsModel sharedInstance] findSwarms:swarm forUser:[VSSettingsModel currentUser].facebookID result:^(NSArray *swarms) {
        if (swarms && [swarms count] > 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"You are already scheduled to a swarm for this game. Do you want to delete the previous swarm and join this instead?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Yes"
                                                  otherButtonTitles:@"No", nil];
            alert.tag = 126;
            [alert show];
        } else {
            [self.activityContainer setHidden:YES];
            [self performSegueWithIdentifier:@"selectSwarmTypeSegue" sender:swarm];
        }
    }];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"selectSwarmTypeSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[VSSwarmSelectionViewController class]]) {
            VSSwarmSelectionViewController *desvVC = segue.destinationViewController;
            [desvVC setSwarm:sender];
        }
    }
}

@end
