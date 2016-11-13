//
//  CornerCoordinateView.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-12.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "CornerCoordinateView.h"
#import <CoreLocation/CoreLocation.h>

@interface CornerCoordinateView()
@property (nonatomic, strong) UIButton *corner1Button;
@property (nonatomic, strong) UIButton *corner2Button;
@property (nonatomic, strong) UIButton *corner3Button;
@property (nonatomic, strong) UIButton *corner4Button;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic) CLLocationCoordinate2D corner1Coord;
@property (nonatomic) CLLocationCoordinate2D corner2Coord;
@property (nonatomic) CLLocationCoordinate2D corner3Coord;
@property (nonatomic) CLLocationCoordinate2D corner4Coord;
@end

@implementation CornerCoordinateView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.corner1Button = [[UIButton alloc] init];
        self.corner1Button.backgroundColor = [UIColor redColor];
        [self.corner1Button setTitle:@"Get Corner 1 Coordinate" forState:UIControlStateNormal];
        self.corner1Button.layer.cornerRadius = 3.0;
        self.corner1Button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.corner1Button addTarget:self action:@selector(corner1ButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.corner1Button];
        
        self.corner2Button = [[UIButton alloc] init];
        self.corner2Button.backgroundColor = [UIColor redColor];
        [self.corner2Button setTitle:@"Get Corner 2 Coordinate" forState:UIControlStateNormal];
        self.corner2Button.layer.cornerRadius = 3.0;
        self.corner2Button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.corner2Button addTarget:self action:@selector(corner2ButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.corner2Button];
        
        self.corner3Button = [[UIButton alloc] init];
        self.corner3Button.backgroundColor = [UIColor redColor];
        [self.corner3Button setTitle:@"Get Corner 3 Coordinate" forState:UIControlStateNormal];
        self.corner3Button.layer.cornerRadius = 3.0;
        self.corner3Button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.corner3Button addTarget:self action:@selector(corner3ButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.corner3Button];
        
        self.corner4Button = [[UIButton alloc] init];
        self.corner4Button.backgroundColor = [UIColor redColor];
        [self.corner4Button setTitle:@"Get Corner 4 Coordinate" forState:UIControlStateNormal];
        self.corner4Button.layer.cornerRadius = 3.0;
        self.corner4Button.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.corner4Button addTarget:self action:@selector(corner4ButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.corner4Button];
        
        self.submitButton = [[UIButton alloc] init];
        self.submitButton.backgroundColor = [UIColor redColor];
        [self.submitButton setTitle:@"Submit Locations" forState:UIControlStateNormal];
        self.submitButton.layer.cornerRadius = 3.0;
        self.submitButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.submitButton addTarget:self action:@selector(submitPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.submitButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat padding = 20.0;
    CGFloat buttonWidth = self.bounds.size.width * 0.8;
    CGFloat buttonHeight = (self.bounds.size.height - padding * 6.0) / 5;
    CGRect frame;
    
    frame.origin.x = padding;
    frame.origin.y = padding;
    frame.size.width = buttonWidth;
    frame.size.height = buttonHeight;
    self.corner1Button.frame = frame;
    
    frame.origin.y = CGRectGetMaxY(self.corner1Button.frame) + padding;
    self.corner2Button.frame = frame;
    
    frame.origin.y = CGRectGetMaxY(self.corner2Button.frame) + padding;
    self.corner3Button.frame = frame;
    
    frame.origin.y = CGRectGetMaxY(self.corner3Button.frame) + padding;
    self.corner4Button.frame = frame;

    frame.origin.y = CGRectGetMaxY(self.corner4Button.frame) + padding;
    self.submitButton.frame = frame;
}

- (void)submitPressed:(id)sender {
    [self.delegate proceedToSave:self];
    [self removeFromSuperview];
}

- (void)corner1ButtonPressed:(id)sender {
    self.corner1Button.alpha = 0.6;
    self.corner1Coord = [self.delegate getCurrentLocationCoordinate];
}

- (void)corner2ButtonPressed:(id)sender {
    self.corner2Button.alpha = 0.6;
    self.corner2Coord = [self.delegate getCurrentLocationCoordinate];
}

- (void)corner3ButtonPressed:(id)sender {
    self.corner3Button.alpha = 0.6;
    self.corner3Coord = [self.delegate getCurrentLocationCoordinate];
}

- (void)corner4ButtonPressed:(id)sender {
    self.corner4Button.alpha = 0.6;
    self.corner4Coord = [self.delegate getCurrentLocationCoordinate];
}

- (NSDictionary *)getRectangularDict {
    CGFloat lowestLatitude = self.corner1Coord.latitude;
    CGFloat highestLatitude = self.corner1Coord.longitude;
    CGFloat lowestLongitude = self.corner1Coord.latitude;
    CGFloat highestLongitude = self.corner1Coord.longitude;
    
    for (int i = 0; i < 3; i++) {
        CLLocationCoordinate2D corner;
        if (i == 0) {
            corner = self.corner2Coord;
        } else if (i == 1) {
            corner = self.corner3Coord;
        } else if (i == 2) {
            corner = self.corner4Coord;
        }
        
        if (corner.latitude < lowestLatitude) {
            lowestLatitude = corner.latitude;
        }
        if (corner.longitude < lowestLongitude) {
            lowestLongitude = corner.longitude;
        }
        if (corner.latitude > highestLatitude) {
            highestLatitude = corner.latitude;
        }
        if (corner.longitude > highestLongitude) {
            highestLongitude = corner.longitude;
        }
    }
    NSDictionary *dict = @{@"lowestLatitude": @(lowestLatitude), @"lowestLongitude": @(lowestLongitude), @"highestLatitude": @(highestLatitude), @"highestLongitude": @(highestLongitude)};
    return dict;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
