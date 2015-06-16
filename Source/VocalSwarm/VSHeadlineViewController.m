//
//  VSHeadlineViewController.m
//  VocalSwarm
//
//  Created by Alexey on 07.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSHeadlineViewController.h"

//#import "VSNetworkESPN.h"
#import "VSNetworkChalk.h"
#import "VSTeam.h"
#import "VSHeadline.h"

#import "VSSettingsModel.h"
#import "EGORefreshTableHeaderView.h"

#import "UIView+FindSubview.h"
#import <Parse/Parse.h>
#import "config.h"
@interface VSHeadlineViewController () <UITableViewDataSource, UITableViewDelegate, EGORefreshTableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;

@property (strong, nonatomic) NSMutableArray *data;
@property (strong, nonatomic) NSMutableArray *favoriteTeams;

@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic) BOOL reloading;

- (IBAction)showWebAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *webViewActivityIndicator;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *webViewCloseButton;

- (IBAction)webViewCloseAction;

@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation VSHeadlineViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _data = [NSMutableArray array];
        _favoriteTeams = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.reloading = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.refreshHeaderView == nil) {
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.view.frame.size.height,
                                                                                                      self.view.frame.size.width, self.view.frame.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		self.refreshHeaderView = view;
	}
    
    if ([self ifNeedUpdate]) {
        [self.tableView setHidden:YES];
        [self.activityIndicator setHidden:NO];
        
        [self updateHeadline];
    } else {
        [self doneLoadingTableViewData:NO];
    }
    
    [self performSelector:@selector(showAds)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)ifNeedUpdate
{
    NSMutableArray *oldTeams = [NSMutableArray arrayWithArray:self.favoriteTeams];
    for (VSTeam *team in [VSSettingsModel getFavoriteTeams]) {
        BOOL isNew = YES;
        for (int i = 0; i < [oldTeams count]; i++) {
            VSTeam *oldTeam = [oldTeams objectAtIndex:i];
            if ([oldTeam isEqual:team]) {
                isNew = NO;
                [oldTeams removeObjectAtIndex:i];
                break;
            }
        }
        
        if (isNew) {
            return YES;
        }
    }
    
    return ([oldTeams count] > 0);
}

- (void)updateHeadline
{
    [Flurry logEvent:@"Headlines Updated"];
    
    self.reloading = YES;
    
//    self.favoriteTeams = [VSSettingsModel getFavoriteTeams];
    NSMutableArray *dataFavoriteTeamArray = (NSMutableArray *)[[PFUser currentUser] objectForKey:PARSE_FAVORITE_TEAMS];
    for(int i = 0; i < dataFavoriteTeamArray.count; i++) {
        NSArray *teamArray = (NSArray *)[dataFavoriteTeamArray objectAtIndex:i];
        VSSportLeague *sportLeague = [[VSSportLeague alloc] initWithSport:[teamArray objectAtIndex:0] league:[teamArray objectAtIndex:1]];
        VSTeam *team = [[VSTeam alloc] initWithSportLeague:sportLeague];
        [team setTeamId:[[teamArray objectAtIndex:2] integerValue]];
        [team setTeamName:[teamArray objectAtIndex:3]];
        [team setTeamNickname:[teamArray objectAtIndex:4]];
        [self.favoriteTeams addObject:team];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[VSNetworkChalk sharedInstance] headlinesForTeams:self.favoriteTeams result:^{
            [self.data removeAllObjects];
            for (VSTeam *team in self.favoriteTeams) {
                //remove headlines older than 2 week
                NSMutableArray *last2weekHeadlines = [NSMutableArray array];
                for (VSHeadline *headline in [team headlines]) {
                    NSTimeInterval ti = [[headline gameDate] timeIntervalSinceNow];
                    if (ti > -1209600) {
                        [last2weekHeadlines addObject:headline];
                    }
                }
                [team setHeadlines:last2weekHeadlines];
                
                [self.data addObjectsFromArray:[team headlines]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self doneLoadingTableViewData:YES];
            });
        }];
    });
}

