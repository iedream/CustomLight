//
//  MasterViewController.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "HueLight.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MapKit/MapKit.h>
#import <CoreMotion/CoreMotion.h>
#import "SettingManager.h"

const NSString *SHAKE_ACTION = @"Detect Shake";
const NSString *BRIGHTNESS_ACTION = @"Detect Brightness";
const NSString *PROXIMITY_ACTION = @"Detect Proximity";
const NSString *SETTING_PAGE = @"Setting Page";

@interface MasterViewController ()

@property NSArray *objects;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *geoRegion;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic) CGFloat lowestLatitude;
@property (nonatomic) CGFloat lowestLongitude;
@property (nonatomic) CGFloat highestLatitude;
@property (nonatomic) CGFloat highestLongitude;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSTimer *iBeaconProximityTimer;
@property (nonatomic, strong) NSTimer *shakeTimer;
@property (nonatomic, strong) NSTimer *checkStateTimer;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SettingManager sharedSettingManager];

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.objects = @[SHAKE_ACTION, BRIGHTNESS_ACTION, PROXIMITY_ACTION, SETTING_PAGE];

    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager requestAlwaysAuthorization];
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.allowsBackgroundLocationUpdates = YES;
        [self.locationManager startMonitoringSignificantLocationChanges];
    }

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    blurEffectView.alpha = 0.9;
    [self.view addSubview:blurEffectView];
    [HueLight sharedHueLight].visualEffectView = blurEffectView;
    
    UIActivityIndicatorView *spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinnerView.center = blurEffectView.center;
    [self.view addSubview:spinnerView];
    [HueLight sharedHueLight].spinnerView = spinnerView;
    [[HueLight sharedHueLight] startLoading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpConnectionDone:) name:@"startObserveStateChange" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeConnection:) name:@"stopObserveStateChange" object:nil];
}

- (void)setUpConnectionDone:(NSNotification *)notif {
    [self checkLocation:NO];
    [self.locationManager startUpdatingLocation];
    self.locationManager.headingFilter = 45.0;
    [self.locationManager startUpdatingHeading];
}

- (void)closeConnection: (NSNotification *)notif {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if (self.geoRegion) {
        [self.locationManager requestStateForRegion:self.geoRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

}

- (void)checkState:(CLLocation *)location {
    [[HueLight sharedHueLight] refreshCache];
    
    NSDictionary *activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SHAKE];
    if (activeDict) {
        BOOL shakeDetected = [self detectShakeMotion:self.motionManager.deviceMotion];
        if (shakeDetected) {
            [[HueLight sharedHueLight] toggleLightOnOffWithActiveDict:activeDict];
        }
    }
    
    activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_BRIGHTNESS];
    if (activeDict) {
        float brightness = [UIScreen mainScreen].brightness;
        [[HueLight sharedHueLight] detectSurrondingBrightness:brightness andActiveDict:activeDict];
    }
    
    activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_PROXIMITY];
    if (activeDict) {
        NSDictionary *rangeDict = [activeDict objectForKey:@"range"];
        if ([[rangeDict objectForKey:@"useiBeacon"] boolValue] && !self.geoRegion) {
            [self clearRectangle];
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:rangeDict[@"iBeaconUUID"]];
            self.geoRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"beaconRegion"];
            self.geoRegion.notifyOnEntry=YES;
            self.geoRegion.notifyOnExit=YES;
            if (self.geoRegion) {
                [self.locationManager startMonitoringForRegion:self.geoRegion];
            }
        } else if (![[rangeDict objectForKey:@"useiBeacon"] boolValue] && !self.lowestLatitude && !self.lowestLongitude && !self.highestLatitude && !self.highestLongitude) {
            [self createRectangleWithRangeDict:rangeDict];
            [self checkLocation:YES];
        } else if (![[rangeDict objectForKey:@"useiBeacon"] boolValue]) {
            BOOL isWithinRange = [self withinRange:location.coordinate];
            if (isWithinRange) {
                [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:YES];
            } else {
                [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:NO];
            }
        }
    } else {
        [self checkLocation:NO];
        [self clearRectangle];
    }
}

- (void)checkStateFinished:(NSTimer *)timer {
    self.locationManager.headingFilter = 45.0;
    [self.locationManager startUpdatingHeading];
    [self.checkStateTimer invalidate];
}

- (void)checkLocation:(BOOL)checkLocation {
    if (!checkLocation && self.locationManager.desiredAccuracy != kCLLocationAccuracyThreeKilometers) {
        self.locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    } else if (checkLocation && self.locationManager.desiredAccuracy != kCLLocationAccuracyBest){
        NSString *distance = @"0.5m";
        MKDistanceFormatter *mdf = [[MKDistanceFormatter alloc] init];
        mdf.units = MKDistanceFormatterUnitsMetric;
        CLLocationDistance preferedDistance = [mdf distanceFromString:distance];
        self.locationManager.distanceFilter = preferedDistance;
        self.locationManager.desiredAccuracy = preferedDistance;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (self.checkStateTimer && !self.checkStateTimer.valid) {
        self.checkStateTimer = nil;
    } else if (!self.checkStateTimer) {
        [self.locationManager stopUpdatingHeading];
        self.checkStateTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkStateFinished:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer: self.checkStateTimer forMode: NSDefaultRunLoopMode];
    }
    [self checkState:self.locationManager.location];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self checkState:locations.firstObject];
}

