//
//  VSFullWebViewController.m
//  VocalSwarm
//
//  Created by Alexey on 20.08.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSFullWebViewController.h"
#import "UIViewController+ImageBackButton.h"

@interface VSFullWebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation VSFullWebViewController

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
    
    [self setUpImageBackButton];
    
    [self showUrl:self.dataUrl];
    
    //not really great idea
    if (self.navigationController && [[self.navigationController viewControllers] count] > 1) {
        UITabBarController *tabVC = [[self.navigationController viewControllers] objectAtIndex:[[self.navigationController viewControllers] count] - 2];
        if ([tabVC isKindOfClass:[UITabBarController class]]) {
            UINavigationController *navVC = (UINavigationController *)[tabVC selectedViewController];
            if ([navVC isKindOfClass:[UINavigationController class]]) {
                self.delegate = (id<VSFullWebViewControllerDelegate>)[navVC topViewController];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), self);
    if (self.navigationController && [self.navigationController topViewController] == self) {
        if ([self.delegate respondsToSelector:@selector(hardDisappear)]) {
            [self.delegate hardDisappear];
        }
    }
    
    [super viewWillDisappear:animated];
}

#pragma mark - WebView

- (void) showUrl:(NSURL*) url {
    [self.webView setHidden:YES];
    [self.activityIndicator setHidden:NO];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *twitterCookie = [storage cookiesForURL:url];
    
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:twitterCookie];
    
    [request setAllHTTPHeaderFields:headers];
    
    NSLog(@"headers %@", headers);
    
    [self.webView loadRequest:request];
}

- (void) showActivity {
    [self.activityIndicator setHidden:NO];
}

- (void) hideActivity {
    [self.activityIndicator setHidden:YES];
    [self.webView setHidden:NO];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSRange domainRange = [[[request URL] host] rangeOfString:@"quickblox.com"];
    if (domainRange.length > 0) {
        [[self navigationController] popViewControllerAnimated:YES];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    [self showActivity];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    [self hideActivity];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"%@", webView);
    NSLog(@"%@", error);
    if ([error code] == NSURLErrorCancelled || [error code] == 102)
        return;
    
    //TODD 102 change to appropriate error define Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"])
        return;
    
    [self hideActivity];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please check your internet connection"
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
    [alertView show];
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
