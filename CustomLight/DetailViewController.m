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

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *startTime;
@property (weak, nonatomic) IBOutlet UIDatePicker *endTime;
@property (weak, nonatomic) IBOutlet UIView *repeatDaySelectionView;
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

@end

@implementation DetailViewController

- (void)configureView {
    // Update the user interface for the detail item.
    
    self.colorPickerWheel = [[ISColorWheel alloc] initWithFrame: self.colorPickerView.bounds];
    [self.colorPickerView addSubview:self.colorPickerWheel];
    self.repeatDaySelectionControl = [[MultiSelectSegmentedControl alloc] initWithItems:@[@"Mon", @"Tue", @"Wed", @"Thur", @"Fri", @"Sat", @"Sun"]];
    [self.repeatDaySelectionView addSubview:self.repeatDaySelectionControl];
    
    self.groupTableView.delegate = self;
    self.groupTableView.dataSource = self;
    
    self.groupData = [[HueLight sharedHueLight] getGroupData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groupData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomLightTableViewCell *groupCell = [self.groupTableView dequeueReusableCellWithIdentifier:@"GroupTableViewCell"];
    if (groupCell == nil) {
        groupCell = [[CustomLightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GroupTableViewCell"];
    }
    [groupCell setTitle:[self.groupData objectAtIndex:indexPath.row]];
    return groupCell;
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
    NSString *selectedDaysString = @"";
    for (NSString *day in selectedDays) {
        selectedDaysString = [NSString stringWithFormat:@"%@%@ ", selectedDaysString, day];
    }
    
    NSNumber *brightnessValue = @(self.brightnessSlider.value*254);
    
    UIColor *color = [self.colorPickerWheel currentColor];
    NSDictionary *colorDict = [[HueLight sharedHueLight] convertUIColorToHueColorNumber:color andGroupName:self.selectedRooms];
    
    if (self.detailType == DETAILVIEWTYPE_PROXIMITY) {
        NSDictionary *rangeDict = @{@"useiBeacon": [NSNumber numberWithBool:self.useiBeaconSwitch.on], @"rangeValue": self.rangeValueLabel.text};
    }

}

@end
