//
//  AppDelegate.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "ServerConfig.h"

@implementation AppDelegate

@synthesize window = _window, rootViewController, trace, packetHandler, cloudEngine, upgrade, nvram;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UITabBarController *c = (UITabBarController*) self.window.rootViewController;
    UITabBar* tb = [c tabBar];
    NSArray* items = [tb items];
    UITabBarItem* homeItem = [items objectAtIndex:0];
    UITabBarItem* promoItem = [items objectAtIndex:1];
    UITabBarItem* aboutItem = [items objectAtIndex:2];
    
    homeItem.title = NSLocalizedString(@"HOME", @"Home");
    promoItem.title = NSLocalizedString(@"PROMO", @"Promo");
    aboutItem.title = NSLocalizedString(@"ABOUT", @"About");
    
    
    // Create the data controller and pass it to the root view controller.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    rootViewController = (HomeViewController *)[[navigationController viewControllers]objectAtIndex:0];
    self.rootViewController = rootViewController;
    
    // Override point for customization after application launch.
    trace = [[MyTraceController alloc] init ];
    [rootViewController setTrace:trace];
    [trace clear];
    cloudEngine = [[CloudEngine alloc] initWithHostName:avneraServer1 customHeaderFields:nil];
    [trace trace:@"Trace up and running"];
    packetHandler = [[PacketHandler alloc] init];
    nvram = [[NvramControl alloc] init];
    upgrade = [[FirmwareUpgrade alloc] init];
//    batteryCapacity = [[BatteryCapacity alloc] init];
    
    current_revision = @"-1";
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSString*)getCurrentRevision
{
    return current_revision;
}

- (void)setCurrentRevision:(NSString *)revision
{
    NSString* tmp = [[NSString alloc] initWithFormat:@"setCurrentRevision(): %@", revision];
    [trace trace:tmp];
    current_revision = revision;
}

- (void)setServer:(int)server_num
{
    NSString *serverUrl;
    if( server_num == 0 )
        serverUrl = [[NSString alloc] initWithString:(avneraServerAuto)];
    else if( server_num == 1 )
        serverUrl = [[NSString alloc] initWithString:(avneraServer1)];
    else if( server_num == 2 )
        serverUrl = [[NSString alloc] initWithString:(avneraServer2)];
    else if(server_num == 3 )
        serverUrl = [[NSString alloc] initWithString:(avneraServer3)];
    
    self.cloudEngine = [[CloudEngine alloc] initWithHostName:serverUrl customHeaderFields:nil];
}
@end
