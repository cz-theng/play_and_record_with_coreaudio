//
//  AppDelegate.m
//  audemo
//
//  Created by apollo on 16/5/28.
//  Copyright © 2016年 projm. All rights reserved.
//

#import "AppDelegate.h"
#import "RecorderVC.h"
#import "PlayerVC.h"

@interface AppDelegate ()
@property (strong, nonatomic) RecorderVC *recorderVC;
@property (strong, nonatomic) PlayerVC * playerVC;
@property (strong, nonatomic) UITabBarController *rootVC;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    _recorderVC =(RecorderVC *) [[UIStoryboard storyboardWithName:@"recorder" bundle:nil] instantiateViewControllerWithIdentifier:@"recorder_vc"];
    _playerVC = (PlayerVC *)[[UIStoryboard storyboardWithName:@"player" bundle:nil] instantiateViewControllerWithIdentifier:@"player_vc"];
    _rootVC = [[UITabBarController alloc] init];
    _rootVC.viewControllers = @[_playerVC, _recorderVC];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = _rootVC;
    [self.window makeKeyAndVisible]; // Should Add This in OC

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
