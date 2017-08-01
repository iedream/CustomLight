//
//  HueLight.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "HueLight.h"
#import "SettingManager.h"
#import <HueSDK_iOS/HueSDK.h>
const NSString *BRIGHTNESS = @"Brightness";
const NSString *PROXIMITY = @"Proximity";
const NSString *SHAKE = @"Shake";
const NSString *SUNRISESUNSET = @"Sunrise/Sunset";

@interface HueLight()
@property (nonatomic, strong) PHHueSDK *hueSDK;
@property (nonatomic, strong) PHBridgeSearching *bridgeSearching;
@property (nonatomic, strong) PHNotificationManager *hueNotificationManager;
@property (nonatomic, strong) PHBridgeResourcesCache *cache;
@property (nonatomic, strong) PHBridgeSendAPI *sendAPI;

@property (nonatomic, strong) NSString *ipAddress;

@property (nonatomic) BOOL actionInProgress;
@property (nonatomic, strong) NSTimer *setupTimer;
@property (nonatomic, strong) NSTimer *sunriseTimer;
@property (nonatomic, strong) NSTimer *sunsetTimer;

@property (nonatomic, strong) NSMutableDictionary *settings;
@end

@implementation HueLight

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hueSDK = [[PHHueSDK alloc]init];
        [self.hueSDK enableLogging:NO];
        [self.hueSDK startUpSDK];
        
        
        self.hueNotificationManager = [PHNotificationManager defaultManager];
        self.sendAPI = [[PHBridgeSendAPI alloc] init];
        if ([[SettingManager sharedSettingManager] readBridgeSetupFromPlistSetting]) {
            [self setUpConnection];
        } else {
            [self authenticate];
        }
    }
    return self;
}

- (void)displayMessage:(UIAlertController *)alertView {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        return;
    }

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        while ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
            
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            if(vc.presentedViewController == nil){
                [vc presentViewController:alertView animated:true completion:nil];
            }
        });
    });
}

- (void)selectHueBridge:(NSArray *)hueBridges completion:(void (^)(NSUInteger index))completion
{
    UIAlertController *bridgeSelection = [UIAlertController alertControllerWithTitle:@"Select Philip Hue Bridge" message:@"Please select your hue bridge" preferredStyle:UIAlertControllerStyleAlert];
    for (NSString *hueBridge in hueBridges) {
        UIAlertAction *currentAction = [UIAlertAction actionWithTitle:hueBridge style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completion([hueBridges indexOfObject:hueBridge]);
        }];
        [bridgeSelection addAction:currentAction];
    }
    [self displayMessage:bridgeSelection];
}

// MARK: - Spinner Related View -

- (void)startLoading {
    self.visualEffectView.hidden = NO;
    [self.spinnerView startAnimating];
}

- (void)stopLoading {
    self.visualEffectView.hidden = YES;
    [self.spinnerView stopAnimating];
}

- (void)hasEnterRange {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.visualEffectView.effect = blurEffect;
}

// MARK: - Hue Light Setup -

- (void)refreshCache {
    if (_actionInProgress) {
        return;
    }
    
    if (![PHBridgeResourcesReader readBridgeResourcesCache]) {
        [self setUpConnection];
    }
}

- (void)authenticate {
    if (_actionInProgress) {
        return;
    }
    _actionInProgress = YES;
    
    UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"Authenticate Bridge" message:@"Press big button on bridge" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.bridgeSearching = [[PHBridgeSearching alloc]initWithUpnpSearch:YES andPortalSearch:YES andIpAddressSearch:YES];
        [self.bridgeSearching startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
            if (bridgesFound.count < 1) {
                UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"No Bridge Found" message:@"Cannot found bridge on current wifi network" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {;
                    _actionInProgress = NO;
                    [self authenticate];
                }];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [authenticateAlert addAction:okAction];
                [authenticateAlert addAction:tryAgainAction];
                [self displayMessage:authenticateAlert];
            } else {
                if (bridgesFound.allKeys.count > 1) {
                    [self selectHueBridge:bridgesFound.allKeys completion:^(NSUInteger index) {
                        [self authentication:bridgesFound.allKeys[index] ipAddress:bridgesFound.allValues[index]];
                    }];
                } else {
                    [self authentication:bridgesFound.allKeys.firstObject ipAddress:bridgesFound.allValues.firstObject];
                }
            }
        }];
    }];
    [authenticateAlert addAction:okAction];
    [self displayMessage:authenticateAlert];
}

