//
//  VSTabBarViewController.m
//  VocalSwarm
//
//  Created by Alexey on 03.06.13.
//  Copyright (c) 2013 injoit. All rights reserved.
//

#import "VSTabBarViewController.h"
#import "VSSettingsViewController.h"
#import "VSMessagesViewController.h"
#import "VSScheduledSwarmsViewController.h"
#import "VSFullWebViewController.h"

@interface VSTabBarViewController () <UITabBarControllerDelegate, UITabBarDelegate>

- (IBAction)settingsAction;
- (IBAction)messagesAction:(id)sender;
- (IBAction)swarmsAction;

@end

@implementation VSTabBarViewController

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
    self.delegate = self;
    
//    for (UITabBarItem* tabBarItem in [[self tabBar] items]) {
//        [tabBarItem setFinishedSelectedImage:[tabBarItem image]
//                 withFinishedUnselectedImage:[tabBarItem image]];
//    }
//    
//    [[self tabBar] setSelectedImageTintColor:[UIColor lightGrayColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    return [[controller topViewController] supportedInterfaceOrientations];
}

- (IBAction)settingsAction {
    int selfIndex = [self.navigationController.viewControllers indexOfObject:self];
    if ([self.navigationController.viewControllers objectAtIndex:selfIndex - 1])
    {
        if ([[self.navigationController.viewControllers objectAtIndex:selfIndex - 1] class] != [VSSettingsViewController class])
        {
            VSSettingsViewController* settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsController"];
            NSMutableArray *controllersArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
            [controllersArray insertObject:settingsController atIndex:selfIndex];
            [self.navigationController setViewControllers:controllersArray animated:NO];
        }
        
        if ([[self.navigationController.viewControllers objectAtIndex:selfIndex] class] == [VSSettingsViewController class])
        {
            [[self.navigationController.viewControllers objectAtIndex:selfIndex] navigationItem].hidesBackButton = YES;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (IBAction)messagesAction:(id)sender {
    [[self tabBar] setSelectionIndicatorImage:[UIImage imageNamed:@"clearDot"]];
    [[[self tabBar] selectedItem] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor grayColor], UITextAttributeTextColor,
                                               nil] forState:UIControlStateNormal];
    
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    if (![[controller topViewController] isKindOfClass:[VSMessagesViewController class]]) {
        UIViewController* messagesController = [self.storyboard instantiateViewControllerWithIdentifier:@"MessagesController"];
        [controller pushViewController:messagesController animated:YES];
    }
}

- (IBAction)swarmsAction {
    [self scheduledSwarmsAction];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    UINavigationController* controller = (UINavigationController*)viewController;
    [controller popToRootViewControllerAnimated:YES];
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
//    for (UITabBarItem* tabBarItem in [tabBar items]) {
//        if (tabBarItem != item) {
//            [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                                  [UIColor grayColor], UITextAttributeTextColor,
//                                                                  nil] forState:UIControlStateNormal];
//        }
//    }
//    
//    [[self tabBar] setSelectionIndicatorImage:nil];
//    [item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                  [UIColor whiteColor], UITextAttributeTextColor,
//                                  nil] forState:UIControlStateNormal];
}

- (void) selectWithTextColoring:(NSInteger) index
{
    [self setSelectedIndex:2];
    
//    for (int i = 0; i < [[self.tabBar items] count]; i++) {
//        UITabBarItem* tabBarItem = [[self.tabBar items] objectAtIndex:i];
//        if (i != index) {
//            [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                [UIColor grayColor], UITextAttributeTextColor,
//                                                nil] forState:UIControlStateNormal];
//        } else {
//            [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                          [UIColor whiteColor], UITextAttributeTextColor,
//                                          nil] forState:UIControlStateNormal];
//        }
//    }
}

- (void)scheduleSwarmAction {
    [self selectWithTextColoring:3];
    
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    [controller popToRootViewControllerAnimated:YES];
}

- (void)scheduledSwarmsAction {
    [self selectWithTextColoring:2];
    
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    if (![[controller topViewController] isKindOfClass:[VSScheduledSwarmsViewController class]]) {
        [controller popToRootViewControllerAnimated:NO];
        [[controller topViewController] performSegueWithIdentifier:@"testSegue" sender:self];
    }
}

- (void)liveSwarmJoin:(NSObject *)swarm {
    [self selectWithTextColoring:3];
    
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    [controller popToRootViewControllerAnimated:NO];
    [[controller topViewController] performSegueWithIdentifier:@"swarmChatSegue" sender:swarm];
}

- (void)liveSwarmCreate:(NSObject *)swarm {
    [self selectWithTextColoring:3];
    
    UINavigationController* controller = (UINavigationController*)[self selectedViewController];
    [controller popToRootViewControllerAnimated:NO];
    [[controller topViewController] performSegueWithIdentifier:@"swarmTypeSelect" sender:swarm];
}

- (void)fullScreenWebView:(NSURL *)url {
    [self performSegueWithIdentifier:@"FullScreenWebView" sender:url];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FullScreenWebView"]) {
        if ([[segue destinationViewController] isKindOfClass:VSFullWebViewController.class] &&
            [sender isKindOfClass:NSURL.class])
        {
            NSURL *url = sender;
            VSFullWebViewController *destVC = [segue destinationViewController];
            [destVC setDataUrl:url];
        }
    }
}

@end
