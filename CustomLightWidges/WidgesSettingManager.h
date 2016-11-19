//
//  WidgesSettingManager.h
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-18.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WidgesSettingManager : NSObject
- (NSMutableArray *)setUpData;
+ (WidgesSettingManager*)sharedSettingManager;
- (void)editActiveSettingWith:(NSDictionary *)dict andState:(BOOL)state;
@end
