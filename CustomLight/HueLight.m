//
//  HueLight.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "HueLight.h"
#import <HueSDK_iOS/HueSDK.h>

const NSString *ipAddress = @"192.168.2.28";

const NSString *BRIGHTNESS = @"Brightness";
const NSString *PROXIMITY = @"Proximity";
const NSString *SHAKE = @"Shake";

@interface HueLight()
@property (nonatomic, strong) PHHueSDK *hueSDK;
@property (nonatomic, strong) PHBridgeSearching *bridgeSearching;
@property (nonatomic, strong) PHNotificationManager *hueNotificationManager;
@property (nonatomic, strong) PHBridgeResourcesCache *cache;
@property (nonatomic, strong) PHBridgeSendAPI *sendAPI;

@property (nonatomic) int time;

@property (nonatomic) BOOL actionInProgress;
@property (nonatomic) BOOL initSetUpDone;

@property (nonatomic, strong) NSMutableDictionary *settings;
@end

@implementation HueLight

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hueSDK = [[PHHueSDK alloc]init];
        [self.hueSDK enableLogging:YES];
        [self.hueSDK startUpSDK];
        
        self.bridgeSearching = [[PHBridgeSearching alloc]initWithUpnpSearch:YES andPortalSearch:YES andIpAddressSearch:ipAddress];
        [self.bridgeSearching startSearchWithCompletionHandler:^(NSDictionary *bridgesFound) {
            self.hueNotificationManager = [PHNotificationManager defaultManager];
            self.sendAPI = [[PHBridgeSendAPI alloc] init];
            //[self authenticate];
            _initSetUpDone = YES;
            [self setUpConnection];
            [self stopLoading];
            [self.visualEffectView removeFromSuperview];
        }];
        
    }
    return self;
}

// MARK: - Spinner Related View -

- (void)startLoading {
    [self.spinnerView startAnimating];
}

- (void)stopLoading {
    [self.spinnerView stopAnimating];
}

// MARK: - Hue Light Setup -

- (void)authenticate {
    self.bridgeSearching = [[PHBridgeSearching alloc]initWithUpnpSearch:YES andPortalSearch:YES andIpAddressSearch:ipAddress];
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
    [self.hueNotificationManager registerObject:self withSelector:@selector(localConnection:) forNotification:LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(noLocalConnection:) forNotification:NO_LOCAL_CONNECTION_NOTIFICATION];
    [self.hueNotificationManager registerObject:self withSelector:@selector(authenticationFailure:) forNotification:NO_LOCAL_AUTHENTICATION_NOTIFICATION];
    
    [self.hueSDK setLocalHeartbeatInterval:2.0f forResourceType:RESOURCES_LIGHTS];
    [self.hueSDK setLocalHeartbeatInterval:5.0f forResourceType:RESOURCES_GROUPS];
    [self.hueSDK setLocalHeartbeatInterval:5.0f forResourceType:RESOURCES_SCHEDULES];
    
    [self.hueSDK enableLocalConnection];
}

- (void)authenticationSuccess:(NSNotification *)notif {
    [self setUpConnection];
}

- (void)authenticationFailure:(NSNotification *)notif {
    //[self authenticate];
}

- (void)noLocalConnection:(NSNotification *)notif {
    
}

- (void)localConnection:(NSNotification *)notif {
    self.cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    _initSetUpDone = YES;
    [self stopLoading];
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
                 _actionInProgress = YES;
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
                     _actionInProgress = YES;
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
                     _actionInProgress = YES;
                    [self setLightState:light.lightState andLightId:light.identifier];
                }
            }
        }
    }
}

// MARK: - Hue Light Action Helper Methods -

- (NSNumber *)getLightStateWithBrightness:(CGFloat)brightness andLightState:(PHLightState*)lightState{
    if (brightness < 1 && lightState.on == [NSNumber numberWithBool:NO]) {
        return [NSNumber numberWithBool:YES];
    } else if (brightness > 3 && lightState.on == [NSNumber numberWithBool:YES]){
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
    [self.sendAPI updateLightStateForId:lightId withLightState:lightState completionHandler:^(NSArray *errors) {
        _actionInProgress = NO;
        if (!errors) {
            NSLog(@"Success");
        } else {
            [self authenticate];
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
