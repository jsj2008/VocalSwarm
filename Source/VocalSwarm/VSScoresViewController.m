//
//  VSScoresViewController.m
//  VocalSwarm
//
//  Created by Alexey on 07.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSScoresViewController.h"
#import "VSSwarmSelectionViewController.h"
#import "VSNetworkChalk.h"
#import "VSSettingsModel.h"
#import "VSGame.h"
#import "VSUtils.h"

@interface VSScoresViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;

//@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) NSMutableArray *data;
@property (strong, nonatomic) NSMutableArray *favoriteTeams;

@property (strong, nonatomic) NSArray *liveData;
@property (strong, nonatomic) NSArray *pastData;
@property (strong, nonatomic) NSArray *todayData;
@property (strong, nonatomic) NSArray *lastWeekData;

@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation VSScoresViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _data = [NSMutableArray array];
        _liveData = [NSArray array];
        _pastData = [NSArray array];
        _todayData = [NSArray array];
        _lastWeekData = [NSArray array];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [self updateData];
}

- (void)proccessScoresForFavoriteTeams:(NSMutableArray *)favoriteTeams {
    if ([favoriteTeams count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator setHidden:YES];
            [self.tableView setHidden:NO];
            [self.collectionView setHidden:NO];
            
            if ([self.data count] > 0) {
                [self.emptyLabel setHidden:YES];
            } else {
                [self.emptyLabel setHidden:NO];
            }
            
            [self sortData];
            
            [self.tableView reloadData];
            [self.collectionView reloadData];
        });
    } else {
        VSSportLeague *sportLeague = [[favoriteTeams lastObject] sportLeague];
        NSMutableArray *teamsToLook = [NSMutableArray array];
        for (int i = 0; i < [favoriteTeams count]; ++i) {
            VSTeam *team = [favoriteTeams objectAtIndex:i];
            if ([[team sportLeague] isEqual:sportLeague]) {
                [teamsToLook addObject:team];
                [favoriteTeams removeObjectAtIndex:i];
                i--;
            }
        }
        
        [[VSNetworkChalk sharedInstance] lastWeekMatchesForSportLeague:sportLeague
                                                                result:^(NSArray *games) {
                                                                    for (VSTeam *team in teamsToLook) {
                                                                        for (VSGame *game in games) {
                                                                            if ([[game homeTeam] isEqual:team] || [[game awayTeam] isEqual:team]) {
                                                                                //check when we haven't this
                                                                                BOOL isAlreadyIn = NO;
                                                                                for (VSGame *inGame in self.data) {
                                                                                    if ([inGame isEqual:game]) {
                                                                                        isAlreadyIn = YES;
                                                                                        break;
                                                                                    }
                                                                                }
                                                                                if (!isAlreadyIn) {
                                                                                    [self.data addObject:game];
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    
                                                                    [self proccessScoresForFavoriteTeams:favoriteTeams];
                                                                }];
//        VSTeam *favTeam = [favoriteTeams lastObject];
//        [favoriteTeams removeLastObject];
//        
//        [[VSNetworkChalk sharedInstance] scoreRequestForTeam:favTeam result:^(NSArray *scoresArray) {
//            for (VSGame *game in scoresArray) {
//                BOOL isAlreadyIn = NO;
//                for (VSGame *inGame in self.data) {
//                    if ([inGame isEqual:game]) {
//                        isAlreadyIn = YES;
//                        break;
//                    }
//                }
//                if (!isAlreadyIn) {
//                    [self.data addObject:game];
//                }
//            }
//
//            [self proccessScoresForFavoriteTeams:favoriteTeams];
//        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self performSelector:@selector(showAds)];
}

- (void)updateData {
    [self.activityIndicator setHidden:NO];
    [self.tableView setHidden:YES];
    [self.collectionView setHidden:YES];
    [self.emptyLabel setHidden:YES];
    
    [self.data removeAllObjects];
    self.favoriteTeams = [NSMutableArray arrayWithArray:[VSSettingsModel getFavoriteTeams]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self proccessScoresForFavoriteTeams:[NSMutableArray arrayWithArray:self.favoriteTeams]];
    });
}

- (void)showAds
{
    if (self.adView) {
        [FlurryAds fetchAndDisplayAdForSpace:@"BOTTOM_IPHONE"
                                        view:self.adView
                                        size:BANNER_BOTTOM];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.adView) {
        [FlurryAds removeAdFromSpace:@"BOTTOM_IPHONE"];
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isSeparator:(NSIndexPath *) indexPath {
    return [indexPath row] % 2 == 1;
}

//TODO not good logic here (for ipad navigation)
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"swarmTypeSelect"]) {
        VSSwarmSelectionViewController *destVC = [segue destinationViewController];
        [destVC setSwarm:sender];
        destVC.isJoinAfterCreate = YES;
    }
}

- (void) sortData
{
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                        sortDescriptorWithKey:@"gameDate"
                                        ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    self.data = [NSMutableArray arrayWithArray:[self.data sortedArrayUsingDescriptors:sortDescriptors]];
//        return [swarmsArray sortedArrayUsingDescriptors:sortDescriptors];
    
    self.liveData = [self liveScores];
    self.pastData = [self lastNotLiveScores];
    self.todayData = [self todayScores];
    self.lastWeekData = [self lastWeekScores];
}

- (NSArray *)liveScores
{
    NSMutableArray *result = [NSMutableArray array];
    for (VSGame *game in self.data) {
        if ([game isLive]) {
            [result addObject:game];
        }
    }
    return result;
}

- (NSArray *)lastNotLiveScores
{
    NSMutableArray *result = [NSMutableArray array];
    for (VSGame *game in self.data) {
        BOOL isLive = NO;
        for (VSGame *liveGame in [self liveScores]) {
            if ([liveGame isEqual:game]) {
                isLive = YES;
                break;
            }
        }
        if (!isLive) {
            [result addObject:game];
        }
    }
    return result;
}

- (NSArray *)todayScores
{
    NSMutableArray *result = [NSMutableArray array];
    for (VSGame *game in self.data) {
        if ([VSUtils isESTDateToday:[game gameDate]]) {
            [result addObject:game];
        }
    }
    return result;
}

- (NSArray *)lastWeekScores
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *todayScores = [self todayScores];
    for (VSGame *game in self.data) {
        
        NSTimeInterval ti = [[game gameDate] timeIntervalSinceNow];
        
        if (ti > -604800) { //1 week = 60 * 60 * 24 * 7
            BOOL isToday = NO;
            
            for (VSGame *game in todayScores) {
                if ([game isEqual:todayScores]) {
                    isToday = YES;
                    break;
                }
            }
            
            if (!isToday) {
                [result addObject:game];
            }
        }
    }
    return result;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.liveData count] > 0)
        return 2;
    else if ([self.pastData count] > 0)
        return 1;
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.liveData count] > 0) {
            return [self.liveData count] * 2 - 1;
        }
        else {
            return [self.pastData count] * 2 - 1;
        }
    }
    return [self.pastData count] * 2 - 1;
}

