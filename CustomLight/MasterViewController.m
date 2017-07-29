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
const NSString *SUNRISE_SUNSET_ACTION = @"Detect Sunrise/Sunset";
const NSString *SETTING_PAGE = @"Setting Page";

@interface MasterViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;

@property NSArray *objects;
@property (nonatomic, strong) NSMutableArray *beaconRegionArray;
@property (nonatomic, strong) NSMutableDictionary *geoRegionDict;
@property (nonatomic, strong) CLCircularRegion *homeRegion;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) NSTimer *iBeaconProximityTimer;
@property (nonatomic, strong) NSTimer *activeSettingTimer;

@property (nonatomic, strong) NSOperationQueue *backgroundQueue;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAllSettings];
}

- (void)initAllSettings {
    if (self.locationManager) {
        return;
    }
    
    [SettingManager sharedSettingManager];
    
    self.beaconRegionArray = [[NSMutableArray alloc] init];
    self.geoRegionDict = [[NSMutableDictionary alloc] init];
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.objects = @[SHAKE_ACTION, BRIGHTNESS_ACTION, PROXIMITY_ACTION, SUNRISE_SUNSET_ACTION, SETTING_PAGE];
    
    self.backgroundQueue = [[NSOperationQueue alloc] init];
    
    self.motionManager = [[CMMotionManager alloc] init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager requestAlwaysAuthorization];
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    UIBarButtonItem *currentLocationButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStylePlain target:self action:@selector(setCurrentLocation)];
    
    self.navigationItem.rightBarButtonItem = currentLocationButton;
    
    if ([SettingManager sharedSettingManager].homeCoord.latitude != 0 || [SettingManager sharedSettingManager].homeCoord.longitude != 0) {
        self.homeRegion = [[CLCircularRegion alloc] initWithCenter:[SettingManager sharedSettingManager].homeCoord radius:10 identifier:@"home"];
        self.homeRegion.notifyOnExit = YES;
        self.homeRegion.notifyOnEntry = YES;
        [self.locationManager startMonitoringForRegion:self.homeRegion];
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
    
    self.activeSettingTimer = [NSTimer timerWithTimeInterval:3600 target:self selector:@selector(checkForData) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer: self.activeSettingTimer forMode: NSDefaultRunLoopMode];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForSunsetSunrise) name:@"checkForSunriseSunset" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForData) name:@"checkForData" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setProximityCoord) name:@"AboutToSetProximityCoordinate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetGeoRegion) name:@"DoneSettingProximityCoordinate" object:nil];
}

- (void)setCurrentLocation {
    [SettingManager sharedSettingManager].homeCoord = self.locationManager.location.coordinate;
}

- (void)checkForData {
    if ([[SettingManager sharedSettingManager] getFutureActiveSettingWith:SETTINGTYPE_SHAKE].count > 0) {
        self.motionManager.deviceMotionUpdateInterval = 0.5;
    } else if ([[SettingManager sharedSettingManager] getFutureActiveSettingWith:SETTINGTYPE_BRIGHTNESS].count > 0){
        self.motionManager.deviceMotionUpdateInterval = 60;
    } else {
        self.motionManager.deviceMotionUpdateInterval = 3600;
    }
    
     [self clearGeoRegion:@[]];
    [self checkState:self.locationManager.location];
}

- (void)checkForSunsetSunrise {
    [[HueLight sharedHueLight] getSunriseSunsetTime:self.locationManager.location.coordinate];
}

- (void)setUpConnection {
    if (!self.locationManager) {
        [self initAllSettings];
        [[HueLight sharedHueLight] hasEnterRange];
    }
    [self checkLocation:NO];
    [self.locationManager startUpdatingLocation];
    self.motionManager.deviceMotionUpdateInterval = 5;
    [self.motionManager startDeviceMotionUpdatesToQueue:self.backgroundQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        [self checkState:self.locationManager.location];
    }];
}

- (void)closeConnection {
    [[HueLight sharedHueLight] startLoading];
    [self.locationManager startMonitoringForRegion:self.homeRegion];
    [self.locationManager stopUpdatingLocation];
    [self.motionManager stopDeviceMotionUpdates];
}

- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if ([region.identifier isEqualToString:@"home"]) {
        [self.locationManager requestStateForRegion:self.homeRegion];
    } else {
        [self.locationManager requestStateForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

}

- (void)checkState:(CLLocation *)location {
    [[HueLight sharedHueLight] refreshCache];
    
    NSArray *activeDictArr = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SHAKE];
    for (NSDictionary *dict in activeDictArr) {
        BOOL shakeDetected = [self detectShakeMotion:self.motionManager.deviceMotion];
        if (shakeDetected) {
            [[HueLight sharedHueLight] toggleLightOnOffWithActiveDict:dict];
        }
    }
    
    activeDictArr = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_BRIGHTNESS];
    for (NSDictionary *dict in activeDictArr) {
        float brightness = [UIScreen mainScreen].brightness;
        [[HueLight sharedHueLight] detectSurrondingBrightness:brightness andActiveDict:dict];
    }
    
    activeDictArr = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_PROXIMITY];
    NSMutableArray *currentBeaconRange = [[NSMutableArray alloc] init];
    NSMutableArray *currentGeoRange = [[NSMutableArray alloc] init];;
    for (NSDictionary *dict in activeDictArr) {
        NSDictionary *rangeDict = [dict objectForKey:@"range"];
        NSString *uniqueKey = [dict[@"uniqueKey"] stringValue];
        if ([[rangeDict objectForKey:@"useiBeacon"] boolValue]) {
            [currentBeaconRange addObject:uniqueKey];
        } else {
            [currentGeoRange addObject:uniqueKey];
        }
        
        if ([[rangeDict objectForKey:@"useiBeacon"] boolValue] && ![self.beaconRegionArray containsObject:uniqueKey]) {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:rangeDict[@"iBeaconUUID"]];
            CLBeaconRegion *geoRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:uniqueKey];
            geoRegion.notifyOnEntry=YES;
            geoRegion.notifyOnExit=YES;
            [self.beaconRegionArray addObject:uniqueKey];
            [self.locationManager startMonitoringForRegion:geoRegion];
        } else if (![[rangeDict objectForKey:@"useiBeacon"] boolValue] && ![self.geoRegionDict objectForKey:uniqueKey]) {
            NSDictionary *geoDict = [self createRectangleWithRangeDict:rangeDict];
            [self.geoRegionDict setObject:geoDict forKey:uniqueKey];
            [self checkLocation:YES];
        } else if (![[rangeDict objectForKey:@"useiBeacon"] boolValue]) {
            BOOL isWithinRange = [self withinRange:location.coordinate geoDict:[self.geoRegionDict objectForKey:uniqueKey]];
            if (isWithinRange) {
                [[HueLight sharedHueLight] configureLightWithActiveDict:dict andLightSwitch:YES];
            } else {
                [[HueLight sharedHueLight] configureLightWithActiveDict:dict andLightSwitch:NO];
            }
        }
    }
    [self resetProximityRelatedSetting:currentBeaconRange currentRangeRegion:currentGeoRange];
}

- (void)resetProximityRelatedSetting:(NSArray *)currentBeaconRegion currentRangeRegion:(NSArray *)currentRangeRegion {
    [self clearBeaconRegion:currentBeaconRegion];
    [self clearGeoRegion:currentRangeRegion];
}

- (void)checkLocation:(BOOL)checkLocation {
    NSString *distance = @"1m";
    MKDistanceFormatter *mdf = [[MKDistanceFormatter alloc] init];
    mdf.units = MKDistanceFormatterUnitsMetric;
    CLLocationDistance preferedDistance = [mdf distanceFromString:distance];

    
    if (!checkLocation && self.locationManager.desiredAccuracy != kCLLocationAccuracyThreeKilometers) {
        self.locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    } else if (checkLocation && self.locationManager.desiredAccuracy != preferedDistance){
        self.locationManager.distanceFilter = preferedDistance;
        self.locationManager.desiredAccuracy = preferedDistance;
    }
}

