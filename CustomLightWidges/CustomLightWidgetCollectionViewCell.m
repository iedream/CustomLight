//
//  CustomLightWidgetCollectionViewCell.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-17.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "CustomLightWidgetCollectionViewCell.h"
#import "WidgesSettingManager.h"

@interface  CustomLightWidgetCollectionViewCell()
@property (nonatomic, strong) UIButton *onButton;
@property (nonatomic, strong) UILabel *groupNameLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic) SETTINGTYPE settingType;

@property (nonatomic, strong) NSDictionary *currentDict;
@end

@implementation CustomLightWidgetCollectionViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setUp {
    self.onButton = [[UIButton alloc] init];
    self.onButton.layer.borderWidth = 1.0;
    self.onButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.onButton.titleLabel.textColor = [UIColor whiteColor];
    self.onButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.onButton addTarget:self action:@selector(toggleButton:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.onButton];
    self.groupNameLabel = [[UILabel alloc] init];
    self.groupNameLabel.textColor = [UIColor whiteColor];
    self.groupNameLabel.textAlignment = NSTextAlignmentCenter;
    self.groupNameLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.groupNameLabel];
    self.typeLabel = [[UILabel alloc] init];
    self.typeLabel.textColor = [UIColor whiteColor];
    self.typeLabel.textAlignment = NSTextAlignmentCenter;
    self.typeLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.typeLabel];
}

- (void)clearData {
    if (self.onButton) {
        [self.onButton removeFromSuperview];
    }
    if (self.typeLabel) {
        [self.typeLabel removeFromSuperview];
    }
    if (self.groupNameLabel) {
        [self.groupNameLabel removeFromSuperview];
    }
}

- (void)setUpCellWithData:(NSDictionary *)dict {
    self.currentDict = dict;
    [self clearData];
    [self setUp];
    [self drawRect:self.frame];
    self.groupNameLabel.text = dict[@"groupName"];
    switch ([dict[@"type"] integerValue]) {
        case SETTINGTYPE_BRIGHTNESS:
            self.typeLabel.text = @"Brightness";
            break;
        case SETTINGTYPE_PROXIMITY:
            self.typeLabel.text = @"Proximity";
            break;
        case SETTINGTYPE_SHAKE:
            self.typeLabel.text = @"Shake";
            break;
        default:
            break;
    }
    self.settingType = [dict[@"type"] integerValue];
    [self.onButton setNeedsDisplay];
    if ([dict[@"state"] boolValue] == YES) {
        [self.onButton setTitle:@"Turn Off" forState:UIControlStateNormal];
    } else {
        [self.onButton setTitle:@"Turn On" forState:UIControlStateNormal];
    }
}

- (void)toggleButton:(UIButton *)sender {
    BOOL state;
    if ([self.currentDict[@"state"] boolValue] == YES) {
        state = NO;
    } else {
        state = YES;
    }
    [[WidgesSettingManager sharedSettingManager] editActiveSettingWith:self.currentDict andState:state];
}

- (void)prepareForReuse {
    self.groupNameLabel.text = @"";
    self.typeLabel.text = @"";
    self.onButton.titleLabel.text = @"";
    self.backgroundColor = [UIColor grayColor];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGRect frame = self.bounds;
    CGFloat padding = 5.0;
    CGFloat elementHeight = (frame.size.height - 4.0 * padding) / 3.0;
    
    frame.origin.x = padding;
    frame.origin.y = padding;
    frame.size.width -= padding * 2.0;
    frame.size.height = elementHeight;
    self.typeLabel.frame = frame;
    
    frame.origin.y = frame.origin.y + frame.size.height + padding;
    self.groupNameLabel.frame = frame;
    
    frame.origin.y = frame.origin.y + frame.size.height + padding;
    self.onButton.frame = frame;
}
@end
