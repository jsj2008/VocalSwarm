//
//  VSScheduledSwarmsViewController.m
//  VocalSwarm
//
//  Created by Alexey on 13.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSScheduledSwarmsViewController.h"
#import "VSSwarmsModel.h"
#import "VSSwarm.h"
#import "VSGame.h"
//#import "VSSwarmSelectionViewController.h"
#import "VSSwarmMainViewController.h"
#import "EGORefreshTableHeaderView.h"

@interface VSScheduledSwarmsViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, EGORefreshTableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (copy, nonatomic) NSArray *data;
@property (copy, nonatomic) NSArray *notMineData;

@property (strong, nonatomic) NSIndexPath *dataForDelete;

@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic) BOOL reloading;

@end

@implementation VSScheduledSwarmsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _data = [NSArray array];
        _notMineData = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateData];
    self.reloading = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.tableView) {
        if (self.refreshHeaderView == nil) {
            EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.frame.size.height,
                                                                                                          self.view.frame.size.width, self.view.frame.size.height)];
            view.delegate = self;
            [self.tableView addSubview:view];
            self.refreshHeaderView = view;
        }
    }
    
    [self.tableView setHidden:YES];
    [self.headerView setHidden:YES];
    [self.activityIndicator setHidden:NO];
        
    [self updateData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateData {
    if (!self.reloading) {
        self.reloading = YES;
        
        //    [self.tableView setHidden:YES];
        //    [self.headerView setHidden:YES];
        if (self.collectionView) {
            [self.collectionView setHidden:YES];
            [self.activityIndicator setHidden:NO];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[VSSwarmsModel sharedInstance] updateSwarmDataWithResult:^(NSArray *swarms) {
                self.data = [self sortByDate:swarms];
                [self splitData];
                self.reloading = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self recreateLocalNotificationsFor:self.data];
                    
                    [self.tableView setHidden:NO];
                    [self.headerView setHidden:NO];
                    [self.collectionView setHidden:NO];
                    [self.activityIndicator setHidden:YES];
                    
                    [self.tableView reloadData];
                    [self.collectionView reloadData];
                    
                    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
                });
            }];
        });
    }
}

- (NSArray *)sortByDate:(NSArray *)swarmsArray
{
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                        sortDescriptorWithKey:@"gameDate"
                                        ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    return [swarmsArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (void) splitData {
    NSMutableArray *myData = [NSMutableArray array];
    NSMutableArray *notMyData = [NSMutableArray array];
    for (VSSwarm *swarm in self.data) {
        if ([swarm isMine]) {
            [myData addObject:swarm];
        } else {
            [notMyData addObject:swarm];
        }
    }
    self.data = myData;
    self.notMineData = notMyData;
}

- (void)recreateLocalNotificationsFor:(NSArray *) swarmsArray
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    for (VSSwarm *swarm in swarmsArray) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [localNotification setAlertBody:[NSString stringWithFormat:@"Swarm %@ VS %@ was started now !", [swarm.game.homeTeam teamNickname], [swarm.game.awayTeam teamNickname]]];
//        [localNotification setFireDate:[NSDate dateWithTimeIntervalSince1970:[[NSDate date] timeIntervalSince1970] + 60 * 60 * 25]];
        [localNotification setFireDate:swarm.gameDate];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        NSLog(@"localNotification %@", localNotification);
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self updateData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return self.reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark - Data Source

- (NSInteger)numberOfSections {
    if ([self.notMineData count] && [self.data count]) {
        return 2;
    } else if ([self.notMineData count] || [self.data count]) {
        return 1;
    }
    return 0;
}

- (NSInteger)numberOfRowsInSecion:(NSInteger)section {
    if (section == 0 && [self.data count]) {
        return [self.data count];
    } else {
        return [self.notMineData count];
    }
    return 0;
}

- (VSSwarm *)dataFor:(NSIndexPath *)indexPath {
    VSSwarm *swarmData = nil;
    if (indexPath.section == 0 && [self.data count]) {
        swarmData = [self.data objectAtIndex:[indexPath row]];
    } else {
        swarmData = [self.notMineData objectAtIndex:[indexPath row]];
    }
    return swarmData;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsInSecion:section];
}

static NSString *scheduledSwarmsCellIdentifier = @"scheduledSwarmsCellIdentifier";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    //static cells for show
    cell = [tableView dequeueReusableCellWithIdentifier:scheduledSwarmsCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:scheduledSwarmsCellIdentifier];
    }
    
    VSSwarm *swarmData = [self dataFor:indexPath];
    
    UIView *titleLabel = [cell viewWithTag:13001];
    if ([titleLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)titleLabel setText:[swarmData getFullDescription]];
    }
    UIView *typeImageView = [cell viewWithTag:13002];
    if ([typeImageView isKindOfClass:[UIImageView class]]) {
        UIImage *image = nil;
        if (swarmData.type == VSSwarmType) {
            image = [UIImage imageNamed:@"vsPill"];
        } else if (swarmData.type == TeamSwarmType) {
            image = [UIImage imageNamed:@"teamPill"];
        } else if (swarmData.type == PrivateSwarmType) {
            image = [UIImage imageNamed:@"privatePill"];
        }
        [(UIImageView*)typeImageView setImage:image];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:scheduledSwarmsCellIdentifier];
    
    return cell.bounds.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    UIImageView *background = [[UIImageView alloc] initWithFrame:view.bounds];
    [background setImage:[UIImage imageNamed:@"settingsAddBackground"]];
    [view addSubview:background];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 320, 50)];
    [title setTextColor:[UIColor whiteColor]];
    [title setBackgroundColor:[UIColor clearColor]];
    if (section == 0 && [self.data count]) {
        [title setText:@"Swarms You Created"];
    } else {
        [title setText:@"Swarms You Joined"];
    }
    [view addSubview:title];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:swarmChatSegue
                              sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        self.dataForDelete = indexPath;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Vocal Swarm Sports"
                                                        message:@"Do you want to delete this swarm?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Delete", nil];
        [alert show];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        VSSwarm *swarm = [self dataFor:self.dataForDelete];
        if (self.dataForDelete.section == 0 && [self.data count]) {
            NSMutableArray *data = [self.data mutableCopy];
            [data removeObjectAtIndex:self.dataForDelete.row];
            self.data = data;
        } else {
            NSMutableArray *data = [self.notMineData mutableCopy];
            [data removeObjectAtIndex:self.dataForDelete.row];
            self.notMineData = data;
        }
        
