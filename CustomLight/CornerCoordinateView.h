//
//  CornerCoordinateView.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-12.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class CornerCoordinateView;

@protocol CornerCoordinateViewDelegate <NSObject>
- (CLLocationCoordinate2D)getCurrentLocationCoordinate;
- (void)proceedToSave:(CornerCoordinateView *)cornerCoordinateView;
@end

@interface CornerCoordinateView : UIView
@property (nonatomic, strong) id<CornerCoordinateViewDelegate> delegate;
- (NSDictionary *)getRectangularDict;
@end
