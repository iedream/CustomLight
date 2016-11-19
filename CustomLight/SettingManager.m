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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configureSettingWithWidgesData:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (NSDictionary *)getActionBrightness {
    return [self getActiveSettingWith:SETTINGTYPE_BRIGHTNESS includeInActive:NO];
}

- (NSDictionary *)getActionProximity {
    return [self getActiveSettingWith:SETTINGTYPE_PROXIMITY includeInActive:NO];
}

- (NSDictionary *)getActionShake {
    return [self getActiveSettingWith:SETTINGTYPE_SHAKE includeInActive:NO];
}

- (void)editActiveSettingWith:(SETTINGTYPE)settingType andState:(BOOL)state writeToSetting:(BOOL)writeToSetting {
    NSDictionary *currentActiveSetting = [self getActiveSettingWith:settingType includeInActive:NO];
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:currentActiveSetting];
    mutableDict[@"on"] = [NSNumber numberWithBool:state];
    [self removeExistingSetting:currentActiveSetting WithSettingType:settingType writeToSetting:NO];
    [self addNewSetting:mutableDict WithSettingType:settingType writeToSetting:NO];
    if (writeToSetting) {
        [self writeToPlistSetting];
        [self shareToWidges];
    }
}

- (void)configureSettingWithWidgesData:(NSNotification *)notif {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    if (!sharedDefaults) {
        return;
    }
    NSArray *data = [sharedDefaults arrayForKey:@"LightSettingData"];
    for (NSDictionary *dict in data) {
        NSDictionary *currentActiveDict = [self getActiveSettingWith:[dict[@"type"] integerValue] includeInActive:YES];
        if (!currentActiveDict) {
            break;
        }
        NSMutableDictionary *mutableCopy;
        NSMutableArray *groupNamesArr = [[NSMutableArray alloc] initWithArray:currentActiveDict[@"groupNames"]];
        if ([dict[@"state"] boolValue] && ![groupNamesArr containsObject:dict[@"groupName"]]) {
                [groupNamesArr addObject:dict[@"groupName"]];
                mutableCopy = [[NSMutableDictionary alloc] initWithDictionary:currentActiveDict];
                mutableCopy[@"groupNames"] = [groupNamesArr copy];
        } else if (![dict[@"state"] boolValue] && [groupNamesArr containsObject:dict[@"groupName"]]) {
                [groupNamesArr removeObject:dict[@"groupName"]];
                mutableCopy = [[NSMutableDictionary alloc] initWithDictionary:currentActiveDict];
                mutableCopy[@"groupNames"] = [groupNamesArr copy];
        }
        if (mutableCopy && [mutableCopy[@"groupNames"] count] == 0) {
            mutableCopy[@"on"] = [NSNumber numberWithBool:NO];
        } else if (mutableCopy && [mutableCopy[@"groupNames"] count] > 0) {
            mutableCopy[@"on"] = [NSNumber numberWithBool:YES];
        }
        if (mutableCopy) {
            [self removeExistingSetting:currentActiveDict WithSettingType:[dict[@"type"] integerValue] writeToSetting:NO];
            [self addNewSetting:[mutableCopy copy] WithSettingType:[dict[@"type"] integerValue] writeToSetting:NO];
        }
        [self writeToPlistSetting];
    }

}

- (void)shareToWidges {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    NSDictionary *brightnessDict = [self getActiveSettingWith:SETTINGTYPE_BRIGHTNESS includeInActive:YES];
    NSDictionary *proximityDict = [self getActiveSettingWith:SETTINGTYPE_PROXIMITY includeInActive:YES];
    NSDictionary *shakeDict = [self getActiveSettingWith:SETTINGTYPE_SHAKE includeInActive:YES];
    for (NSString *groupName in brightnessDict[@"groupNames"]) {
        [data addObject:@{@"groupName": groupName, @"type": @(SETTINGTYPE_BRIGHTNESS), @"state": brightnessDict[@"on"]}];
    }
    for (NSString *groupName in proximityDict[@"groupNames"]) {
        [data addObject:@{@"groupName": groupName, @"type": @(SETTINGTYPE_PROXIMITY), @"state": proximityDict[@"on"]}];
    }
    for (NSString *groupName in shakeDict[@"groupNames"]) {
        [data addObject:@{@"groupName": groupName, @"type": @(SETTINGTYPE_SHAKE), @"state": shakeDict[@"on"]}];
    }
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    [sharedDefaults setObject:data forKey:@"LightSettingData"];
    [sharedDefaults synchronize];
}

- (NSDictionary *)getActiveSettingWith:(SETTINGTYPE)settingType includeInActive:(BOOL)includeInactive {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    for (NSDictionary *currentDict in currentArray) {
        if (!includeInactive) {
            if ( [currentDict[@"on"] boolValue] == NO) {
                break;
            }
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

- (NSMutableArray *)getAllSettingData {
    NSMutableArray *allData = [[NSMutableArray alloc] initWithArray:[_shakeArray copy]];
    [allData addObjectsFromArray:[_brightnessArray copy]];
    [allData addObjectsFromArray:[_proximityArray copy]];
    return allData;
}

- (void)addNewSetting:(NSDictionary *)newSettingDic WithSettingType:(SETTINGTYPE)settingType writeToSetting:(BOOL)writeToSetting {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray addObject:newSettingDic];
    if (writeToSetting) {
        [self writeToPlistSetting];
        [self shareToWidges];
    }
}

- (void)removeExistingSetting:(NSDictionary *)existingSettingDic WithSettingType:(SETTINGTYPE)settingType writeToSetting:(BOOL)writeToSetting {
    NSMutableArray *currentArray = [self getArrayDataWithSettingType:settingType];
    [currentArray removeObject:existingSettingDic];
    if (writeToSetting) {
        [self writeToPlistSetting];
        [self shareToWidges];
    }
}

- (void)writeToPlistSetting {
    NSDictionary *originaldict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
    NSDictionary *dict = @{@"brightness": [_brightnessArray copy], @"proximity": [_proximityArray copy],  @"shake": [_shakeArray copy], @"authenticated": originaldict[@"authenticated"]};
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
