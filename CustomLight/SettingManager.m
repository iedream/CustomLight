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
@property (nonatomic, strong) NSMutableArray *brightnessArray;
@property (nonatomic, strong) NSMutableArray *shakeArray;
@property (nonatomic, strong) NSMutableArray *proximityArray;
@end

@implementation SettingManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *filename = @"plistSetting.txt";
        NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *localPath = [localDir stringByAppendingPathComponent:filename];
        NSString *plistName = [[NSString alloc]initWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
        NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        self.fileURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",plistName]];

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
        NSArray *startTime = [currentDict[@"startTime"] componentsSeparatedByString:@":"];
        NSArray *endTime = [currentDict[@"endTime"] componentsSeparatedByString:@":"];
        NSString *selectedDays = currentDict[@"selectedRepeatDays"];
        
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"HH:mm"];
        NSDateFormatter* day = [[NSDateFormatter alloc] init];
        [day setDateFormat: @"EEEE"];
        
        NSDate *currentTime = [NSDate date];
        NSArray *currentTimeValues = [[outputFormatter stringFromDate:currentTime] componentsSeparatedByString:@":"];
        NSString *currentDay = [day stringFromDate:currentTime];
        
        if ([currentDay containsString:selectedDays]) {
            if (currentTimeValues[0] > startTime[0] && currentTimeValues[0] < endTime[0]) {
                if (currentTimeValues[1] > startTime[1] && currentTimeValues[1] < endTime[1]) {
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
}

- (void)writeToPlistSetting {
    NSURL *fileURL = [self fileURL];
    if (!fileURL) {
        return;
    }
    NSDictionary *dict = @{@"brightness": [_brightnessArray copy], @"proximity": [_proximityArray copy],  @"shake": [_shakeArray copy]};
    [dict writeToURL:fileURL atomically:YES];
    
}

- (void)readFromPlistSetting {
    NSURL *fileURL = [self fileURL];
    if (!fileURL) {
        return;
    }
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if(![fileManage fileExistsAtPath:fileURL.path]){
        _brightnessArray = [[NSMutableArray alloc]init];
        _shakeArray = [[NSMutableArray alloc]init];
        _proximityArray = [[NSMutableArray alloc]init];;
    }
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:fileURL.path];
    _brightnessArray = [dict objectForKey:@"brightness"];
    _shakeArray = [dict objectForKey:@"shake"];
    _proximityArray = [dict objectForKey:@"proximity"];
}

@end
