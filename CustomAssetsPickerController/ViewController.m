//
//  ViewController.m
//  CustomAssetsPickerController
//
//  Created by 龙章辉 on 16/4/29.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "ViewController.h"
#import "FGAssetsPickerController.h"
#import "FGAssetsImageModel.h"

@interface ViewController ()<UINavigationControllerDelegate,FGAssetsPickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"选取器" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor redColor]];
    [btn setFrame:CGRectMake(60, 150, 200, 50)];
    [btn addTarget:self action:@selector(clickedPicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)clickedPicker:(UIButton *)btn
{
    FGAssetsPickerController *picker = [[FGAssetsPickerController alloc] init];
    picker.delegate = self;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.maximumNumberOfSelection = 4;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark FGAssetsPickerControllerDelegate
- (void)assetsPickerController:(FGAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    for (int i=0; i<assets.count; i++) {
        ALAsset *asset = [assets objectAtIndex:i];
        FGAssetsImageModel *model = [[FGAssetsImageModel alloc] initWithAsset:asset];
    }
}

- (void)assetsPickerController:(FGAssetsPickerController *)picker  didSelectedMaximumNumberItem:(NSInteger)maximumNumber
{
    NSString *tips = [NSString stringWithFormat:@"你最多只能选择%zi张照片",maximumNumber];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:tips delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
