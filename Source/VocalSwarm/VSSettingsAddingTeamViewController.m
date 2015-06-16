//
//  VSSettingsAddingTeamViewController.m
//  VocalSwarm
//
//  Created by Alexey on 06.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSSettingsAddingTeamViewController.h"
#import "VSSettingsAddingTeam2ViewController.h"

#import "UIViewController+ImageBackButton.h"

@interface VSSettingsAddingTeamViewController () <UITableViewDelegate>

- (IBAction)homeAction;

@end

@implementation VSSettingsAddingTeamViewController

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
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"teamSelectSegue" sender:cell];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"teamSelectSegue"]) {
        VSSettingsAddingTeam2ViewController *vc = [segue destinationViewController];
        
        NSString *sportName = [[[(UITableViewCell*)sender textLabel] text] lowercaseString];
        [vc setSportName:sportName];
    }
}

@end