- (void)doneLoadingTableViewData:(BOOL) withReload
{
//    [self sortData];
//    [self removeTags];

	self.reloading = NO;
    
    if (withReload) {
        [self.tableView reloadData];
    }
    
    [self.activityIndicator setHidden:YES];
    [self.tableView setHidden:NO];
    
    if ([self.data count] == 0) {
        [self.emptyLabel setHidden:NO];
    } else {
        [self.emptyLabel setHidden:YES];
    }
    
	[self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

- (void) sortData {
    //sorting
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                        sortDescriptorWithKey:@"id"
                                        ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    self.data = [NSMutableArray arrayWithArray:[self.data sortedArrayUsingDescriptors:sortDescriptors]];
}

- (void) removeTags {
    NSMutableArray *mutableData = [NSMutableArray arrayWithArray:self.data];
    for (int i = 0; i < [mutableData count]; i++) {
        NSDictionary *dat = [self.data objectAtIndex:i];
        NSString *description = [dat objectForKey:@"description"];
        NSString *strippedString = [self stringByStrippingHTML:description];
        if ([strippedString length] != [description length]) {
            NSMutableDictionary *mutableDat = [NSMutableDictionary dictionaryWithDictionary:dat];
            [mutableDat setValue:strippedString forKey:@"description"];
            [mutableData replaceObjectAtIndex:i withObject:mutableDat];
        }
    }
    self.data = [NSMutableArray arrayWithArray:mutableData];
}

-(NSString *) stringByStrippingHTML:(NSString *) s {
    NSRange r;
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
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
	[self updateHeadline];
    //	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return self.reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
	return [NSDate date]; // should return date data source was last changed
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"headlineCellIdentifier";
    
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    UIView* showButton = [cell findSubviewOfClass:[UIButton class]];
    if ([showButton isKindOfClass:[UIButton class]]) {
        [(UIButton*)showButton setTag:[indexPath row]];
    }
    
    VSHeadline *headline = [self.data objectAtIndex:[indexPath row]];
    
    UIView* mainTitle = [cell viewWithTag:13002];
    if ([mainTitle isKindOfClass:[UILabel class]]) {
        [(UILabel *)mainTitle setText:[NSString stringWithFormat:@"%@ %@", [[headline team] teamName], [[headline team] teamNickname]]];
        //[(UILabel *)mainTitle setText:[[self.data objectAtIndex:[indexPath row]] objectForKey:@"mainTitle"]];
    }
    
    UIView* subTitle = [cell viewWithTag:13003];
    if ([subTitle isKindOfClass:[UILabel class]]) {
        [(UILabel *)subTitle setText:[headline headlineHeader]];
//        [(UILabel *)subTitle setText:[[self.data objectAtIndex:[indexPath row]] objectForKey:@"title"]];
    }
    
    UIView* descriptionTitle = [cell viewWithTag:13004];
    if ([descriptionTitle isKindOfClass:[UILabel class]]) {
        [(UILabel *)descriptionTitle setText:[headline body]];
//        [(UILabel *)descriptionTitle setText:[[self.data objectAtIndex:[indexPath row]] objectForKey:@"description"]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"headlineCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    return cell.bounds.size.height;
}

- (IBAction)showWebAction:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        VSHeadline *headline = [self.data objectAtIndex:[(UIButton*)sender tag]];
//        NSString* link = [[[dataForShow objectForKey:@"links"] objectForKey:@"mobile"] objectForKey:@"href"];
        //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
        [self showUrl:[NSURL URLWithString:[[headline team] teamNewspaperLink]]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    VSHeadline *headline = [self.data objectAtIndex:[indexPath row]];
    NSString* link = [[headline team] teamNewspaperLink];
    
    NSURL *url = [NSURL URLWithString:link];
    
    if ([self tabBarController] && [[self tabBarController] respondsToSelector:@selector(fullScreenWebView:)]) {
        [[self tabBarController] performSelector:@selector(fullScreenWebView:)
                                      withObject:url];
        return;
    }
    
    if (self.parentViewController && [self.parentViewController respondsToSelector:@selector(fullScreenWebView:)]) {
        [self.parentViewController performSelector:@selector(fullScreenWebView:)
                                        withObject:url];
        return;
    }
    
    if (self.parentViewController && [self.parentViewController respondsToSelector:@selector(showUrl:)]) {
        [self.parentViewController performSelector:@selector(showUrl:)
                                        withObject:url];
    } else {
        [self showUrl:url];
    }
}

#pragma mark - WebView

- (void) showUrl:(NSURL*) url {
    [self.webView setHidden:YES];
    [self.webViewCloseButton setHidden:NO];
    [self.webViewActivityIndicator setHidden:NO];
    [self.webViewContainer setHidden:NO];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:60];
    
    [self.webView loadRequest:request];
}

- (IBAction)webViewCloseAction {
    [self.webViewContainer setHidden:YES];
}

- (void) showActivity {
    [self.webViewActivityIndicator setHidden:NO];
}

- (void) hideActivity {
    [self.webViewActivityIndicator setHidden:YES];
    [self.webView setHidden:NO];
    [self.webViewCloseButton setHidden:NO];
}

#pragma mark - UIWebViewDelegate

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self showActivity];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self hideActivity];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([error code] == NSURLErrorCancelled)
        return;
    [self hideActivity];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please check your internet connection"
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
    [alertView show];
    [self webViewCloseAction];
}

@end