static NSString *pastCellIdentifier = @"pastCellIdentifier";
static NSString *liveCellIdentifier = @"liveCellIdentifier";
static NSString *separatorCellIdentifier = @"separatorCellIdentifier";

#define IPHONE_WINNER_COLOR [UIColor colorWithRed:207.0/255 green:193.0/255 blue:0.0 alpha:1]

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    //separator cell
    if ([self isSeparator:indexPath]) {
        cell = [tableView dequeueReusableCellWithIdentifier:separatorCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:separatorCellIdentifier];
        }
        
        [cell.textLabel setText:@""];
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    //non separator cell
    else {
        NSString *cellIdentifier = pastCellIdentifier;
        if ([indexPath section] == 0 && [self.liveData count] > 0) {
            cellIdentifier = liveCellIdentifier;
        }
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellIdentifier];
        }
        
        NSInteger correctedIndex = [indexPath row];
        correctedIndex = correctedIndex / 2;
        
        VSGame* game = nil;
        if ([indexPath section] == 0 && [self.liveData count] > 0) {
            game = [self.liveData objectAtIndex:correctedIndex];
        } else {
            game = [self.pastData objectAtIndex:correctedIndex];
        }
        
        BOOL isHomeTeamFavorite = NO;
        BOOL isAwayTeamFavorite = NO;
        
        for (VSTeam *team in self.favoriteTeams) {
            if ([team isEqual:[game homeTeam]]) {
                isHomeTeamFavorite = YES;
            }
            if ([team isEqual:[game awayTeam]]) {
                isAwayTeamFavorite = YES;
            }
        }
        
        UIView* titleLabel = [cell viewWithTag:10001];
        if ([titleLabel isKindOfClass:[UILabel class]]) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"MM/dd"];
            NSString *titleString = [df stringFromDate:[game gameDate]];
            [(UILabel *)titleLabel setText:titleString];
        }
        
        UIView* firstTeamName = [cell viewWithTag:10002];
        if ([firstTeamName isKindOfClass:[UILabel class]]) {
            [(UILabel *)firstTeamName setText:[NSString stringWithFormat:@"%@ %@", [[game homeTeam] teamName], [[game homeTeam] teamNickname]]];
            [(UILabel *)firstTeamName setTextColor:[game homeTeamScore] > [game awayTeamScore] ? IPHONE_WINNER_COLOR : [UIColor whiteColor]];
            [(UILabel *)firstTeamName setFont:isHomeTeamFavorite ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14]];
        }
        
        UIView* firstTeamScore = [cell viewWithTag:10003];
        if ([firstTeamScore isKindOfClass:[UILabel class]]) {
            [(UILabel *)firstTeamScore setText:[NSString stringWithFormat:@"%d", [game homeTeamScore]]];
            [(UILabel *)firstTeamScore setTextColor:[game homeTeamScore] > [game awayTeamScore] ? IPHONE_WINNER_COLOR : [UIColor whiteColor]];
            [(UILabel *)firstTeamScore setFont:isHomeTeamFavorite ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14]];
        }
        
        UIView* secondTeamName = [cell viewWithTag:10004];
        if ([secondTeamName isKindOfClass:[UILabel class]]) {
            [(UILabel *)secondTeamName setText:[NSString stringWithFormat:@"%@ %@", [[game awayTeam] teamName], [[game awayTeam] teamNickname]]];
            [(UILabel *)secondTeamName setTextColor:[game awayTeamScore] > [game homeTeamScore] ? IPHONE_WINNER_COLOR : [UIColor whiteColor]];
            [(UILabel *)secondTeamName setFont:isAwayTeamFavorite ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14]];
        }
        
        UIView* secondTeamScore = [cell viewWithTag:10005];
        if ([secondTeamScore isKindOfClass:[UILabel class]]) {
            [(UILabel *)secondTeamScore setText:[NSString stringWithFormat:@"%d", [game awayTeamScore]]];
            [(UILabel *)secondTeamScore setTextColor:[game awayTeamScore] > [game homeTeamScore] ? IPHONE_WINNER_COLOR : [UIColor whiteColor]];
            [(UILabel *)secondTeamScore setFont:isAwayTeamFavorite ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14]];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isSeparator:indexPath]) {
        return 5.0f;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pastCellIdentifier];
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:liveCellIdentifier];
    }
    
    return cell.bounds.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)];
    [result setBackgroundColor:[UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1]];
    UIImageView *imageView = nil;
    if (section == 0) {
        if ([[self liveScores] count] > 0) {
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LiveHeader.png"]];
        } else {
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PastHeader.png"]];
        }
    } else {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PastHeader.png"]];
    }
    imageView.frame = result.frame;
    [result addSubview:imageView];
    return result;
}

