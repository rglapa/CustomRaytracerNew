//
//  AppDelegate.h
//  CustomRaytracerNew
//
//  Created by Ruben Glapa on 3/29/25.
//
#if TARGET_IOS

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

#else

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>


@end
#endif
