//
//  AppDelegate.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#define UIAppDelegate  ((PHAppDelegate *)[[UIApplication sharedApplication] delegate])

#import <UIKit/UIKit.h>
#import <HueSDK_iOS/HueSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

