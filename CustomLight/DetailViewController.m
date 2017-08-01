//
//  DetailViewController.m
//  CustomLight
//
//  Created by Catherine Zhao on 2016-11-05.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "DetailViewController.h"
#import <iOS-color-wheel/ISColorWheel.h>
#import <MultiSelectSegmentedControl/MultiSelectSegmentedControl.h>
#import "HueLight.h"
#import "CustomLightTableViewCell.h"
#import "CustomLightSettingTableViewCell.h"
#import "SettingManager.h"
#import "CornerCoordinateView.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *startTime;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *endTime;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *repeatDaySelectionView;
@property (weak, nonatomic) IBOutlet UILabel *brightnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *brightnessValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *brightnessSlider;
@property (weak, nonatomic) IBOutlet UIView *colorPickerView;
@property (weak, nonatomic) IBOutlet UITableView *groupTableView;
@property (weak, nonatomic) IBOutlet UILabel *rangeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *rangeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *useiBeaconSwitch;

@property (weak, nonatomic) IBOutlet UILabel *rangeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *iBeaconLabel;
@property (weak, nonatomic) IBOutlet UILabel *widgetLabel;

@property (weak, nonatomic) IBOutlet UISwitch *widgetSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *onSwitch;

@property (nonatomic, strong) MultiSelectSegmentedControl *repeatDaySelectionControl;
@property (nonatomic, strong) ISColorWheel *colorPickerWheel;

@property (nonatomic, strong) NSArray *groupData;
@property (nonatomic, strong) NSArray *settingData;
@property (nonatomic, strong) NSMutableArray *selectedRooms;

@property (nonatomic, strong) UITableView *lightSettingsTableView;

@property (nonatomic, strong) NSString *currentActiveKey;

@property (nonatomic, strong) UIVisualEffectView *visualEffectView;

@end

@implementation DetailViewController

