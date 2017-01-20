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
@property (nonatomic, strong) NSMutableArray *settingsArray;
@property (nonatomic, strong) NSMutableArray *widgetsArray;
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
        for (NSDictionary *dict in self.settingsArray) {
            if ([dict[@"uniqueKey"] intValue] == uniqueKey) {
                isUnique = NO;
            }
        }
    } while (!isUnique);
    return uniqueKey;
}

- (NSDictionary *)getActiveDictWithUniqueKey:(int)uniqueKey {
    for (NSDictionary *dict in self.settingsArray) {
        if ([dict[@"uniqueKey"] intValue] == uniqueKey) {
            return dict;
        }
    }
    return nil;
}

- (void)configureSettingWithWidgesData:(NSNotification *)notif {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    NSArray *data = [sharedDefaults arrayForKey:@"LightSettingData"];
    
    for (NSDictionary *dict in data) {
        int uniqueKey = [dict[@"uniqueKey"] intValue];
        NSDictionary *currentActiveDict = [self getActiveDictWithUniqueKey:uniqueKey];
        if (!currentActiveDict) {
            continue;
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
            [self.settingsArray removeObject:currentActiveDict];
            [self.settingsArray addObject:[mutableCopy copy]];
            [self writeToPlistSetting];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForData" object:nil];
        }
    }

}

- (BOOL)widgetTypeExitAlready:(NSDictionary *)dict {
    SETTINGTYPE settingType = [dict[@"type"] integerValue];
    NSArray *groupNames = dict[@"groupNames"];
    for (NSDictionary *widgetDict in self.widgetsArray) {
        if ([widgetDict[@"type"] integerValue] == settingType && [groupNames containsObject:widgetDict[@"groupName"]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)widgetLimitReached {
    if (self.widgetsArray.count >=4 ) {
        return YES;
    } else {
        return NO;
    }
}

- (void)shareWidgets {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    [sharedDefaults setObject:self.widgetsArray forKey:@"LightSettingData"];
    [sharedDefaults synchronize];
}

- (UIAlertController*)refreshWidget {
    NSArray *allDicts = [self getAllSettingData];
    [self.widgetsArray removeAllObjects];
    for (NSDictionary *dict in allDicts) {
        if ([dict[@"useWidgets"] boolValue]) {
            UIAlertController *failure = [self addWidgets:dict];
            if (failure) {
                return failure;
            }
        }
    }
    return nil;
}

- (UIAlertController*)addWidgets:(NSDictionary *)dict {
     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    if ([self widgetLimitReached]) {
        UIAlertController *widgetError = [UIAlertController alertControllerWithTitle:@"Failed To Add Widget" message:@"Max Limit(4) of Widgets Reached" preferredStyle:UIAlertControllerStyleAlert];
        [widgetError addAction:cancelAction];
        return widgetError;
    } else if ([self widgetTypeExitAlready:dict]) {
        UIAlertController *widgetError = [UIAlertController alertControllerWithTitle:@"Failed To Add Widget" message:@"Widget of Current Action Type For Current Room Already Exit" preferredStyle:UIAlertControllerStyleAlert];
        [widgetError addAction:cancelAction];
        return widgetError;
    }
    
    for (NSString *groupName in dict[@"groupNames"]) {
        NSDictionary *data = @{@"groupName": groupName, @"type": dict[@"type"], @"state": dict[@"on"], @"uniqueKey": dict[@"uniqueKey"], @"uicolor": dict[@"uicolor"]};
        [self.widgetsArray addObject:data];
    }
    [self shareWidgets];
    return nil;
}

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType {
    return [self getActiveSettingWith:settingType withinAnHour:NO];
}

- (NSArray *)getFutureActiveSettingWith:(SETTINGTYPE)settingType {
    return [self getActiveSettingWith:settingType withinAnHour:YES];
}

- (NSArray *)getActiveSettingWith:(SETTINGTYPE)settingType withinAnHour:(BOOL)withinAnHour {
    NSMutableArray *allActiveSetting = [[NSMutableArray alloc] init];
    for (NSDictionary *currentDict in self.settingsArray.copy) {
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

- (NSMutableArray *)getAllSettingData {
    return self.settingsArray;
}

- (void)addNewSetting:(NSDictionary *)newSettingDic {
    [self.settingsArray addObject:newSettingDic];
    [self writeToPlistSetting];
}

- (void)removeExistingSetting:(NSDictionary *)existingSettingDic {
    [self.settingsArray removeObject:existingSettingDic];
    [self writeToPlistSetting];
}

- (void)editSettingOldSetting:(NSDictionary *)oldSetting andNewSetting:(NSDictionary *)newSetting {
    [self.settingsArray removeObject:oldSetting];
    [self.settingsArray addObject:newSetting];
    
    [self writeToPlistSetting];
}

- (void)setHomeCoord:(CLLocationCoordinate2D)homeCoord {
    _homeCoord = homeCoord;
    [self writeToPlistSetting];
}

- (void)writeToPlistSetting {
    NSDictionary *homeCoordDict = @{@"longitude": @(self.homeCoord.longitude), @"latitude": @(self.homeCoord.latitude)};
    
    NSDictionary *originaldict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary: @{@"settings": [self.settingsArray copy], @"widgets": [self.widgetsArray copy], @"homeCoord": homeCoordDict}];
    if (originaldict[@"authenticated"]) {
        [dict setValue:originaldict[@"authenticated"] forKey:@"authenticated"];
    }
    [dict writeToURL:self.fileURL atomically:YES];
}

- (void)writeBridgeSetupToPlistSetting {
    NSDictionary *homeCoordDict = @{@"longitude": @(self.homeCoord.longitude), @"latitude": @(self.homeCoord.latitude)};

    NSDictionary *dict = @{@"settings": [self.settingsArray copy], @"authenticated": [NSNumber numberWithBool:YES], @"widgets": [self.widgetsArray copy], @"homeCoord": homeCoordDict};
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
        self.settingsArray = [[NSMutableArray alloc] init];
        self.widgetsArray = [[NSMutableArray alloc] init];
        self.homeCoord = CLLocationCoordinate2DMake(0.0, 0.0);
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:self.fileURL.path];
        self.settingsArray = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"settings"]];
        self.widgetsArray = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"widgets"]];
        NSDictionary *homeDict = dict[@"homeCoord"];
        self.homeCoord = CLLocationCoordinate2DMake([homeDict[@"latitude"] floatValue], [homeDict[@"longitude"] floatValue]);
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