//        [self.tableView deleteRowsAtIndexPaths:@[self.dataForDelete] withRowAnimation:YES];
        [self.tableView reloadData];
        [self.collectionView reloadData];
        [[VSSwarmsModel sharedInstance] removeSwarm:swarm];
    }
    self.dataForDelete = nil;
}

#pragma mark - Segue

static NSString *swarmChatSegue = @"swarmChatSegue";

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:swarmChatSegue]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        VSSwarm *swarm = [self dataFor:indexPath];
        
        VSSwarmMainViewController *swarmSelection = (VSSwarmMainViewController*) segue.destinationViewController;
        
        [swarmSelection setSwarm:swarm];
    }
}

#pragma mark - Collection Deletion

- (void)activateDeletionMode:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan)
    {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        UIView *deleteButton = [cell viewWithTag:13007];
//        [deleteButton setFrame:CGRectMake(deleteButton.center.x - 25, deleteButton.center.y - 25, 50, 50)];
        if ([deleteButton isKindOfClass:[UIButton class]]) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 [deleteButton setAlpha:1.0f];
//                                 [deleteButton setFrame:CGRectMake(deleteButton.center.x - 25, deleteButton.center.y - 25, 50, 50)];
                             }
                             completion:^(BOOL finished) {
//                                 [UIView animateWithDuration:0.1
//                                                  animations:^{
//                                                      [deleteButton setFrame:CGRectMake(deleteButton.center.x - 22, deleteButton.center.y - 22, 44, 44)];
//                                                  }];
                             }];
            NSLog(@"%@", deleteButton);
        }
    }
}

- (IBAction)deleteAction:(id)sender {
    UIView *superView = [[[sender superview] superview] superview];
    NSInteger tag = superView.tag;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:tag / 10
                                                 inSection:tag % 10];
//    VSSwarm *data = [self dataFor:indexPath];
    self.dataForDelete = indexPath;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Vocal Swarm Sports"
                                                    message:@"Do you want to delete this swarm?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Delete", nil];
    [alert show];
    
}

#pragma mark - UICollectionViewDataSource

static NSString *scheduledSwarmsCollectionIdentifier = @"scheduledSwarmsCollectionIdentifier";

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//    NSInteger sections = [self numberOfSections];
//    if (self.parentViewController &&
//        [self.parentViewController respondsToSelector:@selector(swarmsContainerChangeHeight:)]) {
//        if (sections == 2) {
//            CGRect frame = self.collectionView.frame;
//            frame.size.height = 152 + 152;
//            self.collectionView.frame = frame;
//            [self.parentViewController performSelector:@selector(swarmsContainerChangeHeight:) withObject:[NSNumber numberWithFloat:200 + 152]];
//        } else {
//            CGRect frame = self.collectionView.frame;
//            frame.size.height = 152;
//            self.collectionView.frame = frame;
//            [self.parentViewController performSelector:@selector(swarmsContainerChangeHeight:) withObject:[NSNumber numberWithFloat:200]];
//        }
//    }
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.data count];
    } else {
        return [self.notMineData count];
    }
