//
//  VSSettingsAddingTeam2ViewController.m
//  VocalSwarm
//
//  Created by Alexey on 06.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsAddingTeam2ViewController.h"

//#import "VSNetworkESPN.h"
#import "VSNetworkChalk.h"
#import "VSSettingsModel.h"
#import "VSTeam.h"
#import "config.h"
#import <Parse/Parse.h>
#import "UIViewController+ImageBackButton.h"

@interface VSSettingsAddingTeam2ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *dataTeams;

- (IBAction)homeAction;

@end

@implementation VSSettingsAddingTeam2ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dataTeams = [[NSMutableDictionary alloc] init];
        _sportName = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setHidden:YES];
    
    [self setUpImageBackButton];
    
    VSNetworkChalk* networkInstance = [VSNetworkChalk sharedInstance];
    
    NSMutableArray *leagueForLoad = [NSMutableArray arrayWithArray:[networkInstance leaguesForSport:[VSNetworkChalk sport:self.sportName]]];
    
    [self loadLeaguesData:leagueForLoad result:^{
        [self.tableView reloadData];
        [self.tableView setHidden:NO];
        [self.activityIndicator setHidden:YES];
    }];
}

- (void) loadLeaguesData:(NSMutableArray *)leaguesForLoad result:(void (^)())finished {
    if ([leaguesForLoad count] == 0) {
        finished();
    } else {
        NSString *league = [leaguesForLoad lastObject];
        [leaguesForLoad removeLastObject];
        
        [self.dataTeams setObject:[[VSNetworkChalk sharedInstance] prebuildedTeamsForSportLeague:[[VSSportLeague alloc] initWithSport:self.sportName league:league]] forKey:league];
        [self loadLeaguesData:leaguesForLoad result:finished];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)homeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.dataTeams allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.dataTeams allKeys] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *key = [[self.dataTeams allKeys] objectAtIndex:section];
    return [(NSArray *)[self.dataTeams objectForKey:key] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"addTeamCellIdentifier";
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    NSString *key = [[self.dataTeams allKeys] objectAtIndex:[indexPath section]];
    VSTeam *team = [(NSArray *)[self.dataTeams objectForKey:key] objectAtIndex:[indexPath row]];
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@", [team teamName], [team teamNickname]]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *key = [[self.dataTeams allKeys] objectAtIndex:[indexPath section]];
    VSTeam *team = [(NSArray *)[self.dataTeams objectForKey:key] objectAtIndex:[indexPath row]];
    NSMutableArray *dataFavoritesTeams = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_TEAMS];
    if(!dataFavoritesTeams) {
        dataFavoritesTeams = [NSMutableArray array];
    }
    [dataFavoritesTeams addObject:[NSArray arrayWithObjects:team.sportLeague.sportName, team.sportLeague.leagueAbbr,[NSString stringWithFormat:@"%d", team.teamId], team.teamName, team.teamNickname, nil]];
    [[PFUser currentUser] setObject:dataFavoritesTeams forKey:PARSE_FAVORITE_TEAMS];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [VSSettingsModel synchronizeAlltoServer:YES
                                       finished:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
        
        [Flurry logEvent:@"Favorite Team Added"];
        [Flurry logEvent:@"Favorite Team Added For Sport" withParameters:@{@"Sport Name" : self.sportName}];
        [Flurry logEvent:@"Favorite Team Added With Team" withParameters:@{@"Team Name" : [NSString stringWithFormat:@"%@ %@", [team teamName], [team teamNickname]]}];
    }];
//    [VSSettingsModel addFavoriteTeam:team];
    
}


@end
