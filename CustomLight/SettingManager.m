//
//  SettingManager.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-09.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "SettingManager.h"
#import "HueLight.h"
#import <UIKit/UIKit.h>

@interface SettingManager()
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSMutableDictionary *settingsDict;
@property (nonatomic, strong) NSMutableDictionary *widgetsDict;
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

- (int)generateUniqueKey {
    int uniqueKey;
    BOOL isUnique = YES;
    do {
        uniqueKey = arc4random();
        if ([self.settingsDict objectForKey:@(uniqueKey)]) {
            isUnique = NO;
        }
    } while (!isUnique);
    return uniqueKey;
}

- (void)configureSettingWithWidgesData:(NSNotification *)notif {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    NSDictionary *data = [sharedDefaults dictionaryForKey:@"LightSettingData"];
    self.widgetsDict = [[NSMutableDictionary alloc] initWithDictionary:data];
    
    for (NSString *uniqueKeyInit in data.allKeys) {
        NSString *uniqueKey = [[uniqueKeyInit componentsSeparatedByString:@"/"] firstObject];
        NSDictionary *currentActiveDict = [self.settingsDict objectForKey:uniqueKey];
        NSDictionary *currentWidgetsDict = [data objectForKey:uniqueKeyInit];
        if (!currentActiveDict) {
            continue;
        }
        NSMutableDictionary *mutableCopy;
        NSMutableArray *groupNamesArr = [[NSMutableArray alloc] initWithArray:currentActiveDict[@"groupNames"]];
        if ([currentWidgetsDict[@"state"] boolValue] && ![groupNamesArr containsObject:currentWidgetsDict[@"groupName"]]) {
                [groupNamesArr addObject:currentWidgetsDict[@"groupName"]];
                mutableCopy = [[NSMutableDictionary alloc] initWithDictionary:currentActiveDict];
                mutableCopy[@"groupNames"] = [groupNamesArr copy];
        } else if (![currentWidgetsDict[@"state"] boolValue] && [groupNamesArr containsObject:currentWidgetsDict[@"groupName"]]) {
                [groupNamesArr removeObject:currentWidgetsDict[@"groupName"]];
                mutableCopy = [[NSMutableDictionary alloc] initWithDictionary:currentActiveDict];
                mutableCopy[@"groupNames"] = [groupNamesArr copy];
        }
        if (mutableCopy && [mutableCopy[@"groupNames"] count] == 0) {
            mutableCopy[@"on"] = [NSNumber numberWithBool:NO];
        } else if (mutableCopy && [mutableCopy[@"groupNames"] count] > 0) {
            mutableCopy[@"on"] = [NSNumber numberWithBool:YES];
        }
        if (mutableCopy) {
            if ([uniqueKey isEqualToString:@"Sunset"]) {
                if ([mutableCopy[@"groupNames"] count] == 0 && [[self.settingsDict[uniqueKey] objectForKey:@"groupNames"] count] != [mutableCopy[@"groupNames"] count]) {
                    [[HueLight sharedHueLight] setSunriseSunsetDataStatus:SCHEDULE_STATUS_DISABLED];
                } else if ([mutableCopy[@"groupNames"] count] == 1 && [[self.settingsDict[uniqueKey] objectForKey:@"groupNames"] count] != [mutableCopy[@"groupNames"] count]) {
                    [[HueLight sharedHueLight] setSunriseSunsetDataStatus:SCHEDULE_STATUS_ENABLED];
                }
                NSMutableDictionary *originalSunrise = [[NSMutableDictionary alloc] initWithDictionary: self.settingsDict[@"Sunrise"]];
                NSMutableDictionary *originalSunset = [[NSMutableDictionary alloc] initWithDictionary: self.settingsDict[@"Sunset"]];
                originalSunset[@"groupNames"] = mutableCopy[@"groupNames"];
                originalSunrise[@"groupNames"] = mutableCopy[@"groupNames"];
                self.settingsDict[@"Sunrise"] = originalSunrise;
                self.settingsDict[@"Sunset"] = originalSunset;
            } else {
                self.settingsDict[uniqueKey] = [mutableCopy copy];
            }
            [self writeToPlistSetting];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForData" object:nil];
        }
    }

}

