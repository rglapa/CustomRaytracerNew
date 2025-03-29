//
//  AppDelegate.m
//  CustomRaytracerNew
//
//  Created by Ruben Glapa on 3/29/25.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

#if TARGET_IOS

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)NSWorkspaceLaunchOptions
{
    return YES;
}
#else

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#endif
@end