- (void)authentication:(NSString *)bridgeId ipAddress:(NSString *)ipAddress {
    [self.hueSDK setBridgeToUseWithId:bridgeId ipAddress:ipAddress];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationSuccess:) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION];
    [self.hueSDK startPushlinkAuthentication];
}

- (void)setUpConnection {
    if (_actionInProgress) {
        return;
    }
    _actionInProgress = YES;
    self.setupTimer = [NSTimer scheduledTimerWithTimeInterval:180.0 target:self selector:@selector(clearSetupTimer) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer: self.setupTimer forMode: NSDefaultRunLoopMode];
    
    [self.hueNotificationManager registerObject:self withSelector:@selector(localConnection:) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(noLocalConnection:) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    
    [self.hueSDK setLocalHeartbeatInterval:5.0f forResourceType:RESOURCES_LIGHTS];
    [self.hueSDK setLocalHeartbeatInterval:300.0f forResourceType:RESOURCES_GROUPS];
    
    [self.hueSDK enableLocalConnection];
}

- (void)clearSetupTimer {
    _actionInProgress = NO;
    [self.setupTimer invalidate];
    [self authenticate];
}

- (void)authenticationSuccess:(NSNotification *)notif {
    [[SettingManager sharedSettingManager] writeBridgeSetupToPlistSetting];
    _actionInProgress = NO;
    self.hueNotificationManager = [PHNotificationManager defaultManager];
    self.sendAPI = [[PHBridgeSendAPI alloc] init];
    
    [self setUpConnection];
}

- (void)authenticationFailure:(NSNotification *)notif {
    if (notif.userInfo[@"progressPercentage"]) {
        return;
    }
    UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"Authentication Failed" message:@"Authentication progress failed" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _actionInProgress = NO;
        [self authenticate];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [authenticateAlert addAction:okAction];
    [authenticateAlert addAction:tryAgainAction];
    [self displayMessage:authenticateAlert];
}

- (void)noLocalConnection:(NSNotification *)notif {
    _actionInProgress = NO;
}

- (void)localConnection:(NSNotification *)notif {
    if (self.setupTimer) {
        _actionInProgress = NO;
        [self.setupTimer invalidate];
        self.setupTimer = nil;
        [self stopLoading];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForData" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForSunriseSunset" object:nil];
    }
    if ([PHBridgeResourcesReader readBridgeResourcesCache]) {
        self.cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    }
}

// MARK: - Hue Light Action Methods -

- (void)toggleLightOnOffWithActiveDict:(NSDictionary *)activeDict {
    if (_actionInProgress) {
        return;
    }
    
    NSArray *groupNames = [activeDict objectForKey:@"groupNames"];
    for (PHGroup *group in self.cache.groups.allValues) {
        if ([groupNames containsObject:group.name]) {
            for (NSString *lightId in group.lightIdentifiers) {
                PHLight *light = [self.cache.lights objectForKey:lightId];
                if (light.lightState.on == [NSNumber numberWithBool:YES]) {
                    light.lightState.on = [NSNumber numberWithBool:NO];
                } else {
                    light.lightState.on = [NSNumber numberWithBool:YES];
                }
                light.lightState.brightness = [NSNumber numberWithFloat:[[activeDict objectForKey:@"brightness"] intValue]];
                [self setLightStateColorForLight:light.lightState andModelNum:light.modelNumber andActiveDict:activeDict];
                [self setLightState:light.lightState andLightId:light.identifier];
            }
        }
    }
}

- (void)detectSurrondingBrightness:(CGFloat)brightness andActiveDict:(NSDictionary *)activeDict{
    if (_actionInProgress) {
        return;
    }
    
    NSArray *groupNames = [activeDict objectForKey:@"groupNames"];
    for (PHGroup *group in self.cache.groups.allValues) {
        if ([groupNames containsObject:group.name]) {
            for (NSString *lightId in group.lightIdentifiers) {
                PHLight *light = [self.cache.lights objectForKey:lightId];
                NSNumber *lightStateValue = [self getLightStateWithBrightness:brightness andLightState:light.lightState];
                if (![lightStateValue isEqualToNumber:@(-1)]) {
                    light.lightState.brightness = [NSNumber numberWithFloat:[[activeDict objectForKey:@"brightness"] intValue]];
                    [self setLightStateColorForLight:light.lightState andModelNum:light.modelNumber andActiveDict:activeDict];
                    light.lightState.on = lightStateValue;
                    [self setLightState:light.lightState andLightId:light.identifier];
                }
            }
        }
    }
}

