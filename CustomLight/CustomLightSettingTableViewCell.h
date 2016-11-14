//
//  CustomLightSettingTableViewCell.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-10.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingManager.h"

@interface CustomLightSettingTableViewCell : UITableViewCell
- (void)setCellTextWithCurrentDict:(NSDictionary *)currentDict andSettingType:(SETTINGTYPE)settingType;
- (NSDictionary *)currentDict;
@property (nonatomic, strong) NSDictionary *currentDict;
@property (nonatomic) SETTINGTYPE lightSettingType;
@end
