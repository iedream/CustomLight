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

@interface HueLight()
@property (nonatomic, strong) PHHueSDK *hueSDK;
@property (nonatomic, strong) PHBridgeSearching *bridgeSearching;
@property (nonatomic, strong) PHNotificationManager *hueNotificationManager;
@property (nonatomic, strong) PHBridgeResourcesCache *cache;
@property (nonatomic, strong) PHBridgeSendAPI *sendAPI;

@property (nonatomic, strong) NSString *ipAddress;

@property (nonatomic) BOOL actionInProgress;
@property (nonatomic) BOOL initSetUpDone;
@property (nonatomic) BOOL inProgressOfSetUp;
@property (nonatomic, strong) NSTimer *setupTimer;

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
        
        self.bridgeSearching = [[PHBridgeSearching alloc]initWithUpnpSearch:YES andPortalSearch:YES];
        [self searchForBridge];
    }
    return self;
}

- (void)searchForBridge {
    if (_inProgressOfSetUp) {
        return;
    }
    _initSetUpDone = NO;
    _inProgressOfSetUp = YES;
    [self.bridgeSearching startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        if (bridgesFound.count < 1) {
            UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"No Bridge Found" message:@"Cannot found bridge on current wifi network" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                _inProgressOfSetUp = NO;
                [self searchForBridge];
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [authenticateAlert addAction:okAction];
            [authenticateAlert addAction:tryAgainAction];
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            [vc presentViewController:authenticateAlert animated:true completion:nil];
        } else {
            self.ipAddress = bridgesFound.allValues.firstObject;
            self.hueNotificationManager = [PHNotificationManager defaultManager];
            self.sendAPI = [[PHBridgeSendAPI alloc] init];
            _inProgressOfSetUp = NO;
            if ([[SettingManager sharedSettingManager] readBridgeSetupFromPlistSetting]) {
                [self setUpConnection];
            } else {
                [self authenticate];
            }
        }
    }];
}

// MARK: - Spinner Related View -

- (void)startLoading {
    [self.spinnerView startAnimating];
}

- (void)stopLoading {
    [self.spinnerView stopAnimating];
}

// MARK: - Hue Light Setup -

- (void)refreshCache {
    if (!self.hueSDK.localConnected && !_inProgressOfSetUp) {
        [self searchForBridge];
        return;
    }
    
    if (_actionInProgress || !_initSetUpDone || self.cache || _inProgressOfSetUp) {
        return;
    }
    
    if ([PHBridgeResourcesReader readBridgeResourcesCache]) {
        self.cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    } else {
        _initSetUpDone = NO;
        [self setUpConnection];
    }
}

- (void)authenticate {
    if (_inProgressOfSetUp) {
        return;
    }
    _inProgressOfSetUp = YES;
    _initSetUpDone = NO;
    
    UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"Authenticate Bridge" message:@"Press big button on bridge" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [authenticateAlert addAction:okAction];
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:authenticateAlert animated:true completion:nil];
    
    self.bridgeSearching = [[PHBridgeSearching alloc]initWithUpnpSearch:YES andPortalSearch:YES andIpAddressSearch:self.ipAddress];
    [self.bridgeSearching startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        [self.hueSDK setBridgeToUseWithId:bridgesFound.allKeys.firstObject ipAddress:bridgesFound.allValues.firstObject];
        [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationSuccess:) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION];
        [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION];
        [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION];
        [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION];
        [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION];
        [self.hueSDK startPushlinkAuthentication];
    }];
}

- (void)setUpConnection {
    if (_inProgressOfSetUp) {
        return;
    }
    _inProgressOfSetUp = YES;
    _initSetUpDone = NO;
    self.setupTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(clearSetupTimer) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer: self.setupTimer forMode: NSDefaultRunLoopMode];
    
    [self.hueNotificationManager registerObject:self withSelector:@selector(localConnection:) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(noLocalConnection:) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    
    [self.hueSDK setLocalHeartbeatInterval:2.0f forResourceType:RESOURCES_LIGHTS];
    [self.hueSDK setLocalHeartbeatInterval:5.0f forResourceType:RESOURCES_GROUPS];
    
    [self.hueSDK enableLocalConnection];
}

- (void)clearSetupTimer {
    _inProgressOfSetUp = NO;
    [self authenticate];
}

