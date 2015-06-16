//
//  VSMainIPadViewController.m
//  VocalSwarm
//
//  Created by Alexey on 14.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSMainIPadViewController.h"
#import "VSHomeViewController.h"
#import "VSMessagesViewController.h"
#import "VSScheduleSwarmViewController.h"
#import "VSScheduledSwarmsViewController.h"
#import "VSSwarmMainViewController.h"
#import "VSFullWebViewController.h"

@interface VSMainIPadViewController () <UIWebViewDelegate>

- (IBAction)showMessagesNavigationAction;
- (IBAction)showMessagesAction;
- (IBAction)showSwarmsAction;
- (IBAction)homeAction;

@property (weak, nonatomic) UINavigationController* dynamicContent;
@property (weak, nonatomic) VSScheduledSwarmsViewController *scheduledVC;

@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UIButton *webViewCloseButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *webViewActivity;
@property (weak, nonatomic) IBOutlet UIView *swarmsContainer;
@property (weak, nonatomic) IBOutlet UIView *dynamicContainer;

- (IBAction)webViewCloseAction;

@property (weak, nonatomic) IBOutlet UIView *adView;

@end

@implementation VSMainIPadViewController

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
    
    UIImage *navigationMainButtonImage = [UIImage imageNamed:@"navigationBarMainButton.png"];
    UIButton *navigationMainButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, navigationMainButtonImage.size.width, navigationMainButtonImage.size.height)];
    [navigationMainButton setImage:navigationMainButtonImage forState:UIControlStateNormal];
    [navigationMainButton addTarget:self action:@selector(mainAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.titleView = navigationMainButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(showAds)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [FlurryAds removeAdFromSpace:@"BOTTOM_IPAD"];
    
//    for (UIView *views in [self.adView subviews]) {
//        [views removeFromSuperview];
//    }
    
    [super viewWillDisappear:animated];
}

- (void)showAds
{
    [FlurryAds fetchAndDisplayAdForSpace:@"BOTTOM_IPAD"
                                    view:self.adView
                                    size:BANNER_BOTTOM];
//    if ([FlurryAds adReadyForSpace:@"BOTTOM_IPAD"]) {
//        NSLog(@"flurry showing ads in main ipad success");
//        [FlurryAds displayAdForSpace:@"BOTTOM_IPAD" onView:self.adView];
//    } else {
//        NSLog(@"flurry showing ads in main ipad repeat");
//        [self performSelector:@selector(showAds) withObject:nil afterDelay:1];
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) mainAction {
    [self homeAction];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"homeViewSegue"]) {
        VSHomeViewController* homeVC = (VSHomeViewController*)segue.destinationViewController;
        [homeVC setDisplayType:displayTypeiPad];
    } else if ([segue.identifier isEqualToString:@"dynamicContentSegue"]) {
        self.dynamicContent = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"scheduledSwarmsSegue"]) {
        self.scheduledVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"swarmChatSegue"]) {
        VSSwarmMainViewController *destVC = [segue destinationViewController];
        [destVC setSwarm:sender];
        [destVC setIsReplaceBack:YES];
    } else if ([segue.identifier isEqualToString:@"FullScreenWebView"]) {
        if ([[segue destinationViewController] isKindOfClass:VSFullWebViewController.class] &&
            [sender isKindOfClass:NSURL.class])
        {
            NSURL *url = sender;
            VSFullWebViewController *destVC = [segue destinationViewController];
            [destVC setDataUrl:url];
        }
    }
}

- (IBAction)showMessagesNavigationAction {
    
}

- (IBAction)showMessagesAction {
    if (![[self.dynamicContent topViewController] isKindOfClass:[VSMessagesViewController class]]) {
        [[[self.dynamicContent viewControllers] objectAtIndex:0] performSegueWithIdentifier:@"showMessagesSegue" sender:self];
    }
}

- (IBAction)showSwarmsAction {
    [self.dynamicContent popToRootViewControllerAnimated:YES];
    [self.scheduledVC updateData];
}

- (IBAction)homeAction {
    [self.dynamicContent popToRootViewControllerAnimated:YES];
    [self.scheduledVC updateData];
}

- (IBAction)showScheduleAction {
    if (![[self.dynamicContent topViewController] isKindOfClass:[VSScheduleSwarmViewController class]]) {
//        [self.dynamicContent popToRootViewControllerAnimated:NO];
        [[[self.dynamicContent viewControllers] objectAtIndex:0] performSegueWithIdentifier:@"showScheduleSwarmSegue" sender:self];
    }
}

- (IBAction) selectTypeForSwarm:(NSObject *) swarm {
//    if (![[self.dynamicContent topViewController] isKindOfClass:[VSScheduleSwarmViewController class]]) {
        [[[self.dynamicContent viewControllers] objectAtIndex:0] performSegueWithIdentifier:@"swarmTypeSelect" sender:swarm];
//    }
}

- (IBAction) showSwarm:(NSObject *) swarm {
    [self performSegueWithIdentifier:@"swarmChatSegue" sender:swarm];
}

- (void)fullScreenWebView:(NSURL *)url {
    [self performSegueWithIdentifier:@"FullScreenWebView" sender:url];
}

- (void)swarmsContainerChangeHeight:(NSNumber *)height {
    if (self.swarmsContainer.frame.size.height != [height floatValue]) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect frame = self.swarmsContainer.frame;
                             frame.size.height = [height floatValue];
                             self.swarmsContainer.frame = frame;
                             frame = self.dynamicContainer.frame;
                             frame.size.height = 917 - [height floatValue];
                             frame.origin.y = [height floatValue];
                             self.dynamicContainer.frame = frame;
                             [[self.dynamicContent topViewController].view layoutSubviews];
                             NSLog(@"%@", self.dynamicContainer);
                         }];
    }
}

#pragma mark - SwarmJoinLive

- (void) liveSwarmShowActivityIndicator {
    [self.webView setHidden:YES];
    [self.webViewCloseButton setHidden:NO];
    [self.webViewActivity setHidden:NO];
    [self.webViewContainer setHidden:NO];
}

- (void) liveSwarmHideActivityIndicator {
    [self.webViewContainer setHidden:YES];
}

#pragma mark - WebView

- (void) showUrl:(NSURL*) url {
    [self.webView setHidden:YES];
    [self.webViewCloseButton setHidden:NO];
    [self.webViewActivity setHidden:NO];
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
    [self.webViewActivity setHidden:NO];
}

- (void) hideActivity {
    [self.webViewActivity setHidden:YES];
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