- (void)configureLightWithActiveDict:(NSDictionary *)activeDict andLightSwitch:(BOOL)lightSwitch{
    if (_actionInProgress) {
        return;
    }
    
    NSArray *groupNames = [activeDict objectForKey:@"groupNames"];
    for (PHGroup *group in self.cache.groups.allValues) {
        if ([groupNames containsObject:group.name]) {
            for (NSString *lightId in group.lightIdentifiers) {
                PHLight *light = [self.cache.lights objectForKey:lightId];
                if ([light.lightState.on boolValue] != lightSwitch) {
                    light.lightState.on = [NSNumber numberWithBool:lightSwitch];
                    light.lightState.brightness = [NSNumber numberWithFloat:[[activeDict objectForKey:@"brightness"] intValue]];
                    [self setLightStateColorForLight:light.lightState andModelNum:light.modelNumber andActiveDict:activeDict];
                    [self setLightState:light.lightState andLightId:light.identifier];
                }
            }
        }
    }
}

// MARK: - Hue Light Action Helper Methods -

- (NSNumber *)getLightStateWithBrightness:(CGFloat)brightness andLightState:(PHLightState*)lightState{
    if (brightness < 0.3 && lightState.on == [NSNumber numberWithBool:NO]) {
        return [NSNumber numberWithBool:YES];
    } else if (brightness > 0.42 && lightState.on == [NSNumber numberWithBool:YES]){
        return [NSNumber numberWithBool:NO];
    }
    return @(-1);

}

- (void)setLightStateColorForLight:(PHLightState *)lightState andModelNum:(NSString *)modelNum andActiveDict:(NSDictionary *)activeDict {
    NSDictionary *valueDict = [activeDict objectForKey:@"color"];
    NSDictionary *colorDictForLightModel = [valueDict objectForKey:modelNum];
    CGPoint lightColorPoint = CGPointMake([colorDictForLightModel[@"x"] floatValue], [colorDictForLightModel[@"y"] floatValue]);
    lightState.x = @(0);
    //@(round(lightColorPoint.x * 100) / 100);
    lightState.y = @(0);
    //@(round(lightColorPoint.y * 100) / 100);
}

- (void)setLightState:(PHLightState *)lightState andLightId:(NSString *)lightId {
    if (_actionInProgress) {
        return;
    }
    
    _actionInProgress = YES;
    lightState.xIncrement = 0;
    lightState.yIncrement = 0;
    lightState.alert = ALERT_NONE;
    lightState.effect = EFFECT_NONE;
    lightState.transitionTime = 0;
    [self.sendAPI updateLightStateForId:lightId withLightState:lightState completionHandler:^(NSArray *errors) {
        _actionInProgress = NO;
        if (!errors) {
            NSLog(@"Success");
        } else {
            NSLog(@"Failure");
        }
    }];
}

-(void)setLightSchedule:(PHLightState *)lightState andDate:(NSDate *)date andLightId:(NSString *)lightId andScheduleId:(NSString *)scheduleId andRecurringMode:(NSArray *)recurringDaysArr {
    if (_actionInProgress) {
        return;
    }
    
    _actionInProgress = YES;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *currentComponents = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate dateWithTimeInterval:(24*60*60) sinceDate:[NSDate date]]];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
    currentComponents.hour = components.hour;
    currentComponents.minute = components.minute;
    currentComponents.second = components.second;
    
    // Set created time
    NSDate *newTime = [calendar dateFromComponents:currentComponents];
    
    RecurringDay recurringDays;
    for (NSString *recurringDay in recurringDaysArr) {
        if ([recurringDay isEqualToString:@"Mon"]) {
            recurringDays = recurringDays | RecurringMonday;
        }
        if ([recurringDay isEqualToString:@"Tue"]) {
            recurringDays = recurringDays | RecurringTuesday;
        }
        if ([recurringDay isEqualToString:@"Wed"]) {
            recurringDays = recurringDays | RecurringWednesday;
        }
        if ([recurringDay isEqualToString:@"Thur"]) {
            recurringDays = recurringDays | RecurringThursday;
        }
        if ([recurringDay isEqualToString:@"Fri"]) {
            recurringDays = recurringDays | RecurringFriday;
        }
        if ([recurringDay isEqualToString:@"Sat"]) {
            recurringDays = recurringDays | RecurringSaturday;
        }
        if ([recurringDay isEqualToString:@"Sun"]) {
            recurringDays = recurringDays | RecurringSunday;
        }
    }
    
    
    PHSchedule *schedule = [self.cache.schedules objectForKey:scheduleId];
    if (schedule) {
        schedule.date = newTime;
        [self.sendAPI updateScheduleWithSchedule:schedule completionHandler:^(NSArray *errors) {
            _actionInProgress = NO;
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Failure");
            }
        }];
    } else {
        schedule = [[PHSchedule alloc] init];
        if ([lightState.on  isEqual: @(1)]) {
            schedule.name = @"Sunset";
        } else {
            schedule.name = @"Sunrise";
        }
        schedule.localTime = YES;
        schedule.date = newTime;
        schedule.state = lightState;
        schedule.lightIdentifier = lightId;
        schedule.recurringDays = recurringDays;
        [self.sendAPI createSchedule:schedule completionHandler:^(NSString *scheduleIdentifier, NSArray *errors) {
            _actionInProgress = NO;
            [[SettingManager sharedSettingManager] setScheduleIdOfSunriseSunsetSetting:scheduleIdentifier andUniqueKey:schedule.name];
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Failure");
            }
        }];
   }
}

