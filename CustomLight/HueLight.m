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

@interface HueLight()
@property (nonatomic, strong) PHHueSDK *hueSDK;
@property (nonatomic, strong) PHBridgeSearching *bridgeSearching;
@property (nonatomic, strong) PHNotificationManager *hueNotificationManager;
@property (nonatomic, strong) PHBridgeResourcesCache *cache;
@property (nonatomic, strong) PHBridgeSendAPI *sendAPI;

@property (nonatomic) int time;
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
            [self setUpConnection];
            [self stopLoading];
        }];
        
    }
    return self;
}

- (void)startLoading {
    [self.spinnerView startAnimating];
}

- (void)stopLoading {
    [self.spinnerView stopAnimating];
}

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

- (void)toggleLightOnOff {
    PHLight *light = [self.cache.lights objectForKey:@"1"];
    PHLightState *lightState = light.lightState;
    if ([lightState.on isEqualToNumber:@(0)]) {
        lightState.on = [NSNumber numberWithBool:YES];
    } else {
        lightState.on = [NSNumber numberWithBool:NO];
    }
    lightState.brightness = @(254);
    [self setLightState:lightState andLightId:light.identifier];
}

- (void)detectSurrondingBrightness {
    PHLight *light = [self.cache.lights objectForKey:@"1"];
    PHLightState *lightState = light.lightState;
    
    CGFloat brightness = [[UIScreen mainScreen] brightness];
    if (brightness < 0.3) {
        lightState.on = [NSNumber numberWithBool:YES];
    } else {
        lightState.on = [NSNumber numberWithBool:NO];
    }
    lightState.brightness = @(254);
    [self setLightState:lightState andLightId:light.identifier];
}
         
- (void)setLightState:(PHLightState *)lightState andLightId:(NSString *)lightId {
    [self.sendAPI updateLightStateForId:lightId withLightState:lightState completionHandler:^(NSArray *errors) {
        if (!errors) {
            NSLog(@"Success");
        } else {
            [self authenticate];
            NSLog(@"Failure");
        }
    }];
}

-(NSArray*)getGroupData {
    NSMutableArray *groupData = [[NSMutableArray alloc] init];
    for (PHGroup *groupInfo in self.cache.groups.allValues) {
        [groupData addObject:groupInfo.name];
    }
    return groupData;
}

- (void)authenticationSuccess:(NSNotification *)notif {
    [self setUpConnection];
}

- (void)authenticationFailure:(NSNotification *)notif {
    [self authenticate];
}

- (void)noLocalConnection:(NSNotification *)notif {
    
}

- (void)localConnection:(NSNotification *)notif {
    self.cache = [PHBridgeResourcesReader readBridgeResourcesCache];
    PHLight *light = [self.cache.lights objectForKey:@"1"];
    PHLightState *lightState = light.lightState;
    self.time++;
    if (self.time <= 1) {
        //[self turnOnLight];
    }
}

+ (HueLight*)sharedHueLight {
    static HueLight *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[HueLight alloc] init];
    });
    return _sharedInstance;
}
@end
