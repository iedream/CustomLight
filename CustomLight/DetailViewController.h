//
//  DetailViewController.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DETAILVIEWTYPE)
{
    DETAILVIEWTYPE_NONE,
    DETAILVIEWTYPE_SHAKE,
    DETAILVIEWTYPE_BRIGHTNESS,
    DETAILVIEWTYPE_PROXIMITY,
    DETAILVIEWTYPE_SETTINGS
};

@interface DetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) DETAILVIEWTYPE detailType;
@end

