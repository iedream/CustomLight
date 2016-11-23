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
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    [self.locationManager requestAlwaysAuthorization];
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager requestLocation];
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    [self.locationManager startUpdatingLocation];
    
//    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
//    self.geoRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"beaconRegion"];
//    self.geoRegion.notifyOnEntry=YES;
//    self.geoRegion.notifyOnExit=YES;
//    [self.locationManager startMonitoringForRegion:self.geoRegion];
    
//    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
//    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    NSError *err;
//    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
//    [captureSession addInput:input];
//    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
//    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:  kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
//    [output setSampleBufferDelegate:self queue:queue];
//    [captureSession addOutput:output];
//    self.captureSession = captureSession;
//    [self.captureSession startRunning];
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
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    //[[HueLight sharedHueLight] detectSurrondingBrightness:brightnessValue];
}

- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if (self.geoRegion) {
        [self.locationManager requestStateForRegion:self.geoRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    //[self createRectangle];
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
        } else if (![[rangeDict objectForKey:@"useiBeacon"] boolValue]) {
            BOOL isWithinRange = [self withinRange:locations.firstObject.coordinate];
            if (isWithinRange) {
                [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:YES];
            } else {
                [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:NO];
            }
        }
    } else {
        [self clearRectangle];
    }
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

- (BOOL)detectShakeMotion:(CMDeviceMotion *)deviceMotion {
    CMAcceleration userAcceleration = deviceMotion.userAcceleration;
    double accelerationThreshold  = 0.3;
    if (fabs(userAcceleration.x) > accelerationThreshold || fabs(userAcceleration.y) > accelerationThreshold || fabs(userAcceleration.z) > accelerationThreshold)
    {
        float sensitivity = 1;
        float x1 = 0, x2 = 0, y1 = 0, y2 = 0, z1 = 0, z2 = 0;
        
        double totalAccelerationInXY = sqrt(userAcceleration.x * userAcceleration.x +
                                            userAcceleration.y * userAcceleration.y);
        
        if (0.85 < totalAccelerationInXY < 3.45) {
            x1 = userAcceleration.x;
            y1 = userAcceleration.y;
            z1 = userAcceleration.z;
            
            float change = fabs(x1-x2+y1-y2+z1-z2);
            if (sensitivity < change) {
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
