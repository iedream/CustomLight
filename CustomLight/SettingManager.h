//
//  SettingManager.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-09.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SETTINGTYPE)
{
    SETTINGTYPE_NONE,
    SETTINGTYPE_BRIGHTNESS,
    SETTINGTYPE_PROXIMITY,
    SETTINGTYPE_SHAKE
};

@interface SettingManager : NSObject

+ (SettingManager*)sharedSettingManager;

- (UIAlertController *)addNewSetting:(NSDictionary *)newSettingDic;
- (UIAlertController *)editSettingOldSetting:(NSDictionary *)oldSetting andNewSetting:(NSDictionary *)newSetting;
- (void)removeExistingSetting:(NSDictionary *)existingSettingDic;

- (NSDictionary *)getActiveSettingWith:(SETTINGTYPE)settingType;
- (NSMutableArray *)getAllSettingData;

- (void)writeBridgeSetupToPlistSetting;
- (BOOL)readBridgeSetupFromPlistSetting;

- (int)generateUniqueKey;
@end