- (void)configureLightScheduleWithLightSwitch:(BOOL)lightSwitch andDate:(NSDate *)date andUniqueKey:(NSString *)uniqueKey {
    if (_actionInProgress) {
        return;
    }
    
    NSDictionary *activeDict =  [[[SettingManager sharedSettingManager] getSunriseSunsetSetting] objectForKey:uniqueKey];
    if (activeDict.count <= 0) {
        return;
    }
    NSArray *groupNames = [activeDict objectForKey:@"groupNames"];
    for (PHGroup *group in self.cache.groups.allValues) {
        if ([groupNames containsObject:group.name]) {
            for (NSString *lightId in group.lightIdentifiers) {
                PHLight *light = [self.cache.lights objectForKey:lightId];
                PHLightState *newLightState = [[PHLightState alloc] init];
                
                if ([uniqueKey isEqualToString:@"Sunrise"]) {
                    newLightState.on = @(0);
                } else {
                    newLightState.on = @(1);
                }
                
                newLightState.brightness = [NSNumber numberWithFloat:[[activeDict objectForKey:@"brightness"] intValue]];
                [self setLightStateColorForLight:newLightState andModelNum:light.modelNumber andActiveDict:activeDict];
                [self setLightSchedule:newLightState andDate:date andLightId:lightId andScheduleId:[activeDict objectForKey:@"scheduleId"] andRecurringMode:[activeDict objectForKey:@"selectedRepeatDays"]];
            }
        }
    }
}

- (void)getSunriseSunsetTime:(CLLocationCoordinate2D)coordinate {
    NSString *url = [NSString stringWithFormat:@"https://api.sunrise-sunset.org/json?lat=%f&lng=%f",(float)coordinate.latitude, (float)coordinate.longitude];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:40.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error) {
            NSLog(@"Error: %@", error);
        }else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            NSError *err;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            if ([httpResponse statusCode] == 200){
                NSString *sunriseTimeString = json[@"results"][@"sunrise"];
                sunriseTimeString = [sunriseTimeString substringToIndex:[sunriseTimeString length]-3];
                NSString *sunsetTimeString = json[@"results"][@"sunset"];
                sunsetTimeString = [sunsetTimeString substringToIndex:[sunsetTimeString length]-3];
                NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
                [outputFormatter setDateFormat:@"hh:mm:ss"];
                outputFormatter.timeZone = [NSTimeZone systemTimeZone];
                NSDate *sunriseTime = [outputFormatter dateFromString:sunriseTimeString];
                NSDate *sunsetTime = [outputFormatter dateFromString:sunsetTimeString];
                NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
                sunriseTime = [sunriseTime dateByAddingTimeInterval:timeZoneSeconds];
                sunsetTime = [sunsetTime dateByAddingTimeInterval:timeZoneSeconds];
                self.sunriseTimer = [NSTimer timerWithTimeInterval:0 repeats:false block:^(NSTimer * _Nonnull timer) {
                    [self configureLightScheduleWithLightSwitch:true andDate:sunsetTime andUniqueKey:@"Sunrise"];
                }];
                self.sunsetTimer = [NSTimer timerWithTimeInterval:30 repeats:false block:^(NSTimer * _Nonnull timer) {
                    [self configureLightScheduleWithLightSwitch:false andDate:sunriseTime andUniqueKey:@"Sunset"];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSRunLoop currentRunLoop] addTimer: self.sunriseTimer forMode: NSDefaultRunLoopMode];
                    [[NSRunLoop currentRunLoop] addTimer: self.sunsetTimer forMode: NSDefaultRunLoopMode];
                });
            }
        }
    }];
    [task resume];
}