#pragma mark - UICollectionViewDataSource

static NSString *scoreHeaderCollectionIdentifier = @"scoreHeaderCollectionIdentifier";
static NSString *scoreCollectionIdentifier = @"scoreCollectionIdentifier";

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([self.todayData count] > 0)
        return 2;
    else if ([self.lastWeekData count] > 0)
        return 1;
    
    return 0;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *cell = nil;
    
    cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:scoreHeaderCollectionIdentifier forIndexPath:indexPath];
    
    UIView *headerLabel = [cell viewWithTag:12001];
    if ([headerLabel isKindOfClass:[UILabel class]]) {
        if ([indexPath section] == 0) {
            if ([self.todayData count] > 0) {
                [(UILabel*)headerLabel setText:@"TODAY"];
            } else {
                [(UILabel*)headerLabel setText:@"LAST WEEK"];
            }
        } else if ([indexPath section] == 1) {
            [(UILabel*)headerLabel setText:@"LAST WEEK"];
        }
    }
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.todayData count] > 0) {
            return [self.todayData count];
        } else {
            return [self.lastWeekData count];
        }
    } else if (section == 1) {
        return [self.lastWeekData count];
    }
    
    return 0;
}

- (UIImage *) imageForSportName:(NSString*) sportName {
    if ([[sportName lowercaseString] isEqualToString:@"basketball"]) {
        return [UIImage imageNamed:@"iconBasketball.png"];
    } else if ([[sportName lowercaseString] isEqualToString:@"football"]) {
        return [UIImage imageNamed:@"iconFootball.png"];
    } else if ([[sportName lowercaseString] isEqualToString:@"hockey"]) {
        return [UIImage imageNamed:@"iconHockey.png"];
    } else if ([[sportName lowercaseString] isEqualToString:@"soccer"]) {
        return [UIImage imageNamed:@"iconSoccer.png"];
    } else if ([[sportName lowercaseString] isEqualToString:@"baseball"]) {
        return [UIImage imageNamed:@"iconBaseball.png"];
    }
    return nil;
}

