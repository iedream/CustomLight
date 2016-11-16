//
//  SettingManager.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-09.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "SettingManager.h"
#import <UIKit/UIKit.h>

@interface SettingManager()
@property (nonatomic, strong) NSURL *fileURL;
@end

@implementation SettingManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        self.fileURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",@"plistSetting"]];
        [self readFromPlistSetting];

    }
    return self;
}

- (NSDictionary *)getActionBrightness {
    return [self getActiveSettingWith:SETTINGTYPE_BRIGHTNESS];
}

- (NSDictionary *)getActionProximity {
    return [self getActiveSettingWith:SETTINGTYPE_PROXIMITY];
}

- (NSDictionary *)getActionShake {
    return [self getActiveSettingWith:SETTINGTYPE_SHAKE];
}

- (NSDictionary *)getActiveSettingWith:(SETTINGTYPE)settingType {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    for (NSDictionary *currentDict in currentArray) {
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

- (void)addNewSetting:(NSDictionary *)newSettingDic WithSettingType:(SETTINGTYPE)settingType {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray addObject:newSettingDic];
    [self writeToPlistSetting];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LightSettingsDidUpdate" object:nil];
}

- (void)removeExistingSetting:(NSDictionary *)existingSettingDic WithSettingType:(SETTINGTYPE)settingType {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray removeObject:existingSettingDic];
    [self writeToPlistSetting];
}

- (void)writeToPlistSetting {
    NSDictionary *dict = @{@"brightness": [_brightnessArray copy], @"proximity": [_proximityArray copy],  @"shake": [_shakeArray copy]};
    [dict writeToURL:self.fileURL atomically:YES];
}

- (void)writeBridgeSetupToPlistSetting {
    NSDictionary *dict = @{@"authenticated": [NSNumber numberWithBool:YES]};
    [dict writeToURL:self.fileURL atomically:YES];
}

- (BOOL)readBridgeSetupFromPlistSetting {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if(![fileManage fileExistsAtPath:self.fileURL.path]){
        return NO;
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
        BOOL bridgeSetup = [[dict objectForKey:@"authenticated"] boolValue];
        return bridgeSetup;
    }
}

- (void)readFromPlistSetting {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if(![fileManage fileExistsAtPath:self.fileURL.path]){
        _brightnessArray = [[NSMutableArray alloc]init];
        _shakeArray = [[NSMutableArray alloc]init];
        _proximityArray = [[NSMutableArray alloc]init];;
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
        _brightnessArray = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"brightness"]];
        _shakeArray = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"shake"]];
        _proximityArray = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"proximity"]];
    }
}

+ (SettingManager*)sharedSettingManager {
    static SettingManager *_sharedSettingManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedSettingManager = [[SettingManager alloc] init];
    });
    return _sharedSettingManager;
}

@end
