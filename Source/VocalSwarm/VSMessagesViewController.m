//
//  VSMessagesViewController.m
//  VocalSwarm
//
//  Created by Alexey on 08.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSMessagesViewController.h"

@interface VSMessagesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation VSMessagesViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

static NSString *messagesChatCellIdentifier = @"messagesChatCellIdentifier";
static NSString *messagesPropsCellIdentifier = @"messagesPropsCellIdentifier";
static NSString *messagesSwarmCellIdentifier = @"messagesSwarmCellIdentifier";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    //static cells for show
    if ([indexPath row] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesChatCellIdentifier];
    } else if ([indexPath row] == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesPropsCellIdentifier];
    } else if ([indexPath row] == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesSwarmCellIdentifier];
    }

    if (cell == nil) {
        if ([indexPath row] == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:messagesChatCellIdentifier];
        } else if ([indexPath row] == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:messagesPropsCellIdentifier];
        } else if ([indexPath row] == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:messagesSwarmCellIdentifier];
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if ([indexPath row] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesChatCellIdentifier];
    } else if ([indexPath row] == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesPropsCellIdentifier];
    } else if ([indexPath row] == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:messagesSwarmCellIdentifier];
    }
    
    return cell.bounds.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