- (void)refreshWidgetForUniqueKey:(NSString *)uniqueKey{
    if (!uniqueKey) {
        return;
    }
    
    if ([uniqueKey isEqualToString:@"Sunrise_Sunset"]) {
        uniqueKey = @"Sunset";
    }
    
    for (NSString *uniqueKeyInit in self.widgetsDict.allKeys) {
        if ([[[uniqueKeyInit componentsSeparatedByString:@"/"] firstObject] isEqualToString:uniqueKey]) {
            [self.widgetsDict removeObjectForKey:uniqueKeyInit];
        }
    }
    
    if ([uniqueKey isEqualToString:@"Sunrise_Sunset"]) {
        uniqueKey = @"Sunset";
        [self.widgetsDict removeObjectForKey:uniqueKey];
    }
    NSDictionary *dict = self.settingsDict[uniqueKey];
    if ([dict[@"useWidgets"] boolValue] ) {
        NSArray *groupNames = dict[@"groupNames"];
        for (NSString *groupName in groupNames) {
            NSDictionary *data = @{@"groupName": groupName, @"type": dict[@"type"], @"state": dict[@"on"], @"uicolor": dict[@"uicolor"]};
            NSString *uniqueKeyFinal = [NSString stringWithFormat:@"%@/%lu", uniqueKey, (unsigned long)[groupNames indexOfObject:groupName]];
            self.widgetsDict[uniqueKeyFinal] = data;
        }
    }
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    [sharedDefaults setObject:self.widgetsDict forKey:@"LightSettingData"];
    [sharedDefaults synchronize];
}

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType {
    if (settingType == SETTINGTYPE_SUNRISE_SUNSET) {
        return [self getSunriseSunsetSetting].allValues;
    }
    return [self getActiveSettingWith:settingType withinAnHour:NO];
}

- (NSArray *)getFutureActiveSettingWith:(SETTINGTYPE)settingType {
    return [self getActiveSettingWith:settingType withinAnHour:YES];
}

- (void)setScheduleIdOfSunriseSunsetSetting:(NSString *)scheduleId andUniqueKey:(NSString *)uniqueKey {
    if ([uniqueKey isEqualToString:@"Sunrise"]) {
        NSMutableDictionary *sunriseDic = [[NSMutableDictionary alloc] initWithDictionary:self.settingsDict[@"Sunrise"]];
        sunriseDic[@"scheduleId"] = scheduleId;
        self.settingsDict[@"Sunrise"] = sunriseDic.copy;
    } else {
        NSMutableDictionary *sunriseDic = [[NSMutableDictionary alloc] initWithDictionary:self.settingsDict[@"Sunset"]];
        sunriseDic[@"scheduleId"] = scheduleId;
        self.settingsDict[@"Sunset"] = sunriseDic.copy;
    }
    [self writeToPlistSetting];
}

- (NSDictionary *)getSunriseSunsetSetting {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.settingsDict[@"Sunrise"]) {
        [dict setObject:self.settingsDict[@"Sunrise"] forKey:@"Sunrise"];
    }
    if (self.settingsDict[@"Sunset"]) {
        [dict setObject:self.settingsDict[@"Sunset"] forKey:@"Sunset"];
    }
    return dict.copy;
}

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType withinAnHour:(BOOL)withinAnHour {
    NSMutableArray *allActiveSetting = [[NSMutableArray alloc] init];
    for (NSDictionary *currentDict in self.settingsDict.allValues) {
        if ([currentDict[@"type"] integerValue] != settingType) {
            continue;
        }
    
        if ([currentDict[@"on"] boolValue] == NO) {
            continue;
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
        
        NSDate *originalCurrentTime = currentTime;
        if (withinAnHour) {
            currentTime = [currentTime dateByAddingTimeInterval:3600];
        }
        
        
        
        for (NSString *selectedDay in selectedDays) {
            if ([currentDay containsString:selectedDay]) {
                if ([startTime compare:currentTime] == NSOrderedAscending && [originalCurrentTime compare:endTime] == NSOrderedAscending) {
                    [allActiveSetting addObject:currentDict];
                } else if ([endTime compare:startTime] == NSOrderedAscending && [currentTime compare:startTime] == NSOrderedAscending && [originalCurrentTime compare:endTime] == NSOrderedAscending) {
                    [allActiveSetting addObject:currentDict];
                } else if ([endTime compare:startTime] == NSOrderedAscending && [currentTime compare:startTime] == NSOrderedDescending && [originalCurrentTime compare:endTime] == NSOrderedDescending) {
                    [allActiveSetting addObject:currentDict];
                }
            }
        }
    }
    return allActiveSetting.copy;
}

- (NSArray *)getAllSettingData {
    NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:self.settingsDict.allKeys];
    if ([arr containsObject:@"Sunset"]) {
        [arr removeObject:@"Sunset"];
        [arr removeObject:@"Sunrise"];
        [arr addObject:@"Sunrise_Sunset"];
    }
    return arr;
}

- (NSDictionary *)getDataForUniqueKey:(NSString *)uniqueKey {
    if ([uniqueKey isEqualToString:@"Sunrise_Sunset"]) {
        return self.settingsDict[@"Sunset"];
    }
    return self.settingsDict[uniqueKey];
}

