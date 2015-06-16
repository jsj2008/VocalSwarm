//
//  VSScheduleSwarm2ViewController.m
//  VocalSwarm
//
//  Created by Alexey on 13.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSScheduleSwarm2ViewController.h"
#import "VSSettingsModel.h"
//#import "VSNetworkESPN.h"
#import "VSNetworkChalk.h"
#import "VSTeam.h"
#import "VSScheduleSwarm3ViewController.h"

@interface VSScheduleSwarm2ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong)  NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;

- (IBAction)backAction;

@end

@implementation VSScheduleSwarm2ViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dataSourceName = nil;
        _data = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setHidden:YES];
//    [self.titleView setHidden:YES];
    [self.headerLabel setHidden:YES];
    [self.emptyLabel setHidden:YES];
    
    [self updateData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) finishUpdate {
    if ([self.data count] == 0) {
        [self.emptyLabel setHidden:NO];
    } else {
        [self.tableView setHidden:NO];
//        [self.titleView setHidden:NO];
        [self.headerLabel setHidden:NO];
    }
    
    [self.activityIndicator setHidden:YES];
}

- (void) updateData {
    self.data = [NSArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if ([self ifFavoriteTeams]) {
            self.data = [NSArray arrayWithArray:[VSSettingsModel getFavoriteTeams]];
//            [self.data addObjectsFromArray:[VSSettingsModel getFavoriteTeams]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self finishUpdate];
            });
        } else {
            VSNetworkChalk* networkInstance = [VSNetworkChalk sharedInstance];
            
            NSMutableArray *leagueForLoad = [NSMutableArray arrayWithArray:[networkInstance leaguesForSport:[VSNetworkChalk sport:self.dataSourceName]]];
            
            [self loadLeaguesData:leagueForLoad resultArray:[NSMutableArray array] result:^(NSMutableArray *result) {
                self.data = [NSArray arrayWithArray:result];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self finishUpdate];
                });
            }];
        }
    });
}

- (void) loadLeaguesData:(NSMutableArray *)leaguesForLoad resultArray:(NSMutableArray*)resultArray result:(void (^)(NSMutableArray* result))finished {
    if ([leaguesForLoad count] == 0) {
        finished(resultArray);
    } else {
        NSString *league = [leaguesForLoad lastObject];
        [leaguesForLoad removeLastObject];
        
        NSArray *teamsArray = [[VSNetworkChalk sharedInstance] prebuildedTeamsForSportLeague:[[VSSportLeague alloc] initWithSport:self.dataSourceName league:league]];
        
        [resultArray insertObject:@{@"league" : league, @"teams" : [self sortTeamsByName:teamsArray]}
                          atIndex:0];
        [self loadLeaguesData:leaguesForLoad resultArray:resultArray result:finished];
    }
}

- (NSArray *)sortTeamsByName:(NSArray *) teams
{
    NSSortDescriptor *teamNameDescriptor = [NSSortDescriptor
                                        sortDescriptorWithKey:@"teamName"
                                        ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:teamNameDescriptor];
    return [teams sortedArrayUsingDescriptors:sortDescriptors];
}

- (BOOL) ifFavoriteTeams {
    return [self.dataSourceName isEqualToString:@"favorite teams"];
}

- (IBAction)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Segue

static NSString *selectVSSegueIdentifier = @"swarmScheduleSelectVSTeamSegue";

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:selectVSSegueIdentifier]) {
        VSScheduleSwarm3ViewController *schedule3VC = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        VSTeam *team = nil;
        if ([self ifFavoriteTeams]) {
            team = [self.data objectAtIndex:[indexPath row]];
            [Flurry logEvent:@"Create swarm For Favorite Teams"];
        } else {
            team = [[[self.data  objectAtIndex:[indexPath section]] objectForKey:@"teams"] objectAtIndex:[indexPath row]];
            [Flurry logEvent:@"Create swarm For Sport" withParameters:@{@"Sport Name" : self.dataSourceName}];
        }
        schedule3VC.firstTeam = team;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![self ifFavoriteTeams]) {
        NSLog(@"numberOfRowsInSection: %d, %@, %d", section, [[self.data objectAtIndex:section] objectForKey:@"league"], [[[self.data objectAtIndex:section] objectForKey:@"teams"] count]);
        return [[[self.data objectAtIndex:section] objectForKey:@"teams"] count];
    }
    return [self.data count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (![self ifFavoriteTeams]) {
        NSLog(@"numberOfSectionsInTableView: %d", [self.data count]);
        return [self.data count];
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self ifFavoriteTeams]) {
        return [[self.data objectAtIndex:section] objectForKey:@"league"];
    }
    return @"";
}

static NSString *scheduleTeamCellIdentifier = @"scheduleTeamCellIdentifier";


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleTeamCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:scheduleTeamCellIdentifier];
    }
    
    UIView *titleLabel = [cell viewWithTag:13001];
    if ([titleLabel isKindOfClass:[UILabel class]]) {
        VSTeam *team = nil;
        if ([self ifFavoriteTeams]) {
            team = [self.data objectAtIndex:[indexPath row]];
        } else {
            team = [[[self.data  objectAtIndex:[indexPath section]] objectForKey:@"teams"] objectAtIndex:[indexPath row]];
        }
        
        [(UILabel*)titleLabel setText:[NSString stringWithFormat:@"%@ %@", [team teamName], [team teamNickname]]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleTeamCellIdentifier];
    
    return cell.bounds.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:selectVSSegueIdentifier
                              sender:[tableView cellForRowAtIndexPath:indexPath]];
}


@end