- (BOOL)withinRange:(CLLocationCoordinate2D )currentPoint {
    if (currentPoint.latitude < self.highestLatitude && currentPoint.latitude > self.lowestLatitude) {
        if (currentPoint.longitude < self.highestLongitude && currentPoint.longitude > self.lowestLongitude) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)clearRectangle {
    self.highestLongitude = 0;
    self.lowestLongitude = 0;
    self.highestLatitude = 0;
    self.lowestLatitude = 0;
}

- (void)createRectangleWithRangeDict:(NSDictionary *)rangeDict {
    
    float rangeValue = [rangeDict[@"rangeValue"] floatValue] / 100000;
    self.highestLatitude = [rangeDict[@"highestLatitude"] floatValue] + rangeValue;
    self.lowestLatitude = [rangeDict[@"lowestLatitude"] floatValue] - rangeValue;
    self.highestLongitude = [rangeDict[@"highestLongitude"] floatValue] + rangeValue;
    self.lowestLongitude = [rangeDict[@"lowestLongitude"] floatValue] - rangeValue;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSDictionary *activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_PROXIMITY];
    if (activeDict) {
        CLBeacon *beacon = beacons.firstObject;
        NSDictionary *rangeDict = [activeDict objectForKey:@"range"];
        BOOL isWithinRange;
        if ([rangeDict[@"rangeValue"] isEqualToString:@"Far"]) {
            isWithinRange = YES;
        } else if ([rangeDict[@"rangeValue"] isEqualToString:@"Near"]) {
            if (beacon.proximity != CLProximityFar) {
                isWithinRange = YES;
            } else {
                isWithinRange = NO;
            }
        } else if ([rangeDict[@"rangeValue"] isEqualToString:@"Immediate"]) {
            if (beacon.proximity == CLProximityImmediate || beacon.proximity == CLProximityUnknown) {
                isWithinRange = YES;
            } else {
                isWithinRange = NO;
            }
        } else {
            return;
        }
        
        if (isWithinRange) {
            [self.iBeaconProximityTimer invalidate];
            [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:YES];
        } else {
            if (!self.iBeaconProximityTimer.valid) {
                self.iBeaconProximityTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(iBeaconProximityTimerExpire:) userInfo:activeDict repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer: self.iBeaconProximityTimer forMode: NSDefaultRunLoopMode];
            }
        }
    }
}

- (void)iBeaconProximityTimerExpire:(NSTimer *)timer {
    [[HueLight sharedHueLight] configureLightWithActiveDict:timer.userInfo andLightSwitch:NO];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    //Start Ranging
    self.geoRegion = region;
    [manager startRangingBeaconsInRegion:self.geoRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (self.geoRegion) {
        [manager stopRangingBeaconsInRegion:self.geoRegion];
        self.geoRegion = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (state == CLRegionStateInside) {
        //Start Ranging
        self.geoRegion = region;
        [manager startRangingBeaconsInRegion:self.geoRegion];
    } else {
        if (self.geoRegion) {
            [manager stopRangingBeaconsInRegion:self.geoRegion];
            self.geoRegion = nil;
        }
    }
}

- (void)shakeTimerExpire:(NSTimeInterval *)timer {
    self.shakeTimer = nil;
}

- (BOOL)detectShakeMotion:(CMDeviceMotion *)deviceMotion {
    if (self.shakeTimer) {
        return false;
    }

    CMAcceleration userAcceleration = deviceMotion.userAcceleration;
    double accelerationThreshold  = 0.7;
    if (fabs(userAcceleration.x) > accelerationThreshold || fabs(userAcceleration.y) > accelerationThreshold || fabs(userAcceleration.z) > accelerationThreshold)
    {
        float sensitivity = 1.0;
        float x1 = 0, x2 = 0, y1 = 0, y2 = 0, z1 = 0, z2 = 0;
        
        double totalAccelerationInXY = sqrt(userAcceleration.x * userAcceleration.x +
                                            userAcceleration.y * userAcceleration.y);
        
        if (0.85 < totalAccelerationInXY < 3.45) {
            x1 = userAcceleration.x;
            y1 = userAcceleration.y;
            z1 = userAcceleration.z;
            
            float change = fabs(x1-x2+y1-y2+z1-z2);
            if (sensitivity < change) {
                NSLog(@"detect shake");
                self.shakeTimer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(shakeTimerExpire:) userInfo:nil repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer: self.shakeTimer forMode: NSDefaultRunLoopMode];
                return  YES;
            }
        }
    }
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [self becomeFirstResponder];
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CLLocationCoordinate2D)getCurrentLocation {
    return self.locationManager.location.coordinate;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *text = [self.objects objectAtIndex:indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.navigationItem.title = text;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        controller.delegate = self;
        
        if ([text isEqualToString:SHAKE_ACTION]) {
            controller.detailType = DETAILVIEWTYPE_SHAKE;
        } else if ([text isEqualToString:BRIGHTNESS_ACTION]) {
            controller.detailType = DETAILVIEWTYPE_BRIGHTNESS;
        } else if ([text isEqualToString:PROXIMITY_ACTION]) {
            controller.detailType = DETAILVIEWTYPE_PROXIMITY;
        } else if ([text isEqualToString:SETTING_PAGE]) {
            controller.detailType = DETAILVIEWTYPE_SETTINGS;
        } else {
            controller.detailType = DETAILVIEWTYPE_NONE;
        }
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *text = self.objects[indexPath.row];
    cell.textLabel.text = text;
    return cell;
}


@end
