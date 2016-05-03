//
//  FGAssetsPickerController.h
//  CustomAssetsPickerController
//
//  Created by 龙章辉 on 16/4/29.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>


@protocol FGAssetsPickerControllerDelegate;

@interface FGAssetsPickerController : UINavigationController

@property(nonatomic,assign)id <UINavigationControllerDelegate,FGAssetsPickerControllerDelegate>delegate;

/**
 *  设置选取类型，图片、视频
 */
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;
@property (nonatomic, copy, readonly) NSArray *indexPathsForSelectedItems;

/**
 *  最多可选图片，默认无限制
 */
@property (nonatomic, assign) NSInteger maximumNumberOfSelection;

/**
 *  A predicate which must be true for each asset to be selectable
 *  default YES
 */
@property (nonatomic, strong)NSPredicate *selectionFilter;


/**
 *  显示空的分组相册，默认NO,YES显示
 */
@property (nonatomic, assign, readwrite) BOOL showsEmptyGroups;
@end



@protocol FGAssetsPickerControllerDelegate <NSObject>
/**
 *点击完成按钮
 */
- (void)assetsPickerController:(FGAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets;

@optional

/**
 *点击取消按钮
 */
- (void)assetsPickerControllerDidCancel:(FGAssetsPickerController *)picker;


/**
 Tells the delegate that the item at the specified index path was selected.
 @param picker The controller object managing the assets picker interface.
 @param indexPath The index path of the asset that was selected.
 */
- (void)assetsPickerController:(FGAssetsPickerController *)picker didSelectItemAtIndexPath:(NSIndexPath *)indexPath;


/**
 Tells the delegate that the item at the specified path was deselected.
 @param picker The controller object managing the assets picker interface.
 @param indexPath The index path of the asset that was deselected.
 */
- (void)assetsPickerController:(FGAssetsPickerController *)picker didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;


/**
 *  选中照片张数和maximumNumberOfSelection相等的时候，不能再选择
 *
 *  @param maximumNumber 最多选择照片张数
 */
- (void)assetsPickerController:(FGAssetsPickerController *)picker  didSelectedMaximumNumberItem:(NSInteger)maximumNumber;


@end