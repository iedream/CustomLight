//
//  CustomLightTableViewCell.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-06.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomLightTableViewCell : UITableViewCell
@property (nonatomic) BOOL isSelected;
- (void)setTitle:(NSString *)title;
- (void)getSelected;
@end
