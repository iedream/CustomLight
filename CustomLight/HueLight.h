//
//  HueLight.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LIGHTNAME)
{
    LIGHTNAME_NONE,
    LIGHTNAME_CATHERINE_BEDROOM,
    LIGHTNAME_LIVING_ROOM,
    LIGHTNAME_ALL
};

@interface HueLight : NSObject
@property (nonatomic, strong) UIActivityIndicatorView *spinnerView;
+ (HueLight*)sharedHueLight;
- (void)toggleLightOnOff;
- (void)detectSurrondingBrightness:(CGFloat)brightness;
- (void)turnLightOn;
- (void)turnLightOff;
- (NSArray*)getGroupData;
- (void)startLoading;
- (void)stopLoading;
@end
