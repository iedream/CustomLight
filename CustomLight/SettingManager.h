//
//  SettingManager.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-09.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, SETTINGTYPE)
{
    SETTINGTYPE_NONE,
    SETTINGTYPE_BRIGHTNESS,
    SETTINGTYPE_PROXIMITY,
    SETTINGTYPE_SHAKE,
    SETTINGTYPE_SUNRISE_SUNSET
};

@interface SettingManager : NSObject

@property (nonatomic) CLLocationCoordinate2D homeCoord;

+ (SettingManager*)sharedSettingManager;

- (NSString *)addSetting:(NSDictionary *)newSettingDic uniqueKey:(NSString *)uniqueKey;
- (void)removeSettingWithUniqueKey:(NSString *)uniqueKey;

- (void)refreshWidgetForUniqueKey:(NSString *)uniqueKey;

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType;
- (NSArray *)getFutureActiveSettingWith:(SETTINGTYPE)settingType;
- (NSArray *)getAllSettingData;
- (NSDictionary *)getDataForUniqueKey:(NSString *)uniqueKey;

- (void)setScheduleIdOfSunriseSunsetSetting:(NSString *)scheduleId andUniqueKey:(NSString *)uniqueKey;

- (NSString *)addSettingForSunriseSunset:(NSDictionary *)newSettingDic;
- (NSDictionary *)getSunriseSunsetSetting;

- (void)writeBridgeSetupToPlistSetting;
- (BOOL)readBridgeSetupFromPlistSetting;

@end
