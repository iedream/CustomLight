//
//  WidgesSettingManager.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-18.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "WidgesSettingManager.h"

@interface  WidgesSettingManager()
@property (nonatomic, strong) NSMutableDictionary *data;
@end
@implementation WidgesSettingManager

- (NSArray *)setUpData {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    NSDictionary *dict = [defaults dictionaryForKey:@"LightSettingData"];
    self.data = [[NSMutableDictionary alloc] initWithDictionary:dict];
    return self.data.allKeys;
}

- (NSDictionary *)dataForUniqueKey:(NSString *)uniqueKey {
    return self.data[uniqueKey];
}

- (void)shareWidgets {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.smarterlight"];
    [sharedDefaults setObject:self.data forKey:@"LightSettingData"];
    [sharedDefaults synchronize];
}

- (void)editActiveSettingWith:(NSString *)uniqueKey {
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:self.data[uniqueKey]];
    BOOL state;
    if ([mutableDict[@"state"] boolValue] == YES) {
        state = NO;
    } else {
        state = YES;
    }
    mutableDict[@"state"] = [NSNumber numberWithBool:state];
    self.data[uniqueKey] = mutableDict.copy;
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
