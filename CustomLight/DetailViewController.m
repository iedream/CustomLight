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

@property (nonatomic, strong) MultiSelectSegmentedControl *repeatDaySelectionControl;
@property (nonatomic, strong) ISColorWheel *colorPickerWheel;

@property (nonatomic, strong) NSArray *groupData;
@property (nonatomic, strong) NSMutableArray *selectedRooms;
@property (nonatomic, strong) NSMutableArray *brightnessDetectionArr;

@property (nonatomic, strong) UITableView *lightSettingsTableView;

@end

@implementation DetailViewController

- (void)configureView {
    // Update the user interface for the detail item.
    
    self.colorPickerWheel = [[ISColorWheel alloc] initWithFrame: self.colorPickerView.bounds];
    [self.colorPickerView addSubview:self.colorPickerWheel];
    self.repeatDaySelectionControl = [[MultiSelectSegmentedControl alloc] initWithItems:@[@"Mon", @"Tue", @"Wed", @"Thur", @"Fri", @"Sat", @"Sun"]];
    [self.repeatDaySelectionView addSubview:self.repeatDaySelectionControl];
    
    self.lightSettingsTableView = [[UITableView alloc] init];
    self.lightSettingsTableView.delegate = self;
    self.lightSettingsTableView.dataSource = self;
    [self.view addSubview:self.lightSettingsTableView];
    
    CGRect frame;
    frame.origin.x = 10.0;
    frame.origin.y = self.startTimeLabel.frame.origin.y;
    frame.size.width = self.view.frame.size.width - 20.0;
    frame.size.height = self.view.frame.size.height - 10.0 - frame.origin.y;
    self.lightSettingsTableView.frame = frame;
    
    self.groupTableView.delegate = self;
    self.groupTableView.dataSource = self;
    
    self.groupData = [[HueLight sharedHueLight] getGroupData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        SettingManager *settingManager = [SettingManager sharedSettingManager];
        int count = settingManager.shakeArray.count + settingManager.proximityArray.count + settingManager.brightnessArray.count;
        return count;
    } else {
        return [self.groupData count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.detailType == DETAILVIEWTYPE_SETTINGS) {
        CustomLightSettingTableViewCell *lightSettingCell = [self.groupTableView dequeueReusableCellWithIdentifier:@"LightSettingTableViewCell"];
        if (lightSettingCell == nil) {
            lightSettingCell = [[CustomLightSettingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LightSettingTableViewCell"];
        }
        NSInteger currentIndex = indexPath.row;
        SettingManager *settingManager = [SettingManager sharedSettingManager];
        NSDictionary *currentDict = @{};
        SETTINGTYPE currentSettingType = SETTINGTYPE_NONE;
        if (currentIndex < settingManager.shakeArray.count) {
            currentDict = [settingManager.shakeArray objectAtIndex:currentIndex];
            currentSettingType = SETTINGTYPE_SHAKE;
        } else if (currentIndex - settingManager.shakeArray.count < settingManager.proximityArray.count) {
            currentIndex = currentIndex - settingManager.shakeArray.count;
            currentDict = [settingManager.proximityArray objectAtIndex:currentIndex];
            currentSettingType = SETTINGTYPE_PROXIMITY;
        } else if (currentIndex - settingManager.proximityArray.count < settingManager.brightnessArray.count) {
            currentIndex = currentIndex - settingManager.brightnessArray.count;
            currentDict = [settingManager.brightnessArray objectAtIndex:currentIndex];
            currentSettingType = SETTINGTYPE_BRIGHTNESS;
        }
        [lightSettingCell setCellTextWithCurrentDict:currentDict andSettingType:currentSettingType];
        return lightSettingCell;
        
    } else {
        CustomLightTableViewCell *groupCell = [self.groupTableView dequeueReusableCellWithIdentifier:@"GroupTableViewCell"];
        if (groupCell == nil) {
            groupCell = [[CustomLightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GroupTableViewCell"];
        }
        [groupCell setTitle:[self.groupData objectAtIndex:indexPath.row]];
        return groupCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomLightTableViewCell *groupCell = [self.groupTableView cellForRowAtIndexPath:indexPath];
    [groupCell getSelected];
    
    NSString *roomName = [self.groupData objectAtIndex:indexPath.row];
    if (groupCell.isSelected) {
        [self.selectedRooms addObject:roomName];
    } else {
        [self.selectedRooms removeObject:roomName];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedRooms = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
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
        
        
        self.lightSettingsTableView.hidden = NO;
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
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender {
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm"];
    NSString *startTime = [outputFormatter stringFromDate:self.startTime.date];
    NSString *endTime = [outputFormatter stringFromDate:self.endTime.date];
    
    NSArray *selectedDays = self.repeatDaySelectionControl.selectedSegmentTitles;
    NSMutableArray *selectedDaysArr = [[NSMutableArray alloc] init];
    for (NSString *day in selectedDays) {
        [selectedDaysArr addObject:day];
    }
    
    NSNumber *brightnessValue = @(self.brightnessSlider.value*254);
    
    UIColor *color = [self.colorPickerWheel currentColor];
    NSDictionary *colorDict = [[HueLight sharedHueLight] convertUIColorToHueColorNumber:color andGroupName:self.selectedRooms];
    
    NSDictionary *rangeDict;
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY) {
        rangeDict = @{@"useiBeacon": [NSNumber numberWithBool:self.useiBeaconSwitch.on], @"rangeValue": self.rangeValueLabel.text};
    }
    
    NSDictionary *dict = @{@"startTime": startTime, @"endTime": endTime, @"selectedRepeatDays": selectedDaysArr, @"brightness": brightnessValue, @"color":colorDict, @"range": rangeDict, @"groupNames": self.selectedRooms};
    [self.brightnessDetectionArr addObject:dict];
}

@end
