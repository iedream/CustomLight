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

@interface MasterViewController ()

@property NSMutableArray *objects;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLRegion *geoRegion;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic) CGFloat lowestLatitude;
@property (nonatomic) CGFloat lowestLongitude;
@property (nonatomic) CGFloat highestLatitude;
@property (nonatomic) CGFloat highestLongitude;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessChanged:) name:UIScreenBrightnessDidChangeNotification object:nil];

    
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    [self.locationManager requestAlwaysAuthorization];
//    if ([CLLocationManager locationServicesEnabled]) {
//        [self.locationManager requestLocation];
//    }
//    [self.locationManager startUpdatingLocation];
    
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *err;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
    [captureSession addInput:input];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    [captureSession addOutput:output];
    self.captureSession = captureSession;
    [self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    NSLog(@"new brighness");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationManager requestStateForRegion:self.geoRegion];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self createRectangle];
    CLLocationCoordinate2D coord = locations.firstObject.coordinate;
    if ([self withinRange:coord]) {
        NSLog(@"Inside");
    } else {
        NSLog(@"Outside");
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
            self.lowestLatitude = corner.latitude - 0.0001;
        }
        if (corner.longitude < self.lowestLongitude) {
            self.lowestLongitude = corner.longitude - 0.0001;
        }
        if (corner.latitude > self.highestLatitude) {
            self.highestLatitude = corner.latitude + 0.0001;
        }
        if (corner.longitude > self.highestLongitude) {
            self.highestLongitude = corner.longitude + 0.0001;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Hello");
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Bye");
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
//    if (state == CLRegionStateInside) {
//        NSLog(@"Inside");
//    } else if (state == CLRegionStateOutside) {
//        NSLog(@"Outside");
//    }
    float differenceX = fabsf(self.locationManager.location.coordinate.latitude - region.center.latitude);
    float differenceY = fabsf(self.locationManager.location.coordinate.longitude - region.center.longitude);
    if (differenceX > 0.0001 || differenceY > 0.0001 ) {
        NSLog(@"Turning Off");
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
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

    NSDate *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)brightnessChanged:(NSNotification *)notif {
    [[HueLight sharedHueLight] detectSurrondingBrightness];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
        
        self.geoRegion = [[CLCircularRegion alloc]initWithCenter:self.locationManager.location.coordinate radius:10 identifier:@"LivingRoomRegion"];
        [self.locationManager startMonitoringForRegion:self.geoRegion];
        // User was shaking the device. Post a notification named "shake".
        [[HueLight sharedHueLight] toggleLightOnOff];
    }
}


@end