- (void)authenticationSuccess:(NSNotification *)notif {
    [[SettingManager sharedSettingManager] writeBridgeSetupToPlistSetting];
    _inProgressOfSetUp = NO;
    self.hueNotificationManager = [PHNotificationManager defaultManager];
    self.sendAPI = [[PHBridgeSendAPI alloc] init];
    
    [self setUpConnection];
}

- (void)authenticationFailure:(NSNotification *)notif {
    _inProgressOfSetUp = NO;
    UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"Authentication Failed" message:@"Authentication progress failed" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self authenticate];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [authenticateAlert addAction:okAction];
    [authenticateAlert addAction:tryAgainAction];
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:authenticateAlert animated:true completion:nil];
}

- (void)noLocalConnection:(NSNotification *)notif {
    _inProgressOfSetUp = NO;
    [self.bridgeSearching startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
        if (bridgesFound.count < 1) {
            [self.hueSDK disableLocalConnection];
            [self.hueSDK disableCacheUpdateLocalHeartbeat:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stopObserveStateChange" object:nil];
            _initSetUpDone = NO;
            
            UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"No Bridge Found" message:@"Cannot found bridge on current wifi network" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self searchForBridge];
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [authenticateAlert addAction:okAction];
            [authenticateAlert addAction:tryAgainAction];
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            [vc presentViewController:authenticateAlert animated:true completion:nil];
        } else {
            UIAlertController *authenticateAlert = [UIAlertController alertControllerWithTitle:@"Set Up Connection Failed" message:@"Setting Up Connection progress failed" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self setUpConnection];
            }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [authenticateAlert addAction:okAction];
            [authenticateAlert addAction:tryAgainAction];
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            [vc presentViewController:authenticateAlert animated:true completion:nil];
        }
    }];
}

- (void)localConnection:(NSNotification *)notif {
    if (!_initSetUpDone) {
        _initSetUpDone = YES;
        _inProgressOfSetUp = NO;
        [self.setupTimer invalidate];
        [self.visualEffectView removeFromSuperview];
        [self stopLoading];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"startObserveStateChange" object:nil];
    }
    if ([PHBridgeResourcesReader readBridgeResourcesCache]) {
        self.cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    }
}

// MARK: - Hue Light Action Methods -

- (void)toggleLightOnOffWithActiveDict:(NSDictionary *)activeDict {
    if (_actionInProgress || !_initSetUpDone) {
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
                [self setLightStateColorForLight:light andActiveDict:activeDict];
                [self setLightState:light.lightState andLightId:light.identifier];
            }
        }
    }
}

- (void)detectSurrondingBrightness:(CGFloat)brightness andActiveDict:(NSDictionary *)activeDict{
    if (_actionInProgress || !_initSetUpDone) {
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
                    [self setLightStateColorForLight:light andActiveDict:activeDict];
                    light.lightState.on = lightStateValue;
                    [self setLightState:light.lightState andLightId:light.identifier];
                }
            }
        }
    }
}

- (void)configureLightWithActiveDict:(NSDictionary *)activeDict andLightSwitch:(BOOL)lightSwitch{
    if (_actionInProgress || !_initSetUpDone) {
        return;
    }
    
    NSArray *groupNames = [activeDict objectForKey:@"groupNames"];
    for (PHGroup *group in self.cache.groups.allValues) {
        if ([groupNames containsObject:group.name]) {
            for (NSString *lightId in group.lightIdentifiers) {
                PHLight *light = [self.cache.lights objectForKey:lightId];
                if (![light.lightState.on boolValue] == lightSwitch) {
                    light.lightState.on = [NSNumber numberWithBool:lightSwitch];
                    light.lightState.brightness = [NSNumber numberWithFloat:[[activeDict objectForKey:@"brightness"] intValue]];
                    [self setLightStateColorForLight:light andActiveDict:activeDict];
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

- (void)setLightStateColorForLight:(PHLight *)light andActiveDict:(NSDictionary *)activeDict {
    NSDictionary *valueDict = [activeDict objectForKey:@"color"];
    NSDictionary *colorDictForLightModel = [valueDict objectForKey:light.modelNumber];
    CGPoint lightColorPoint = CGPointMake([colorDictForLightModel[@"x"] floatValue], [colorDictForLightModel[@"y"] floatValue]);
    light.lightState.x = @(lightColorPoint.x);
    light.lightState.y = @(lightColorPoint.y);
}

- (void)setLightState:(PHLightState *)lightState andLightId:(NSString *)lightId {
    if (_actionInProgress || !_initSetUpDone) {
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
