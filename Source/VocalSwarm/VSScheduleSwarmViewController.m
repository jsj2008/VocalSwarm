//
//  VSScheduleSwarmViewController.m
//  VocalSwarm
//
//  Created by Alexey on 13.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSScheduleSwarmViewController.h"
#import "VSScheduleSwarm2ViewController.h"
#import "VSSwarmSelectionViewController.h"
#import "VSSwarmMainViewController.h"

@interface VSScheduleSwarmViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation VSScheduleSwarmViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

static NSString *secondScreenSegueIdentifier = @"scheduleSwarmSegue";
static NSString *swarmTypeSelect = @"swarmTypeSelect";
static NSString *swarmChatSegue = @"swarmChatSegue";

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:secondScreenSegueIdentifier]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            VSScheduleSwarm2ViewController* destinationVC = (VSScheduleSwarm2ViewController*)segue.destinationViewController;
            [destinationVC setDataSourceName:[[(UILabel*)[sender viewWithTag:13001] text] lowercaseString]];
        }
    } else if ([segue.identifier isEqualToString:swarmTypeSelect]) {
        VSSwarmSelectionViewController *swarmSelection = segue.destinationViewController;
        [swarmSelection setSwarm:sender];
        swarmSelection.isJoinAfterCreate = YES;
    } else if ([segue.identifier isEqualToString:swarmChatSegue]) {
        VSSwarmMainViewController *swarmMainVC = segue.destinationViewController;
        [swarmMainVC setSwarm:sender];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

static NSString *scheduleSportCellIdentifier = @"scheduleSportCellIdentifier";


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleSportCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:scheduleSportCellIdentifier];
    }
    
    UIView *titleLabel = [cell viewWithTag:13001];
    if ([titleLabel isKindOfClass:[UILabel class]]) {
        if ([indexPath row] == 0) {
            [(UILabel*)titleLabel setText:@"Favorite Teams"];
        } else if ([indexPath row] == 1) {
            [(UILabel*)titleLabel setText:@"Baseball"];
        } else if ([indexPath row] == 2) {
            [(UILabel*)titleLabel setText:@"Football"];
        } else if ([indexPath row] == 3) {
            [(UILabel*)titleLabel setText:@"Basketball"];
        } else if ([indexPath row] == 4) {
            [(UILabel*)titleLabel setText:@"Hockey"];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduleSportCellIdentifier];
    
    return cell.bounds.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:secondScreenSegueIdentifier
                              sender:[tableView cellForRowAtIndexPath:indexPath]];
}

@end