- (void)configureView {
    self.currentActiveKey = nil;
    
    // Update the user interface for the detail item.
    
    self.colorPickerWheel = [[ISColorWheel alloc] initWithFrame: self.colorPickerView.bounds];
    [self.colorPickerView addSubview:self.colorPickerWheel];
    self.repeatDaySelectionControl = [[MultiSelectSegmentedControl alloc] initWithItems:@[@"Mon", @"Tue", @"Wed", @"Thur", @"Fri", @"Sat", @"Sun"]];
    [self.repeatDaySelectionView addSubview:self.repeatDaySelectionControl];
    
    self.lightSettingsTableView = [[UITableView alloc] init];
    self.lightSettingsTableView.delegate = self;
    self.lightSettingsTableView.dataSource = self;
    [self.view addSubview:self.lightSettingsTableView];
    
    [self.lightSettingsTableView registerClass:[CustomLightSettingTableViewCell class] forCellReuseIdentifier:@"LightSettingTableViewCell"];
    
    CGRect frame;
    frame.origin.x = 10.0;
    frame.origin.y = self.startTimeLabel.frame.origin.y;
    frame.size.width = self.view.frame.size.width - 20.0;
    frame.size.height = self.view.frame.size.height - 10.0 - frame.origin.y;
    self.lightSettingsTableView.frame = frame;
    
    self.groupTableView.delegate = self;
    self.groupTableView.dataSource = self;
    
    self.groupData = [[HueLight sharedHueLight] getGroupData];
    self.settingData = [[SettingManager sharedSettingManager] getAllSettingData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        return [self.settingData count];
    } else {
        return [self.groupData count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        CustomLightSettingTableViewCell *lightSettingCell = [self.lightSettingsTableView dequeueReusableCellWithIdentifier:@"LightSettingTableViewCell"];
        if (lightSettingCell == nil) {
            lightSettingCell = [[CustomLightSettingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LightSettingTableViewCell"];
        }
        NSString *currentUniqueKey = [self.settingData objectAtIndex:indexPath.row];
        [lightSettingCell setCellTextWithCurrentUniqueKey:currentUniqueKey];
        return lightSettingCell;
        
    } else {
        CustomLightTableViewCell *groupCell = [self.groupTableView dequeueReusableCellWithIdentifier:@"GroupTableViewCell"];
        if (groupCell == nil) {
            groupCell = [[CustomLightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GroupTableViewCell"];
        }
        [groupCell setTitle:[self.groupData objectAtIndex:indexPath.row]];
        [groupCell applyCurrentSetting:self.currentActiveKey];
        return groupCell;
    }
}

- (void)configureSettingView:(NSString *)currentActiveKey {
    NSDictionary *currentDict = [[SettingManager sharedSettingManager] getDataForUniqueKey:currentActiveKey];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm"];
    outputFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    if (currentDict[@"startTime"] && currentDict[@"endTime"]) {
        NSDate *startTime = [outputFormatter dateFromString:currentDict[@"startTime"]];
        NSDate *endTime = [outputFormatter dateFromString:currentDict[@"endTime"]];
        [self.startTime setDate:startTime animated:YES];
        [self.endTime setDate:endTime animated:YES];
    }
    
    NSArray *selectedDays = currentDict[@"selectedRepeatDays"];
    NSMutableIndexSet *indexSets = [[NSMutableIndexSet alloc] init];
    if ([selectedDays containsObject:@"Mon"]) {
        [indexSets addIndex:0];
    }
    if ([selectedDays containsObject:@"Tue"]) {
        [indexSets addIndex:1];
    }
    if ([selectedDays containsObject:@"Wed"]) {
        [indexSets addIndex:2];
    }
    if ([selectedDays containsObject:@"Thur"]) {
        [indexSets addIndex:3];
    }
    if ([selectedDays containsObject:@"Fri"]) {
        [indexSets addIndex:4];
    }
    if ([selectedDays containsObject:@"Sat"]) {
        [indexSets addIndex:5];
    }
    if ([selectedDays containsObject:@"Sun"]) {
        [indexSets addIndex:6];
    }
    [self.repeatDaySelectionControl setSelectedSegmentIndexes:indexSets];
    
    NSDictionary *colorDict = currentDict[@"uicolorDict"];
    [self.colorPickerWheel setCurrentTouchPoint:colorDict];
    
    double brightness = [currentDict[@"brightness"] doubleValue];
    brightness = brightness / 254.0;
    [self.brightnessSlider setValue:brightness animated:YES];
    self.brightnessValueLabel.text = [NSString stringWithFormat:@"%d%%",(int)roundf(brightness*100)];
    
    self.onSwitch.on = [currentDict[@"on"] boolValue];
    
    self.widgetSwitch.on = [currentDict[@"useWidgets"] boolValue];
    
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY) {
        self.useiBeaconSwitch.userInteractionEnabled = NO;
        self.useiBeaconSwitch.alpha = 0.6;
        BOOL useiBeacon = [[[currentDict objectForKey:@"range"] objectForKey:@"useiBeacon"] boolValue];
        [self.useiBeaconSwitch setOn:useiBeacon];
        NSString *rangeValueString = [[currentDict objectForKey:@"range"] objectForKey:@"rangeValue"];
        self.rangeValueLabel.text = rangeValueString;
        if (useiBeacon) {
            if ([rangeValueString isEqualToString:@"Far"]) {
                [self.rangeSlider setValue:1.0 animated:YES];
            } else if ([rangeValueString isEqualToString:@"Near"]) {
                [self.rangeSlider setValue:0.66 animated:YES];
            } else {
                [self.rangeSlider setValue:0.33 animated:YES];
            }
        } else {
            double rangeValue = [rangeValueString doubleValue] / 10;
            [self.rangeSlider setValue:rangeValue animated:YES];
        }
    }
    self.currentActiveKey = currentActiveKey;
    
    [self.selectedRooms addObjectsFromArray:[currentDict objectForKey:@"groupNames"]];
    [self.groupTableView reloadData];
    
    UIBarButtonItem *currentLocationButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Widgets" style:UIBarButtonItemStylePlain target:self action:@selector(refreshWidgets:)];
    self.navigationItem.rightBarButtonItem = currentLocationButton;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        CustomLightSettingTableViewCell *groupCell = [self.lightSettingsTableView cellForRowAtIndexPath:indexPath];
        if ([groupCell currentSettingType] == SETTINGTYPE_SHAKE) {
            self.detailType = DETAILVIEWTYPE_SHAKE;
        } else if ([groupCell currentSettingType] == SETTINGTYPE_BRIGHTNESS) {
            self.detailType = DETAILVIEWTYPE_BRIGHTNESS;
        } else if ([groupCell currentSettingType] == SETTINGTYPE_PROXIMITY) {
            self.detailType = DETAILVIEWTYPE_PROXIMITY;
        } else if ([groupCell currentSettingType] == SETTINGTYPE_SUNRISE_SUNSET) {
            self.detailType = DETAILVIEWTYPE_SUNRISE_SUNSET;
        }
        [self resetViews];
        [self configureSettingView:[groupCell getCurrentUniqueKey]];
    } else {
        CustomLightTableViewCell *groupCell = [self.groupTableView cellForRowAtIndexPath:indexPath];
        [groupCell getSelected];
        
        NSString *roomName = [self.groupData objectAtIndex:indexPath.row];
        if (groupCell.isSelected) {
            [self.selectedRooms addObject:roomName];
        } else {
            [self.selectedRooms removeObject:roomName];
        }

    }
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
            SettingManager *settingManager = [SettingManager sharedSettingManager];
            NSString *currentUniqueKey = [self.settingData objectAtIndex:indexPath.row];
            [settingManager removeSettingWithUniqueKey:currentUniqueKey];
            self.settingData = [[SettingManager sharedSettingManager] getAllSettingData];
            [self.lightSettingsTableView reloadData];
            if ([currentUniqueKey isEqualToString:@"Sunrise/Sunset"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForSunriseSunset" object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForData" object:nil];
            }
        }
    }
}

- (IBAction)brightnessSliderValueChanged:(id)sender {
    float value = roundf(self.brightnessSlider.value * 100);
    self.brightnessValueLabel.text = [NSString stringWithFormat:@"%.f%%", value];
}

- (IBAction)rangeSliderValueChanged:(id)sender {
    float value = roundf(self.rangeSlider.value * 100);
    if (self.useiBeaconSwitch.on) {
        if (value < 33.33) {
            self.rangeValueLabel.text = @"Immediate";
        } else if (value < 66.67) {
            self.rangeValueLabel.text = @"Near";
        } else {
            self.rangeValueLabel.text = @"Far";
        }
    } else {
        if (value < 5) {
            self.rangeValueLabel.text = @"0";
        } else if (value < 15) {
            self.rangeValueLabel.text = @"1";
        } else if (value < 25) {
            self.rangeValueLabel.text = @"2";
        } else if (value < 35) {
            self.rangeValueLabel.text = @"3";
        } else if (value < 45) {
            self.rangeValueLabel.text = @"4";
        } else if (value < 55) {
            self.rangeValueLabel.text = @"5";
        } else if (value < 65) {
            self.rangeValueLabel.text = @"6";
        } else if (value < 75) {
            self.rangeValueLabel.text = @"7";
        } else if (value < 85) {
            self.rangeValueLabel.text = @"8";
        } else if (value < 95) {
            self.rangeValueLabel.text = @"9";
        } else {
            self.rangeValueLabel.text = @"10";
        }
    }
}

- (IBAction)useiBeaconSwitchValueChanged:(id)sender {
    [self rangeSliderValueChanged:self.rangeSlider];
}

- (void)resetViews {
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        self.startTimeLabel.hidden = YES;
        self.startTime.hidden = YES;
        self.endTimeLabel.hidden = YES;
        self.endTime.hidden = YES;
        
        self.repeatDaySelectionView.hidden = YES;
        self.repeatDaySelectionControl.hidden = YES;
        
        self.brightnessLabel.hidden = YES;
        self.brightnessValueLabel.hidden = YES;
        self.brightnessSlider.hidden = YES;
        
        self.groupTableView.hidden = YES;
        
        self.colorPickerView.hidden = YES;
        self.colorPickerWheel.hidden = YES;
        
        self.rangeTitleLabel.hidden = YES;
        self.rangeValueLabel.hidden = YES;
        self.rangeSlider.hidden = YES;
        
        self.iBeaconLabel.hidden = YES;
        self.useiBeaconSwitch.hidden = YES;
        
        self.widgetLabel.hidden = YES;
        self.widgetSwitch.hidden = YES;
        
        
        self.lightSettingsTableView.hidden = NO;
        self.navigationItem.rightBarButtonItem = nil;
    } else if (self.detailType == DETAILVIEWTYPE_SUNRISE_SUNSET) {
        self.startTimeLabel.hidden = YES;
        self.startTime.hidden = YES;
        self.endTimeLabel.hidden = YES;
        self.endTime.hidden = YES;
        
        self.repeatDaySelectionView.hidden = NO;
        self.repeatDaySelectionControl.hidden = NO;
        
        self.brightnessLabel.hidden = NO;
        self.brightnessValueLabel.hidden = NO;
        self.brightnessSlider.hidden = NO;
        
        self.groupTableView.hidden = NO;
        
        self.colorPickerView.hidden = NO;
        self.colorPickerWheel.hidden = NO;
        
        self.widgetLabel.hidden = NO;
        self.widgetSwitch.hidden = NO;
        
        self.lightSettingsTableView.hidden = YES;
        
        [self.rangeSlider setHidden:YES];
        self.rangeValueLabel.hidden = YES;
        self.useiBeaconSwitch.hidden = YES;
        self.rangeTitleLabel.hidden = YES;
        self.iBeaconLabel.hidden = YES;
    } else {
        self.startTimeLabel.hidden = NO;
        self.startTime.hidden = NO;
        self.endTimeLabel.hidden = NO;
        self.endTime.hidden = NO;
        
        self.repeatDaySelectionView.hidden = NO;
        self.repeatDaySelectionControl.hidden = NO;
        
        self.brightnessLabel.hidden = NO;
        self.brightnessValueLabel.hidden = NO;
        self.brightnessSlider.hidden = NO;
        
        self.groupTableView.hidden = NO;
        
        self.colorPickerView.hidden = NO;
        self.colorPickerWheel.hidden = NO;
        
        self.widgetLabel.hidden = NO;
        self.widgetSwitch.hidden = NO;
        
        self.lightSettingsTableView.hidden = YES;
        
        if (self.detailType != DETAILVIEWTYPE_PROXIMITY) {
            [self.rangeSlider setHidden:YES];
            self.rangeValueLabel.hidden = YES;
            self.useiBeaconSwitch.hidden = YES;
            self.rangeTitleLabel.hidden = YES;
            self.iBeaconLabel.hidden = YES;
        } else {
            self.rangeSlider.hidden = NO;
            self.rangeValueLabel.hidden = NO;
            self.useiBeaconSwitch.hidden = NO;
            self.rangeTitleLabel.hidden = NO;
            self.iBeaconLabel.hidden = NO;
            [self rangeSliderValueChanged:self.rangeSlider];
        }
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedRooms = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    [self resetViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDetailType:(DETAILVIEWTYPE)detailType {
    if (self.detailType != DETAILVIEWTYPE_PROXIMITY && self.detailType != DETAILVIEWTYPE_SETTINGS && detailType == DETAILVIEWTYPE_PROXIMITY) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AboutToSetProximityCoordinate" object:nil];
    }
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY && detailType != DETAILVIEWTYPE_PROXIMITY) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneSettingProximityCoordinate" object:nil];
    }
    _detailType = detailType;
}