- (void)setProximityCoord {
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self checkState:locations.firstObject];
}

- (BOOL)withinRange:(CLLocationCoordinate2D )currentPoint geoDict:(NSDictionary *)geoDict{
    CGFloat highestLatitude = [geoDict[@"highestLatitude"] floatValue];
    CGFloat highestLongitude = [geoDict[@"highestLongitude"] floatValue];
    CGFloat lowestLatitude = [geoDict[@"lowestLatitude"] floatValue];
    CGFloat lowestLongitude = [geoDict[@"lowestLongitude"] floatValue];
    if (currentPoint.latitude < highestLatitude && currentPoint.latitude > lowestLatitude) {
        if (currentPoint.longitude < highestLongitude && currentPoint.longitude > lowestLongitude) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)clearBeaconRegion:(NSArray *)beaconRegionToKeep {
    if (self.beaconRegionArray.count < 1) {
        return;
    }
    
    for (CLRegion *region in self.locationManager.monitoredRegions.copy) {
        if (![beaconRegionToKeep containsObject:region.identifier] && [self.beaconRegionArray containsObject: region.identifier] ) {
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            [self.locationManager stopMonitoringForRegion:region];
            [self.beaconRegionArray removeObject:region.identifier];
        }
    }
}

- (void)resetGeoRegion {
    [self.geoRegionDict removeAllObjects];
}

- (void)clearGeoRegion:(NSArray *)geoRegionToKeep {
    if (self.geoRegionDict.count < 1) {
        return;
    }
    if (geoRegionToKeep.count < 1) {
        [self checkLocation:NO];
    }
    for (NSString *key in self.geoRegionDict.allKeys.copy) {
        if (![geoRegionToKeep containsObject:key]) {
            [self.geoRegionDict removeObjectForKey:key];
        }
    }
}

- (NSDictionary *)createRectangleWithRangeDict:(NSDictionary *)rangeDict {
    float rangeValue = [rangeDict[@"rangeValue"] floatValue] / 100000;
    CGFloat highestLatitude = [rangeDict[@"highestLatitude"] floatValue] + rangeValue;
    CGFloat lowestLatitude = [rangeDict[@"lowestLatitude"] floatValue] - rangeValue;
    CGFloat highestLongitude = [rangeDict[@"highestLongitude"] floatValue] + rangeValue;
    CGFloat lowestLongitude = [rangeDict[@"lowestLongitude"] floatValue] - rangeValue;
    NSDictionary *dict = @{@"highestLatitude": @(highestLatitude), @"lowestLatitude": @(lowestLatitude), @"highestLongitude": @(highestLongitude), @"lowestLongitude": @(lowestLongitude)};
    return dict;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSArray *activeDictArr = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_PROXIMITY];
    for (NSDictionary *dict in activeDictArr) {
        CLBeacon *beacon = beacons.firstObject;
        NSDictionary *rangeDict = [dict objectForKey:@"range"];
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
            [[HueLight sharedHueLight] configureLightWithActiveDict:dict andLightSwitch:YES];
        } else {
            if (!self.iBeaconProximityTimer.valid) {
                self.iBeaconProximityTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(iBeaconProximityTimerExpire:) userInfo:dict repeats:NO];
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
    if ([region.identifier isEqualToString:@"home"]) {
        [self setUpConnection];
    } else {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [manager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region.identifier isEqualToString:@"home"]) {
        [self closeConnection];
    } else {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [manager stopRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if ([region.identifier isEqualToString:@"home"]) {
        if (state == CLRegionStateInside) {
            [self setUpConnection];
        } else if (state == CLRegionStateOutside){
            [self closeConnection];
        }
    } else {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (state == CLRegionStateInside) {
            [manager startRangingBeaconsInRegion:beaconRegion];
        } else if (state == CLRegionStateOutside){
            [manager stopRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (BOOL)detectShakeMotion:(CMDeviceMotion *)deviceMotion {
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
                return YES;
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
        } else if ([text isEqualToString:SUNRISE_SUNSET_ACTION]) {
            controller.detailType = DETAILVIEWTYPE_SUNRISE_SUNSET;
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
