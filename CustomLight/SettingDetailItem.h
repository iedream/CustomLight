//
//  SettingDetailItem.h
//  CustomLight
//
//  Created by Catherine Zhao on 2017-08-21.
//  Copyright © 2017 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY,
    SUNDAY
} RepeatDays;

@interface SettingDetailItem : NSObject

@property (nonatomic, strong) NSArray *wheelColor;
@property (nonatomic, strong) NSData *uiColor;
@property (nonatomic, strong) NSArray *groupNames;
@property (nonatomic) BOOL on;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;

- (NSDictionary *)lightColor;
- (void)setRepeatDays:(NSArray *)repeatDays;
- (NSArray *)getRepeatDays;
- (void)getDictionary;
- (instancetype)initWithData:(NSDictionary *)dict;

@end
