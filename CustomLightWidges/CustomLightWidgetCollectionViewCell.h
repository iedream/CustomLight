//
//  CustomLightWidgetCollectionViewCell.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-17.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SETTINGTYPE)
{
    SETTINGTYPE_NONE,
    SETTINGTYPE_BRIGHTNESS,
    SETTINGTYPE_PROXIMITY,
    SETTINGTYPE_SHAKE,
    SETTINGTYPE_SUNRISE_SUNSET
};

@interface CustomLightWidgetCollectionViewCell : UICollectionViewCell
- (void)setUpCellWithData:(NSString *)uniqueKey;
@end
