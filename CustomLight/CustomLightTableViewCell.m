//
//  CustomLightTableViewCell.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-06.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "CustomLightTableViewCell.h"
#import "SettingManager.h"

@interface CustomLightTableViewCell()
@property (nonatomic, strong) UILabel *textView;
@property (nonatomic, strong) UIImageView *customImageView;
@end

@implementation CustomLightTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.textView = [[UILabel alloc] init];
    self.textView.adjustsFontSizeToFitWidth = YES;
    
    UIImage *image = [UIImage imageNamed:@"checkMark.png"];
    self.customImageView = [[UIImageView alloc] initWithImage:image];
    self.customImageView.hidden = YES;
    
    [self addSubview:self.textView];
    [self addSubview:self.customImageView];
}

- (void)prepareForReuse {
    self.textView.text = @"";
    self.customImageView.hidden = YES;
}

- (void)setTitle:(NSString *)title {
    self.textView.text = title;
}

- (void)applyCurrentSetting:(NSString *)currentActiveKey {
    NSDictionary *currentActiveDict = [[SettingManager sharedSettingManager] getDataForUniqueKey:currentActiveKey];
    NSArray *groupNames = currentActiveDict[@"groupNames"];
    for (NSString *groupName in groupNames) {
        if ([groupName isEqualToString:self.textView.text]) {
            self.isSelected = YES;
            self.customImageView.hidden = NO;
        }
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGRect frame = self.bounds;
    CGFloat boundry = frame.size.width * 0.7;
    self.separatorInset = UIEdgeInsetsZero;
    
    self.textView.frame = CGRectMake(0, 0, boundry, frame.size.height);
    self.customImageView.frame = CGRectMake(boundry + 10.0, 0, frame.size.width - boundry - 20.0 , frame.size.height);
}

- (void)getSelected {
    if (self.isSelected) {
        self.isSelected = NO;
        self.customImageView.hidden = YES;
    } else {
        self.isSelected = YES;
        self.customImageView.hidden = NO;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //[super setSelected:selected animated:animated];
}

@end