//    return [self numberOfRowsInSecion:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = nil;
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:scheduledSwarmsCollectionIdentifier forIndexPath:indexPath];
    
    [cell setTag:[indexPath row] * 10 + [indexPath section]];
    
    VSSwarm *swarmData = [self dataFor:indexPath];
//    VSTeam *myTeam = [swarmData isMyHomeTeam] ? swarmData.game.homeTeam : swarmData.game.awayTeam;
//    VSTeam *opponentTeam = [swarmData isMyHomeTeam] ? swarmData.game.awayTeam : swarmData.game.homeTeam;
    VSTeam *myTeam = swarmData.game.homeTeam;
    VSTeam *opponentTeam = swarmData.game.awayTeam;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
    [df setAMSymbol:@"am"];
    [df setPMSymbol:@"pm"];

    UIView *dayTitleLabel = [cell viewWithTag:13001];
    if ([dayTitleLabel isKindOfClass:[UILabel class]]) {
        [df setDateFormat:@"EEEE"];
        [(UILabel*)dayTitleLabel setText:[df stringFromDate:[swarmData.game gameDate]]];
    }
    
    UIView *dateTitleLabel = [cell viewWithTag:13002];
    if ([dateTitleLabel isKindOfClass:[UILabel class]]) {
        [df setDateFormat:@"MMM d, h:mma 'EST'"];
        [(UILabel*)dateTitleLabel setText:[df stringFromDate:[swarmData.game gameDate]]];
    }
    
    UIView *homeTitleLabel = [cell viewWithTag:13003];
    if ([homeTitleLabel isKindOfClass:[UILabel class]]) {
//        [(UILabel*)homeTitleLabel setText:[NSString stringWithFormat:@"%@ %@", [myTeam teamName], [myTeam teamNickname]]];
        [(UILabel*)homeTitleLabel setText:[NSString stringWithFormat:@"%@", [myTeam teamNickname]]];
    }
    UIView *awayTitleLabel = [cell viewWithTag:13005];
    if ([awayTitleLabel isKindOfClass:[UILabel class]]) {
//        [(UILabel*)awayTitleLabel setText:[NSString stringWithFormat:@"%@ %@", [opponentTeam teamName], [opponentTeam teamNickname]]];
        [(UILabel*)awayTitleLabel setText:[NSString stringWithFormat:@"%@", [opponentTeam teamNickname]]];
    }
    
    UIView *typeImageView = [cell viewWithTag:13006];
    if ([typeImageView isKindOfClass:[UIImageView class]]) {
        UIImage *image = nil;
        if (swarmData.type == VSSwarmType) {
            image = [UIImage imageNamed:@"vsPill"];
        } else if (swarmData.type == TeamSwarmType) {
            image = [UIImage imageNamed:@"teamPill"];
        } else if (swarmData.type == PrivateSwarmType) {
            image = [UIImage imageNamed:@"privatePill"];
        }
        [(UIImageView*)typeImageView setImage:image];
    }
    
    UIView *deleteButton = [cell viewWithTag:13007];
    if ([deleteButton isKindOfClass:[UIButton class]]) {
        [deleteButton setAlpha:0.0];
//        [deleteButton setFrame:CGRectMake(deleteButton.center.x, deleteButton.center.y, 0, 0)];
        BOOL isHave = NO;
        for (UIGestureRecognizer *gesture in [deleteButton gestureRecognizers]) {
            if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
                isHave = YES;
                break;
            }
        }
        if (!isHave) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateDeletionMode:)];
            longPress.delegate = self;
            [collectionView addGestureRecognizer:longPress];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    VSSwarm *swarmData = [self dataFor:indexPath];
    
    if (self.parentViewController &&
        [self.parentViewController respondsToSelector:@selector(showSwarm:)]) {
        [self.parentViewController performSelector:@selector(showSwarm:) withObject:swarmData];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        UIView *titleLabel = [reusableview viewWithTag:13000];
        if ([titleLabel isKindOfClass:[UILabel class]]) {
            if (indexPath.section == 0) {
                [(UILabel *)titleLabel setText:@"Swarms You Created"];
            } else {
                [(UILabel *)titleLabel setText:@"Swarms You Joined"];
            }
        }
    }
    
    return reusableview;
}

@end
