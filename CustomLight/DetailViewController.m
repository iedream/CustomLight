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

@property (nonatomic, strong) MultiSelectSegmentedControl *repeatDaySelectionControl;
@property (nonatomic, strong) ISColorWheel *colorPickerWheel;

@property (nonatomic, strong) NSArray *groupData;

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
}
- (IBAction)brightnessSliderValueChanged:(id)sender {
    float value = roundf(self.brightnessSlider.value * 100);
    self.brightnessValueLabel.text = [NSString stringWithFormat:@"%.f%%", value];
}

- (IBAction)rangeSliderValueChanged:(id)sender {
    float value = roundf(self.rangeSlider.value * 100);
    if (value < 5) {
        self.rangeValueLabel.text = @"0";
    } else if (value > 5 && value < 15) {
        self.rangeValueLabel.text = @"1";
    } else if (value > 15 && value < 25) {
        self.rangeValueLabel.text = @"2";
    } else if (value > 25 && value < 35) {
        self.rangeValueLabel.text = @"3";
    } else if (value > 35 && value < 45) {
        self.rangeValueLabel.text = @"4";
    } else if (value > 45 && value < 55) {
        self.rangeValueLabel.text = @"5";
    } else if (value > 55 && value < 65) {
        self.rangeValueLabel.text = @"6";
    } else if (value > 65 && value < 75) {
        self.rangeValueLabel.text = @"7";
    } else if (value > 75 && value < 85) {
        self.rangeValueLabel.text = @"8";
    } else if (value > 85 && value < 95) {
        self.rangeValueLabel.text = @"9";
    } else if (value > 95) {
        self.rangeValueLabel.text = @"10";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender {
}

@end