#define IPAD_WINNER_COLOR [UIColor colorWithRed:227.0/255 green:210.0/255 blue:0.0 alpha:1]

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = nil;
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:scoreCollectionIdentifier forIndexPath:indexPath];
    
    VSGame* game = nil;
    if ([indexPath section] == 0) {
        if ([self.todayData count] > 0) {
            game = [self.todayData objectAtIndex:[indexPath row]];
        } else {
            game = [self.lastWeekData objectAtIndex:[indexPath row]];
        }
    } else {
        game = [self.lastWeekData objectAtIndex:[indexPath row]];
    }
    
    BOOL isHomeTeamFavorite = NO;
    BOOL isAwayTeamFavorite = NO;
    
    for (VSTeam *team in self.favoriteTeams) {
        if ([team isEqual:[game homeTeam]]) {
            isHomeTeamFavorite = YES;
        }
        if ([team isEqual:[game awayTeam]]) {
            isAwayTeamFavorite = YES;
        }
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd"];
    NSString *titleString = [df stringFromDate:[game gameDate]];
    NSString *homeTeamString =  [NSString stringWithFormat:@"%@ %@", [[game homeTeam] teamName], [[game homeTeam] teamNickname]];
    NSString *homeTeamScore = [NSString stringWithFormat:@"%d", [game homeTeamScore]];
    NSString *awayTeamString = [NSString stringWithFormat:@"%@ %@", [[game awayTeam] teamName], [[game awayTeam] teamNickname]];
    NSString *awayTeamScore = [NSString stringWithFormat:@"%d", [game awayTeamScore]];
    NSString *sportName = [[[game homeTeam] sportLeague] sportName];
    
    UIImage *sportImage = [self imageForSportName:sportName];
    
    UIView *cellTitleLabel = [cell viewWithTag:13001];
    if ([cellTitleLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)cellTitleLabel setText:titleString];
    }
    
    UIView *homeTeamNameLabel = [cell viewWithTag:13002];
    if ([homeTeamNameLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)homeTeamNameLabel setText:homeTeamString];
        [(UILabel*)homeTeamNameLabel setTextColor:[game homeTeamScore] > [game awayTeamScore] ? IPAD_WINNER_COLOR : [UIColor darkGrayColor]];
        [(UILabel*)homeTeamNameLabel setFont:isHomeTeamFavorite ? [UIFont boldSystemFontOfSize:15] : [UIFont systemFontOfSize:15]];
    }
    
    UIView *homeTeamScoresLabel = [cell viewWithTag:13003];
    if ([homeTeamScoresLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)homeTeamScoresLabel setText:homeTeamScore];
        [(UILabel*)homeTeamScoresLabel setTextColor:[game homeTeamScore] > [game awayTeamScore] ? IPAD_WINNER_COLOR : [UIColor darkGrayColor]];
        [(UILabel*)homeTeamScoresLabel setFont:isHomeTeamFavorite ? [UIFont boldSystemFontOfSize:15] : [UIFont systemFontOfSize:15]];
    }
    
    UIView *awayTeamNameLabel = [cell viewWithTag:13004];
    if ([awayTeamNameLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)awayTeamNameLabel setText:awayTeamString];
        [(UILabel*)awayTeamNameLabel setTextColor:[game awayTeamScore] > [game homeTeamScore] ? IPAD_WINNER_COLOR : [UIColor darkGrayColor]];
        [(UILabel*)awayTeamNameLabel setFont:isAwayTeamFavorite ? [UIFont boldSystemFontOfSize:15] : [UIFont systemFontOfSize:15]];
    }
    
    UIView *awayTeamScoresLabel = [cell viewWithTag:13005];
    if ([awayTeamScoresLabel isKindOfClass:[UILabel class]]) {
        [(UILabel*)awayTeamScoresLabel setText:awayTeamScore];
        [(UILabel*)awayTeamScoresLabel setTextColor:[game awayTeamScore] > [game homeTeamScore] ? IPAD_WINNER_COLOR : [UIColor darkGrayColor]];
        [(UILabel*)awayTeamScoresLabel setFont:isAwayTeamFavorite ? [UIFont boldSystemFontOfSize:15] : [UIFont systemFontOfSize:15]];
    }
    
    UIView *sportTypeImage = [cell viewWithTag:13006];
    if ([sportTypeImage isKindOfClass:[UIImageView class]]) {
        [(UIImageView*)sportTypeImage setImage:sportImage];
    }
    
    return cell;
}

@end
