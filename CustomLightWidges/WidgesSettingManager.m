//
//  WidgesSettingManager.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-18.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "WidgesSettingManager.h"

@interface  WidgesSettingManager()
@property (nonatomic, strong) NSMutableArray *data;
@end
@implementation WidgesSettingManager

- (NSMutableArray *)setUpData {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    NSArray *array = [defaults arrayForKey:@"LightSettingData"];
    self.data = [[NSMutableArray alloc] initWithArray:array];
    return self.data;
}

- (void)shareWidgets {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    [sharedDefaults setObject:self.data forKey:@"LightSettingData"];
    [sharedDefaults synchronize];
}

- (void)editActiveSettingWith:(NSDictionary *)dict andState:(BOOL)state {
    NSInteger widgetIndex = [self.data indexOfObject:dict];
    [self.data removeObject:dict];
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
    mutableDict[@"state"] = [NSNumber numberWithBool:state];
    [self.data insertObject:mutableDict atIndex:widgetIndex];
    [self shareWidgets];
}

+ (WidgesSettingManager*)sharedSettingManager {
    static WidgesSettingManager *_sharedSettingManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedSettingManager = [[WidgesSettingManager alloc] init];
    });
    return _sharedSettingManager;
}
@end
