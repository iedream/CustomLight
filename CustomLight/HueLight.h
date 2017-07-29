//
//  HueLight.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSInteger, LIGHTNAME)
{
    LIGHTNAME_NONE,
    LIGHTNAME_CATHERINE_BEDROOM,
    LIGHTNAME_LIVING_ROOM,
    LIGHTNAME_ALL
};

@interface HueLight : NSObject
@property (nonatomic, strong) UIActivityIndicatorView *spinnerView;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;

+ (HueLight*)sharedHueLight;
- (void)refreshCache;
- (void)toggleLightOnOffWithActiveDict:(NSDictionary *)activeDict;
- (void)configureLightWithActiveDict:(NSDictionary *)activeDict andLightSwitch:(BOOL)lightSwitch;
- (void)getSunriseSunsetTime:(CLLocationCoordinate2D)coordinate;
- (void)detectSurrondingBrightness:(CGFloat)brightness andActiveDict:(NSDictionary *)activeDict;
- (NSArray*)getGroupData;
- (void)startLoading;
- (void)stopLoading;
- (void)hasEnterRange;
- (NSDictionary*)convertUIColorToHueColorNumber:(UIColor *)color andGroupName:(NSArray *)groupNames;
- (void) deleteSunriseSunsetData;
@end
