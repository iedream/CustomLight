//
//  SettingManager.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-09.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SETTINGTYPE)
{
    SETTINGTYPE_NONE,
    SETTINGTYPE_BRIGHTNESS,
    SETTINGTYPE_PROXIMITY,
    SETTINGTYPE_SHAKE
};

@interface SettingManager : NSObject
@property (nonatomic, strong) NSMutableArray *brightnessArray;
@property (nonatomic, strong) NSMutableArray *shakeArray;
@property (nonatomic, strong) NSMutableArray *proximityArray;
+ (SettingManager*)sharedSettingManager;
- (void)addNewSetting:(NSDictionary *)newSettingDic WithSettingType:(SETTINGTYPE)settingType;
- (void)removeExistingSetting:(NSDictionary *)existingSettingDic WithSettingType:(SETTINGTYPE)settingType;
- (NSDictionary *)getActiveSettingWith:(SETTINGTYPE)settingType;

@end
