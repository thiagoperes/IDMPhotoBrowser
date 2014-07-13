//
//  AppDelegate.m
//  PhotoBrowserDemo
//
//  Created by Michael Waterfall on 31/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Menu.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    Menu *menu = [[Menu alloc] initWithStyle:UITableViewStyleGrouped];
    self.viewController = (UIViewController *)[[UINavigationController alloc] initWithRootViewController:menu];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