- (void)finishedSavingWithRangeDict:(NSDictionary *)rangeDict {
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm"];
    NSString *startTime = [outputFormatter stringFromDate:self.startTime.date];
    NSString *endTime = [outputFormatter stringFromDate:self.endTime.date];
    
    NSArray *selectedDays = self.repeatDaySelectionControl.selectedSegmentTitles;
    NSMutableArray *selectedDaysArr = [[NSMutableArray alloc] init];
    for (NSString *day in selectedDays) {
        [selectedDaysArr addObject:day];
    }
    
    int aroundedBrightness = roundf(self.brightnessSlider.value*254);
    NSNumber *brightnessValue = @(aroundedBrightness);
    
    UIColor *color = [self.colorPickerWheel currentColor];
    NSDictionary *uicolorDict = [self.colorPickerWheel getTouchPoint];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    NSDictionary *colorDict = [[HueLight sharedHueLight] convertUIColorToHueColorNumber:color andGroupName:self.selectedRooms];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.detailType == SETTINGTYPE_SUNRISE_SUNSET) {
        [dict addEntriesFromDictionary:@{@"selectedRepeatDays": selectedDaysArr, @"brightness": brightnessValue, @"color":colorDict, @"uicolor":colorData, @"uicolorDict": uicolorDict, @"groupNames": self.selectedRooms, @"on":[NSNumber numberWithBool:self.onSwitch.on]}];
    } else {
        [dict addEntriesFromDictionary:@{@"startTime": startTime, @"endTime": endTime, @"selectedRepeatDays": selectedDaysArr, @"brightness": brightnessValue, @"color":colorDict, @"uicolor":colorData, @"uicolorDict": uicolorDict, @"groupNames": self.selectedRooms, @"on":[NSNumber numberWithBool:self.onSwitch.on]}];
    }
    
    if (self.currentActiveKey) {
        rangeDict = [[[SettingManager sharedSettingManager] getDataForUniqueKey:self.currentActiveKey] objectForKey:@"range"];
    }
    
    if (rangeDict) {
        NSMutableDictionary *finalRangeDict = [[NSMutableDictionary alloc] initWithDictionary:rangeDict];
        [finalRangeDict setValue:self.rangeValueLabel.text forKey:@"rangeValue"];
        [finalRangeDict setValue:[NSNumber numberWithBool:self.useiBeaconSwitch.on] forKey:@"useiBeacon"];
        [dict setValue:finalRangeDict forKey:@"range"];
    }
    
    SETTINGTYPE settingType = SETTINGTYPE_NONE;
    if (self.detailType == DETAILVIEWTYPE_BRIGHTNESS) {
        settingType = SETTINGTYPE_BRIGHTNESS;
    } else if (self.detailType == DETAILVIEWTYPE_SHAKE) {
        settingType = SETTINGTYPE_SHAKE;
    } else if (self.detailType == DETAILVIEWTYPE_PROXIMITY) {
        settingType = SETTINGTYPE_PROXIMITY;
    } else if (self.detailType == DETAILVIEWTYPE_SUNRISE_SUNSET) {
        settingType = SETTINGTYPE_SUNRISE_SUNSET;
    }
    
    [dict setValue:@(settingType) forKey:@"type"];
    
    [dict setValue:[NSNumber numberWithBool:self.widgetSwitch.on] forKey:@"useWidgets"];
    
    if (self.detailType == DETAILVIEWTYPE_SUNRISE_SUNSET) {
        self.currentActiveKey = [[SettingManager sharedSettingManager] addSettingForSunriseSunset:dict];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForSunriseSunset" object:nil];
    } else {
        self.currentActiveKey = [[SettingManager sharedSettingManager] addSetting:dict uniqueKey:self.currentActiveKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForData" object:nil];
    }
}

