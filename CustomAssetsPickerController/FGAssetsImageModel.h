//
//  FGAssetsImageModel.h
//  CustomAssetsPickerController
//
//  Created by 龙章辉 on 16/5/3.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

@interface FGAssetsImageModel : NSObject

@property(nonatomic,copy,readonly)NSString *imagePath;
@property(nonatomic,copy,readonly)UIImage  *displayImage;
@property(nonatomic,copy,readonly)UIImage  *smallerImage;

- (instancetype)initWithAsset:(ALAsset *)asset;


@end
