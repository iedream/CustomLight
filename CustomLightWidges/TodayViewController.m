//
//  TodayViewController.m
//  CustomLightWidges
//
//  Created by Catherine Zhao on 2016-11-17.
//  Copyright © 2016 Catherine. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "CustomLightWidgetCollectionViewCell.h"

#import "WidgesSettingManager.h"

@interface TodayViewController () <NCWidgetProviding>
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSDictionary *settingData;
@property (nonatomic) CGSize originalSize;
@end

@implementation TodayViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
   // NSLog(@"init widges");
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsDidChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    //NSLog(@"reload widges");
    
    [super viewDidLoad];
    self.originalSize = self.view.frame.size;
    [self.extensionContext setWidgetLargestAvailableDisplayMode:NCWidgetDisplayModeExpanded];
    self.data = [[WidgesSettingManager sharedSettingManager] setUpData];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 0);
    flowLayout.minimumInteritemSpacing = 1.0f;
    flowLayout.minimumLineSpacing = 1.0f;
    CGRect collectionFrame = self.view.bounds;
    collectionFrame.size.width -= 20.0f;
    self.collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:flowLayout];
    [self.collectionView registerClass:[CustomLightWidgetCollectionViewCell class] forCellWithReuseIdentifier:@"WidgesCollectionViewCell"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView setScrollEnabled:YES];
    self.collectionView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:self.collectionView];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    [self.collectionView reloadData];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    self.data = [[WidgesSettingManager sharedSettingManager] setUpData];
    [self.collectionView reloadData];
}


- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20.0, 0, 0, 0); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.data count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CustomLightWidgetCollectionViewCell *collectionViewCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"WidgesCollectionViewCell" forIndexPath:indexPath];
    if (!collectionViewCell) {
        collectionViewCell = [[CustomLightWidgetCollectionViewCell alloc] init];
    }
    NSString *uniqueKey = [self.data objectAtIndex:indexPath.row];
    [collectionViewCell setUpCellWithData:uniqueKey];
    return collectionViewCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Adjust cell size for orientation
    return CGSizeMake(74, 64);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    if (activeDisplayMode == NCWidgetDisplayModeCompact){
        [UIView animateWithDuration:0.25 animations:^{
            self.preferredContentSize = maxSize;
            [self.view layoutIfNeeded];
        }];
    }else if (activeDisplayMode == NCWidgetDisplayModeExpanded){
        [UIView animateWithDuration:0.25 animations:^{
            self.preferredContentSize = self.originalSize;
            [self.view layoutIfNeeded];
        }];
    }
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData 
    completionHandler(NCUpdateResultNewData);
}

@end
