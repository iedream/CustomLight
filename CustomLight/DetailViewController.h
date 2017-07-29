//
//  DetailViewController.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CornerCoordinateView.h"

typedef NS_ENUM(NSInteger, DETAILVIEWTYPE)
{
    DETAILVIEWTYPE_NONE,
    DETAILVIEWTYPE_SHAKE,
    DETAILVIEWTYPE_BRIGHTNESS,
    DETAILVIEWTYPE_PROXIMITY,
    DETAILVIEWTYPE_SUNRISE_SUNSET,
    DETAILVIEWTYPE_SETTINGS
};

@protocol DetailViewControllerDelegate <NSObject>
- (CLLocationCoordinate2D)getCurrentLocation;
@end

@interface DetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CornerCoordinateViewDelegate>
@property (nonatomic) DETAILVIEWTYPE detailType;
@property (nonatomic, weak) id<DetailViewControllerDelegate> delegate;
@end

