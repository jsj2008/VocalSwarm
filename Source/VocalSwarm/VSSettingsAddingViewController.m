//
//  VSSettingsAddingViewController.m
//  VocalSwarm
//
//  Created by Alexey on 05.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsAddingViewController.h"

//#import "VSNetworkESPN.h"

#import "VSSettingsModel.h"

#import "VSSportLeague.h"

#import "UIViewController+ImageBackButton.h"
#import "config.h"
#import <Parse/Parse.h>
@interface VSSettingsAddingViewController () <UITableViewDelegate>

- (IBAction)homeAction;

@end

@implementation VSSettingsAddingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpImageBackButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)homeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *leagueAbbr = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    NSString *sportName = [tableView.dataSource tableView:tableView titleForHeaderInSection:[indexPath section]];
    
    NSMutableArray *dataFavoritesSports = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_SPORTS];
    if(!dataFavoritesSports) {
        dataFavoritesSports = [NSMutableArray array];
    }
//    [dataFavoritesSports addObject:[[VSSportLeague alloc] initWithSport:sportName league:leagueAbbr]];
    [dataFavoritesSports addObject:[NSArray arrayWithObjects:sportName, leagueAbbr, nil]];
    NSLog(@"%d", dataFavoritesSports.count);

    [[PFUser currentUser] setObject:dataFavoritesSports forKey:PARSE_FAVORITE_SPORTS];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [VSSettingsModel synchronizeAlltoServer:YES
                                       finished:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
//    [VSSettingsModel addFavoriteSport:[[VSSportLeague alloc] initWithSport:sportName league:leagueAbbr]];
    
}

@end