- (void) setSunriseSunsetDataStatus:(PHScheduleStatus)status {
    NSDictionary *sunriseSunsetDict1 = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SUNRISE_SUNSET].firstObject;
    NSDictionary *sunriseSunsetDict2 = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SUNRISE_SUNSET].lastObject;
    self.sunriseTimer = [NSTimer timerWithTimeInterval:0 repeats:false block:^(NSTimer * _Nonnull timer) {
        PHSchedule *schedule = [self.cache.schedules objectForKey:sunriseSunsetDict1[@"scheduleId"]];
        [schedule setStatusAsEnum:status];
        [self.sendAPI updateScheduleWithSchedule:schedule completionHandler:^(NSArray *errors) {
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Error: %@", errors);
            }
        }];
    }];
    self.sunsetTimer = [NSTimer timerWithTimeInterval:30 repeats:false block:^(NSTimer * _Nonnull timer) {
        PHSchedule *schedule = [self.cache.schedules objectForKey:sunriseSunsetDict2[@"scheduleId"]];
        [schedule setStatusAsEnum:status];
        [self.sendAPI updateScheduleWithSchedule:schedule completionHandler:^(NSArray *errors) {
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Error: %@", errors);
            }
        }];

    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSRunLoop currentRunLoop] addTimer: self.sunriseTimer forMode: NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer: self.sunsetTimer forMode: NSDefaultRunLoopMode];
    });
}

- (void) deleteSunriseSunsetData {
    NSDictionary *sunriseSunsetDict1 = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SUNRISE_SUNSET].firstObject;
    NSDictionary *sunriseSunsetDict2 = [[SettingManager sharedSettingManager] getActiveSettingWith:SETTINGTYPE_SUNRISE_SUNSET].lastObject;
    self.sunriseTimer = [NSTimer timerWithTimeInterval:0 repeats:false block:^(NSTimer * _Nonnull timer) {
        [self.sendAPI removeScheduleWithId:sunriseSunsetDict1[@"scheduleId"] completionHandler:^(NSArray *errors) {
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Error: %@", errors);
            }
        }];
    }];
    self.sunsetTimer = [NSTimer timerWithTimeInterval:30 repeats:false block:^(NSTimer * _Nonnull timer) {
        [self.sendAPI removeScheduleWithId:sunriseSunsetDict2[@"scheduleId"] completionHandler:^(NSArray *errors) {
            if (!errors) {
                NSLog(@"Success");
            } else {
                NSLog(@"Error: %@", errors);
            }
        }];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSRunLoop currentRunLoop] addTimer: self.sunriseTimer forMode: NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer: self.sunsetTimer forMode: NSDefaultRunLoopMode];
    });
}

// MARK: - Hue Light Data Helper Methods -

-(NSArray*)getGroupData {
    NSMutableArray *groupData = [[NSMutableArray alloc] init];
    for (PHGroup *groupInfo in self.cache.groups.allValues) {
        [groupData addObject:groupInfo.name];
    }
    return groupData;
}

-(NSDictionary*)convertUIColorToHueColorNumber:(UIColor *)color andGroupName:(NSArray *)groupNames {
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    
    for (NSString *groupName in groupNames) {
        for (PHGroup *groupInfo in self.cache.groups.allValues) {
            if ([groupInfo.name isEqualToString:groupName]) {
                for (NSString *lightId in groupInfo.lightIdentifiers) {
                    PHLight *light = [self.cache.lights objectForKey:lightId];
                    NSString *lightModel = light.modelNumber;
                    if (![resultDic valueForKey: lightModel]) {
                        CGPoint xy = [PHUtilities calculateXY:color forModel:lightModel];
                        NSDictionary *dict = @{@"x":@(xy.x), @"y":@(xy.y)};
                        [resultDic setValue:dict forKey:lightModel];
                    }
                }
            }
        }
    }
    return resultDic;
}

// MARK: - Get Hue Light -

+ (HueLight*)sharedHueLight {
    static HueLight *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[HueLight alloc] init];
    });
    return _sharedInstance;
}
@end
