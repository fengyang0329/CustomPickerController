//
//  FGAssetsImageModel.m
//  CustomAssetsPickerController
//
//  Created by 龙章辉 on 16/5/3.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "FGAssetsImageModel.h"

@interface FGAssetsImageModel ()

@property (nonatomic,copy,readwrite)NSString *imagePath;
@property (nonatomic,copy,readwrite)UIImage *displayImage;
@property (nonatomic,copy,readwrite)UIImage *smallerImage;
@property (nonatomic,strong)ALAsset *asset;

@end


@implementation FGAssetsImageModel

- (instancetype)initWithAsset:(ALAsset *)asset
{
    self = [super init];
    if (self)
    {
        _asset = asset;
        UIImage *ima = [UIImage imageWithCGImage:_asset.defaultRepresentation.fullScreenImage];
        self.displayImage = ima;
        self.imagePath = [self saveImageToTemporaryDirectory:ima];
    }
    return self;
}



- (NSString *)saveImageToTemporaryDirectory:(UIImage *)image
{
    NSString *path = [self imageCachePath];
    NSData* imageData = UIImageJPEGRepresentation(image,0.8);
    NSString *time = [self stringWithDate:[NSDate date] formater:@"yyyyMMddHHmmssSSS"];
    NSString *picName = [NSString stringWithFormat:@"%@.jpg", time];
    NSString* fullPathToFile = [path stringByAppendingPathComponent:picName];
    [imageData writeToFile:fullPathToFile atomically:NO];
    return fullPathToFile;
}

- (NSString *)imageCachePath
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"FGAssetsPicCache"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return path;
}

- (UIImage *)displayImage
{
    return [UIImage imageWithContentsOfFile:self.imagePath];
}

- (UIImage *)smallerImage
{
    UIImage *ima = [UIImage imageWithCGImage:_asset.thumbnail];
    return ima;
}


- (NSString *)stringWithDate:(NSDate *)date formater:(NSString *)formaterString
{
    if (!date) {
        return  nil;
    }
    if (!formaterString) {
        formaterString = @"yyyy-MM-dd";
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:formaterString];
    return [formatter stringFromDate:date];
}

@end
