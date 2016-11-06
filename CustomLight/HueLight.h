//
//  HueLight.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LIGHTNAME)
{
    LIGHTNAME_NONE,
    LIGHTNAME_CATHERINE_BEDROOM,
    LIGHTNAME_LIVING_ROOM,
    LIGHTNAME_ALL
};

@interface HueLight : NSObject
+ (HueLight*)sharedHueLight;
- (void)toggleLightOnOff;
- (void)detectSurrondingBrightness;
@end
