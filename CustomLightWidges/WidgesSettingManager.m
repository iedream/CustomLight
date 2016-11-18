//
//  WidgesSettingManager.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-18.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "WidgesSettingManager.h"

@interface  WidgesSettingManager()
@property (nonatomic, strong) NSMutableArray *brightnessArray;
@property (nonatomic, strong) NSMutableArray *proximityArray;
@property (nonatomic, strong) NSMutableArray *shakeArray;
@end

@implementation WidgesSettingManager

- (void)reloadData {
    NSLog(@"time to reload data");
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    NSDictionary *dict = [defaults dictionaryForKey:@"LightSettingData"];
    if (dict) {
        NSLog(@"data actually exits");
    }
    if (dict[@"shake"]) {
        _shakeArray = [[NSMutableArray alloc] initWithArray:dict[@"shake"]];
    } else {
        _shakeArray = [[NSMutableArray alloc] init];
    }
    
    if (dict[@"brightness"]) {
        _brightnessArray = [[NSMutableArray alloc] initWithArray:dict[@"brightness"]];
    } else {
        _brightnessArray = [[NSMutableArray alloc] init];
    }
    
    if (dict[@"proximity"]) {
        _proximityArray = [[NSMutableArray alloc] initWithArray:dict[@"proximity"]];
    } else {
        _proximityArray = [[NSMutableArray alloc] init];
    }
}

- (NSMutableArray *)getArrayDataWithSettingType:(SETTINGTYPE)settingType {
    switch (settingType) {
        case SETTINGTYPE_SHAKE:
            return _shakeArray;
        case SETTINGTYPE_PROXIMITY:
            return _proximityArray;
        case SETTINGTYPE_BRIGHTNESS:
            return _brightnessArray;
        default:
            return [[NSMutableArray alloc] init];
    }
}

- (NSDictionary *)getActiveSettingWith:(SETTINGTYPE)settingType {
    NSArray *currentArray = [self getArrayDataWithSettingType:settingType];
    for (NSDictionary *currentDict in currentArray) {
        if ([currentDict[@"on"] boolValue] == NO) {
            break;
        }
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"HH:mm"];
        outputFormatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSDateFormatter* day = [[NSDateFormatter alloc] init];
        [day setDateFormat: @"EEEE"];
        
        NSDate *startTime = [outputFormatter dateFromString:currentDict[@"startTime"]];
        NSDate *endTime = [outputFormatter dateFromString:currentDict[@"endTime"]];
        NSArray *selectedDays = currentDict[@"selectedRepeatDays"];
        
        NSDate *currentTime = [NSDate date];
        NSString *currentDay = [day stringFromDate:currentTime];
        currentTime = [outputFormatter dateFromString:[outputFormatter stringFromDate:currentTime]];
        
        if ([endTime compare:startTime] == NSOrderedAscending) {
            endTime = [endTime dateByAddingTimeInterval:60*60*24];
        }
        
        for (NSString *selectedDay in selectedDays) {
            if ([currentDay containsString:selectedDay]) {
                if ([startTime compare:currentTime] == NSOrderedAscending && [currentTime compare:endTime] == NSOrderedAscending) {
                    return currentDict;
                }
            }
        }
    }
    return nil;
}

- (void)editActiveSettingWith:(SETTINGTYPE)settingType andState:(BOOL)state{
    NSDictionary *currentActiveSetting = [self getActiveSettingWith:settingType];
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:currentActiveSetting];
    mutableDict[@"on"] = [NSNumber numberWithBool:state];
    [self removeExistingSetting:currentActiveSetting WithSettingType:settingType];
    [self addNewSetting:mutableDict WithSettingType:settingType];
}

- (void)addNewSetting:(NSDictionary *)newSettingDic WithSettingType:(SETTINGTYPE)settingType {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray addObject:newSettingDic];
}

- (void)removeExistingSetting:(NSDictionary *)existingSettingDic WithSettingType:(SETTINGTYPE)settingType {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray removeObject:existingSettingDic];
}

+ (WidgesSettingManager*)sharedSettingManager {
    static WidgesSettingManager *_sharedSettingManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedSettingManager = [[WidgesSettingManager alloc] init];
    });
    return _sharedSettingManager;
}
@end
