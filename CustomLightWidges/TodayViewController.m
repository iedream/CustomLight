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
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSDictionary *settingData;
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
    self.data = [[WidgesSettingManager sharedSettingManager] setUpData];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 0);
    flowLayout.minimumInteritemSpacing = 1.0f;
    flowLayout.minimumLineSpacing = 0;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    [self.collectionView registerClass:[CustomLightWidgetCollectionViewCell class] forCellWithReuseIdentifier:@"WidgesCollectionViewCell"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
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
    return 0.0;
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
    NSDictionary *dict = [self.data objectAtIndex:indexPath.row];
    [collectionViewCell setUpCellWithData:dict];
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

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData 
    completionHandler(NCUpdateResultNewData);
}

@end