- (NSString *)addSetting:(NSDictionary *)newSettingDic uniqueKey:(NSString *)uniqueKey {
    if (!uniqueKey) {
        uniqueKey = [NSString stringWithFormat: @"%i", [self generateUniqueKey]];
    }
    self.settingsDict[uniqueKey] = newSettingDic;
    [self writeToPlistSetting];
    return uniqueKey;
}

- (NSString *)addSettingForSunriseSunset:(NSDictionary *)newSettingDic {
    NSDictionary *oldSunriseDic = self.settingsDict[@"Sunrise"];
    NSMutableDictionary *newSunriseDic = [[NSMutableDictionary alloc] initWithDictionary:newSettingDic];
    newSunriseDic[@"scheduleId"] = oldSunriseDic[@"scheduleId"];
    self.settingsDict[@"Sunrise"] = newSunriseDic.copy;
    
    NSDictionary *oldSunsetDic = self.settingsDict[@"Sunset"];
    NSMutableDictionary *newSunsetDic = [[NSMutableDictionary alloc] initWithDictionary:newSettingDic];
    newSunsetDic[@"scheduleId"] = oldSunsetDic[@"scheduleId"];
    self.settingsDict[@"Sunset"] = newSunsetDic.copy;
    
    [self writeToPlistSetting];
    return @"Sunrise_Sunset";
}

- (void)removeSettingWithUniqueKey:(NSString *)uniqueKey {
    if ([uniqueKey isEqualToString:@"Sunrise_Sunset"]) {
        [[HueLight sharedHueLight] deleteSunriseSunsetData];
    }
    [self.settingsDict removeObjectForKey:@"Sunrise"];
    [self.settingsDict removeObjectForKey:@"Sunset"];
    [self refreshWidgetForUniqueKey:uniqueKey];
    [self writeToPlistSetting];
}

- (void)setHomeCoord:(CLLocationCoordinate2D)homeCoord {
    _homeCoord = homeCoord;
    [self writeToPlistSetting];
}

- (void)writeToPlistSetting {
    NSDictionary *homeCoordDict = @{@"longitude": @(self.homeCoord.longitude), @"latitude": @(self.homeCoord.latitude)};
    
    NSDictionary *originaldict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary: @{@"settings": self.settingsDict, @"widgets": self.widgetsDict, @"homeCoord": homeCoordDict}];
    if (originaldict[@"authenticated"]) {
        [dict setValue:originaldict[@"authenticated"] forKey:@"authenticated"];
    }
    Boolean succ = [dict writeToURL:self.fileURL atomically:YES];
}

- (void)writeBridgeSetupToPlistSetting {
    NSDictionary *homeCoordDict = @{@"longitude": @(self.homeCoord.longitude), @"latitude": @(self.homeCoord.latitude)};

    NSDictionary *dict = @{@"settings": [self.settingsDict copy], @"authenticated": [NSNumber numberWithBool:YES], @"widgets": [self.widgetsDict copy], @"homeCoord": homeCoordDict};
    Boolean succ = [dict writeToURL:self.fileURL atomically:YES];
}

- (BOOL)readBridgeSetupFromPlistSetting {
    [self writeBridgeSetupToPlistSetting];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if(![fileManage fileExistsAtPath:self.fileURL.path]){
        return NO;
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
        if (dict) {
            BOOL bridgeSetup = [[dict objectForKey:@"authenticated"] boolValue];
            return bridgeSetup;
        }
        return NO;
    }
}

- (void)readFromPlistSetting {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if(![fileManage fileExistsAtPath:self.fileURL.path]){
        self.settingsDict = [[NSMutableDictionary alloc] init];
        self.widgetsDict = [[NSMutableDictionary alloc] init];
        _homeCoord = CLLocationCoordinate2DMake(0.0, 0.0);
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
        if (dict && [dict objectForKey:@"settings"]) {
            self.settingsDict = [[NSMutableDictionary alloc] initWithDictionary:[dict objectForKey:@"settings"]];
        } else {
            self.settingsDict = [[NSMutableDictionary alloc] init];
        }
        if (dict && [dict objectForKey:@"widgets"]) {
            self.widgetsDict = [[NSMutableDictionary alloc] initWithDictionary:[dict objectForKey:@"widgets"]];
        } else {
            self.widgetsDict = [[NSMutableDictionary alloc] init];
        }
        if (dict && dict[@"homeCoord"]) {
            NSDictionary *homeDict = dict[@"homeCoord"];
            _homeCoord = CLLocationCoordinate2DMake([homeDict[@"latitude"] floatValue], [homeDict[@"longitude"] floatValue]);
        } else {
            _homeCoord = CLLocationCoordinate2DMake(0.0, 0.0);
        }
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
