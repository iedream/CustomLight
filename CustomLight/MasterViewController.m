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
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SettingManager sharedSettingManager];

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.objects = @[SHAKE_ACTION, BRIGHTNESS_ACTION, PROXIMITY_ACTION, SETTING_PAGE];
    
    UIActivityIndicatorView *spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinnerView.center = self.view.center;
    spinnerView.backgroundColor = [UIColor grayColor];
    spinnerView.alpha = 0.6;
    [self.view addSubview:spinnerView];
    [HueLight sharedHueLight].spinnerView = spinnerView;
    [[HueLight sharedHueLight] startLoading];

    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestAlwaysAuthorization];
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager requestLocation];
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    [self.locationManager startUpdatingLocation];
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
    self.geoRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"beaconRegion"];
    self.geoRegion.notifyOnEntry=YES;
    self.geoRegion.notifyOnExit=YES;
    [self.locationManager startMonitoringForRegion:self.geoRegion];
    
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
    [self.locationManager requestStateForRegion:self.geoRegion];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    //[self createRectangle];
    NSDictionary *activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SHAKE];
    if (activeDict) {
        CMAcceleration userAcceleration = self.motionManager.deviceMotion.userAcceleration;
        double totalAcceleration = sqrt(userAcceleration.x * userAcceleration.x +
                                        userAcceleration.y * userAcceleration.y + userAcceleration.z * userAcceleration.z);
        if (totalAcceleration > 0.7) {
            [[HueLight sharedHueLight] toggleLightOnOffWithActiveDict:activeDict];
        }
    }
    
    activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_BRIGHTNESS];
    if (activeDict) {
        float brightness = [UIScreen mainScreen].brightness;
        [[HueLight sharedHueLight] detectSurrondingBrightness:brightness andActiveDict:activeDict];
    }
//    CLLocationCoordinate2D coord = locations.firstObject.coordinate;
//    if ([self withinRange:coord]) {
//        NSLog(@"Inside");
//    } else {
//        NSLog(@"Outside");
//    }
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

- (void)createRectangle {
    CLLocationCoordinate2D corner1 = CLLocationCoordinate2DMake(+43.84679991,-79.42567142);
    CLLocationCoordinate2D corner2 = CLLocationCoordinate2DMake(+43.84680946,-79.42567033);
    CLLocationCoordinate2D corner3 = CLLocationCoordinate2DMake(+43.84682887,-79.42569271);
    CLLocationCoordinate2D corner4 = CLLocationCoordinate2DMake(+43.84679987,-79.42566907);
    
    self.lowestLatitude = corner1.latitude;
    self.highestLatitude = corner1.longitude;
    self.lowestLongitude = corner1.latitude;
    self.highestLongitude = corner1.longitude;
    
    for (int i = 0; i < 3; i++) {
        CLLocationCoordinate2D corner;
        if (i == 0) {
            corner = corner2;
        } else if (i == 1) {
            corner = corner3;
        } else if (i == 2) {
            corner = corner4;
        }
         
        if (corner.latitude < self.lowestLatitude) {
            self.lowestLatitude = corner.latitude - 0.00005;
        }
        if (corner.longitude < self.lowestLongitude) {
            self.lowestLongitude = corner.longitude - 0.00005;
        }
        if (corner.latitude > self.highestLatitude) {
            self.highestLatitude = corner.latitude + 0.00005;
        }
        if (corner.longitude > self.highestLongitude) {
            self.highestLongitude = corner.longitude + 0.0005;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSDictionary *activeDict = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_PROXIMITY];
    if (activeDict) {
        CLBeacon *beacon = beacons.firstObject;
        if (beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate) {
            [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:YES];
        } else {
            [[HueLight sharedHueLight] configureLightWithActiveDict:activeDict andLightSwitch:NO];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    //Start Ranging
    [manager startRangingBeaconsInRegion:self.geoRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
   [manager stopRangingBeaconsInRegion:self.geoRegion];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (state == CLRegionStateInside) {
        //Start Ranging
        [manager startRangingBeaconsInRegion:self.geoRegion];
    } else {
        [manager stopRangingBeaconsInRegion:self.geoRegion];
    }
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *text = [self.objects objectAtIndex:indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.navigationItem.title = text;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
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