- (IBAction)save:(id)sender {
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY && !self.currentActiveKey) {
        if (self.useiBeaconSwitch.on) {
            UIAlertController *useiBeacon = [UIAlertController alertControllerWithTitle:@"Create iBeacon Range" message:@"Create iBeacon Boundry" preferredStyle:UIAlertControllerStyleAlert];
            [useiBeacon addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"Enter iBeacon UUID";
                textField.clearsOnBeginEditing = YES;
            }];
            UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *iBeaconUUID = useiBeacon.textFields.firstObject.text;
                NSDictionary *rangeDict = @{@"useiBeacon": [NSNumber numberWithBool:self.useiBeaconSwitch.on], @"rangeValue": self.rangeValueLabel.text, @"iBeaconUUID": iBeaconUUID};
                [self finishedSavingWithRangeDict:rangeDict];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [useiBeacon addAction:submitAction];
            [useiBeacon addAction:cancelAction];
            [self presentViewController:useiBeacon animated:true completion:nil];
        } else {
            CGRect frame;
            frame.size.width = self.view.bounds.size.width * 0.8;
            frame.size.height = self.view.bounds.size.height * 0.5;
            frame.origin.y = self.view.bounds.size.height * 0.25;
            frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2.0;
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.visualEffectView.frame = self.view.bounds;
            self.visualEffectView.alpha = 0.9;
            [self.view addSubview:self.visualEffectView];
            
            CornerCoordinateView *cornerCoordinateView = [[CornerCoordinateView alloc]initWithFrame:frame];
            cornerCoordinateView.delegate = self;
            [self.view addSubview:cornerCoordinateView];
        }
    } else {
        [self finishedSavingWithRangeDict:nil];
    }
}
- (CLLocationCoordinate2D)getCurrentLocationCoordinate {
    return [self.delegate getCurrentLocation];
}

- (void)proceedToSave:(CornerCoordinateView *)cornerCoordinateView {
    NSDictionary *rangeDict = [cornerCoordinateView getRectangularDict];
    [self finishedSavingWithRangeDict:rangeDict];
    [self.visualEffectView removeFromSuperview];
}

- (void)refreshWidgets:(id)sender {
    [self save:nil];
    [[SettingManager sharedSettingManager] refreshWidgetForUniqueKey:self.currentActiveKey];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneSettingProximityCoordinate" object:nil];
    }
}
@end
