//
//  CustomLightSettingTableViewCell.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-10.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "CustomLightSettingTableViewCell.h"

@interface CustomLightSettingTableViewCell()
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *groupLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *repeatDaysLabel;
@property (nonatomic, strong) NSString *currentUniqueKey;
@end

@implementation CustomLightSettingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.timeLabel = [[UILabel alloc] init];
        self.timeLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.timeLabel];
        self.groupLabel = [[UILabel alloc] init];
        self.groupLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.groupLabel];
        self.typeLabel = [[UILabel alloc] init];
        self.typeLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.typeLabel];
        self.repeatDaysLabel = [[UILabel alloc] init];
        self.repeatDaysLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.repeatDaysLabel];
    }
    return self;
}

- (SETTINGTYPE)currentSettingType {
    NSDictionary *currentDict = [[SettingManager sharedSettingManager] getDataForUniqueKey:self.currentUniqueKey];
    return [currentDict[@"type"] integerValue];
}

- (NSString *)getCurrentUniqueKey {
    return self.currentUniqueKey;
}

- (void)setCellTextWithCurrentUniqueKey:(NSString *)uniqueKey {
    self.currentUniqueKey = uniqueKey;
    NSDictionary *currentDict = [[SettingManager sharedSettingManager] getDataForUniqueKey:uniqueKey];
    
    NSString *lightSettingType = [self lightSettingTypeString:[currentDict[@"type"] integerValue]];
    NSString *groupName = [self groupNameString:currentDict];
    NSString *time = [self timeString:currentDict];
    NSString *repeatDays = [self repeateDaysString:currentDict];
    UIColor *color = (UIColor *)[NSKeyedUnarchiver unarchiveObjectWithData:[currentDict objectForKey:@"uicolor"]];
    
    self.timeLabel.text = time;
    self.groupLabel.text = groupName;
    self.typeLabel.text = lightSettingType;
    self.repeatDaysLabel.text = repeatDays;
    self.backgroundColor = color;
}

- (void)prepareForReuse {
    self.timeLabel.text = @"";
    self.groupLabel.text = @"";
    self.typeLabel.text = @"";
    self.repeatDaysLabel.text = @"";
    self.backgroundColor = [UIColor whiteColor];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGRect frame = self.bounds;
    CGFloat horizontalSizeFirstPart = frame.size.width * 0.5;
    CGFloat horizontalSizeSecondPart = frame.size.width * 0.5 - 5.0;
    CGFloat verticalSizeFirstLine = frame.size.height * 0.6;
    CGFloat verticalSizeSecondLine = frame.size.height * 0.4 - 1.0;
    self.separatorInset = UIEdgeInsetsZero;
    
    self.typeLabel.frame = CGRectMake(0, 0, horizontalSizeFirstPart, verticalSizeFirstLine);
    self.groupLabel.frame = CGRectMake(0, verticalSizeFirstLine + 1.0, horizontalSizeFirstPart, verticalSizeSecondLine);
    self.timeLabel.frame = CGRectMake(horizontalSizeFirstPart + 5.0, 0, horizontalSizeSecondPart, verticalSizeFirstLine);
    self.repeatDaysLabel.frame = CGRectMake(horizontalSizeFirstPart + 5.0, verticalSizeFirstLine + 1.0, horizontalSizeSecondPart, verticalSizeSecondLine);
}

- (NSString *)repeateDaysString:(NSDictionary *)currentDict {
    NSArray *repeatDays = [currentDict objectForKey:@"selectedRepeatDays"];
    NSString *repeatDaysString = nil;
    for (NSString *repeatDay in repeatDays) {
        if (!repeatDaysString) {
            repeatDaysString = repeatDay;
        } else {
            repeatDaysString = [NSString stringWithFormat:@"%@/%@", repeatDaysString, repeatDay];
        }
    }
    return repeatDaysString;
}

- (NSString *)timeString:(NSDictionary *)currentDict {
    NSString *startTime = [currentDict objectForKey:@"startTime"];
    NSString *endTime = [currentDict objectForKey:@"endTime"];
    if (startTime && endTime) {
        return [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
    }
    return @"";
}

- (NSString *)groupNameString:(NSDictionary *)currentDict {
    NSArray *groupNames = [currentDict objectForKey:@"groupNames"];
    NSString *groupNameString = nil;
    for (NSString *groupName in groupNames) {
        if (!groupNameString) {
            groupNameString = groupName;
        } else {
            groupNameString = [NSString stringWithFormat:@"%@ / %@", groupNameString, groupName];
        }
    }
    return groupNameString;
}

- (NSString *)lightSettingTypeString:(SETTINGTYPE)settingType {
    switch (settingType) {
        case SETTINGTYPE_SHAKE:
            return @"SHAKE";
        case SETTINGTYPE_BRIGHTNESS:
            return @"BRIGHTNESS";
        case SETTINGTYPE_PROXIMITY:
            return @"PROXIMITY";
        case SETTINGTYPE_SUNRISE_SUNSET:
            return @"SUNRISE/SUNSET";
        default:
            return @"";
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
