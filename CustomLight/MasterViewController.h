//
//  MasterViewController.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;


@end

