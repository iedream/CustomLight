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
    SETTINGTYPE_SHAKE
};

@interface SettingManager : NSObject

@property (nonatomic) CLLocationCoordinate2D homeCoord;

+ (SettingManager*)sharedSettingManager;

- (UIAlertController *)addNewSetting:(NSDictionary *)newSettingDic;
- (UIAlertController *)editSettingOldSetting:(NSDictionary *)oldSetting andNewSetting:(NSDictionary *)newSetting;
- (void)removeExistingSetting:(NSDictionary *)existingSettingDic;

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType;
- (NSArray *)getFutureActiveSettingWith:(SETTINGTYPE)settingType;
- (NSMutableArray *)getAllSettingData;

- (void)writeBridgeSetupToPlistSetting;
- (BOOL)readBridgeSetupFromPlistSetting;

- (int)generateUniqueKey;
@end
