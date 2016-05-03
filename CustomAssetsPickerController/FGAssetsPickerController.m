//
//  FGAssetsPickerController.m
//  CustomAssetsPickerController
//
//  Created by 龙章辉 on 16/4/29.
//  Copyright © 2016年 Peter. All rights reserved.
//

#import "FGAssetsPickerController.h"
#define IS_IOS7             ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#define kThumbnailLength    78.0f
#define kThumbnailSize      CGSizeMake(kThumbnailLength, kThumbnailLength)

#define MAIN_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define MAIN_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define kPopoverContentSize CGSizeMake(MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT)
#define kTitleColor   [UIColor whiteColor]
#define kUnTitleColor [kTitleColor colorWithAlphaComponent:0.5]


#define RGBColor(r,g,b)  [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define kNavigationColor RGBColor(240,132,120)

@interface FGAssetsPickerController ()

@property (nonatomic, copy) NSArray *indexPathsForSelectedItems;

@end


@interface FGAssetsGroupViewController : UITableViewController

@end


@interface FGAssetsGroupViewController()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) NSMutableArray *groups;

@end

@interface FGAssetsGroupViewCell : UITableViewCell

- (void)bind:(ALAssetsGroup *)assetsGroup;

@end

@interface FGAssetsGroupViewCell ()

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end




@interface FGAssetsViewController : UICollectionViewController

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end

@interface FGAssetsViewController ()

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) NSInteger numberOfPhotos;
@property (nonatomic, assign) NSInteger numberOfVideos;
@property (nonatomic, strong) UIButton  *numberBtn;
@property (nonatomic, strong) UIButton *rightBtn;

@end


@interface FGAssetsViewCell : UICollectionViewCell

- (void)bind:(ALAsset *)asset;

@end


@interface FGAssetsViewCell ()

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *videoImage;
@property (nonatomic, assign) BOOL disabled;

@end


@implementation FGAssetsPickerController


- (id)init
{
    FGAssetsGroupViewController *groupViewController = [[FGAssetsGroupViewController alloc] init];
    if (self = [super initWithRootViewController:groupViewController])
    {
        _maximumNumberOfSelection   = NSIntegerMax;
        _assetsFilter               = [ALAssetsFilter allAssets];
        _showsEmptyGroups           = NO;
        _selectionFilter            = [NSPredicate predicateWithValue:YES];
        self.preferredContentSize = kPopoverContentSize;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end



#pragma mark - FGAssetsGroupViewController

@implementation FGAssetsGroupViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
       
            self.preferredContentSize = kPopoverContentSize;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setCancelButton];
    [self localize];
    [self setupGroup];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
}


#pragma mark - Setup
- (void)setupViews
{
    self.tableView.rowHeight = kThumbnailLength + 12;
    self.tableView.backgroundColor = RGBColor(248,248,248);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.backgroundColor= kNavigationColor;
    self.navigationController.navigationBar.barTintColor = kNavigationColor;
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
}

- (void)setCancelButton
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(dismiss:)];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14], NSForegroundColorAttributeName:kTitleColor} forState:UIControlStateNormal];
}

- (void)localize
{
    self.title = @"相册";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17],
                                                                      NSForegroundColorAttributeName:kTitleColor}];
}

- (void)setupGroup
{
    if (!self.assetsLibrary)
        self.assetsLibrary = [self.class defaultAssetsLibrary];
    
    if (!self.groups)
        self.groups = [[NSMutableArray alloc] init];
    else
        [self.groups removeAllObjects];
    
    FGAssetsPickerController *picker = (FGAssetsPickerController *)self.navigationController;
    ALAssetsFilter *assetsFilter = picker.assetsFilter;
    //获取分组信息
    ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group)
        {
            [group setAssetsFilter:assetsFilter];
            if (group.numberOfAssets > 0 || picker.showsEmptyGroups)
                [self.groups addObject:group];
            
        }
        else
        {
            [self reloadData];
        }
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        
        [self showNotAllowed];
        
    };
    
    //获取分组相册ALAsset
    // 首先遍历相机胶卷
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
    
    //遍历其他所有所有相册
    NSUInteger type =
    ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
    ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
    
    [self.assetsLibrary enumerateGroupsWithTypes:type
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
}


#pragma mark - Reload Data
- (void)reloadData
{
    if (self.groups.count == 0)
        [self showNoAssets];
    
    [self.tableView reloadData];
}


#pragma mark - ALAssetsLibrary
+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}


#pragma mark - Not allowed / No assets
- (void)showNotAllowed
{
    self.title              = nil;
    UIView *lockedView      = [[UIView alloc] initWithFrame:self.view.bounds];

    CGRect rect             = CGRectInset(self.view.bounds, 8, 8);
    UILabel *title          = [[UILabel alloc] initWithFrame:rect];
    UILabel *message        = [[UILabel alloc] initWithFrame:rect];
    
    title.text              = @"这个程序不能访问你的照片或视频";
    title.font              = [UIFont boldSystemFontOfSize:17.0];
    title.textColor         = RGBColor(129, 136, 148);
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = @"访问手机相册已被禁用，请在iPhone的\"设置-隐私-照片\"选项中允许访问";
    message.font            = [UIFont systemFontOfSize:14.0];
    message.textColor       = RGBColor(129, 136, 148);
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    title.center            = CGPointMake(lockedView.center.x, lockedView.center.y - 10 - title.frame.size.height / 2);
    message.center          = CGPointMake(lockedView.center.x, lockedView.center.y + 10 + message.frame.size.height / 2);
    
    [lockedView addSubview:title];
    [lockedView addSubview:message];
    
    self.tableView.tableHeaderView  = lockedView;
    self.tableView.scrollEnabled    = NO;
}

- (void)showNoAssets
{
    UIView *noAssetsView    = [[UIView alloc] initWithFrame:self.view.bounds];
    
    CGRect rect             = CGRectInset(self.view.bounds, 10, 10);
    UILabel *title          = [[UILabel alloc] initWithFrame:rect];
    UILabel *message        = [[UILabel alloc] initWithFrame:rect];
    
    title.text              = @"没有照片或者视频";
    title.font              = [UIFont systemFontOfSize:17.0];
    title.textColor         = RGBColor(153, 153, 153);
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = @"你可以使用iTunes同步照片和视频到你的iPhone";
    message.font            = [UIFont systemFontOfSize:14.0];
    message.textColor       = RGBColor(153, 153, 153);
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    title.center            = CGPointMake(noAssetsView.center.x, noAssetsView.center.y - 10 - title.frame.size.height / 2);
    message.center          = CGPointMake(noAssetsView.center.x, noAssetsView.center.y + 10 + message.frame.size.height / 2);
    
    [noAssetsView addSubview:title];
    [noAssetsView addSubview:message];
    
    self.tableView.tableHeaderView  = noAssetsView;
    self.tableView.scrollEnabled    = NO;
}



#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroupCell";
    FGAssetsGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[FGAssetsGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    [cell bind:[self.groups objectAtIndex:indexPath.row]];
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kThumbnailLength + 12;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FGAssetsViewController *vc = [[FGAssetsViewController alloc] init];
    vc.assetsGroup = [self.groups objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 返回
- (void)dismiss:(id)sender
{
    FGAssetsPickerController *picker = (FGAssetsPickerController *)self.navigationController;
    if ([picker.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)])
        [picker.delegate assetsPickerControllerDidCancel:picker];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end


#pragma mark - 分组相册cell
@implementation FGAssetsGroupViewCell

- (void)bind:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup            = assetsGroup;
    CGImageRef posterImage      = assetsGroup.posterImage;
    size_t height               = CGImageGetHeight(posterImage);
    float scale                 = height / kThumbnailLength;
    
    self.imageView.image        = [UIImage imageWithCGImage:posterImage scale:scale orientation:UIImageOrientationUp];
    self.textLabel.text         = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.detailTextLabel.text   = [NSString stringWithFormat:@"%zi", [assetsGroup numberOfAssets]];
    self.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
}
@end



#pragma mark - FGAssetsViewController

#define kAssetsViewCellIdentifier           @"AssetsViewCellIdentifier"
#define kAssetsSupplementaryViewIdentifier  @"AssetsSupplementaryViewIdentifier"

@implementation FGAssetsViewController

- (id)init
{
    UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
    //cell的size
    layout.itemSize                     = kThumbnailSize;
    //section显示区域内容的缩进
    layout.sectionInset                 = UIEdgeInsetsMake(5.0, 0, 0, 0);
    //左右cell的最小间距
    layout.minimumInteritemSpacing      = 2;
    //上下cell的最小间距
    layout.minimumLineSpacing           = 2;
    //定义footView的size
    layout.footerReferenceSize          = CGSizeMake(0, 44.0);
    
    if (self = [super initWithCollectionViewLayout:layout])
    {
        self.collectionView.allowsMultipleSelection = YES;
        self.collectionView.backgroundColor = RGBColor(248, 248, 248);
        [self.collectionView registerClass:[FGAssetsViewCell class]
                forCellWithReuseIdentifier:kAssetsViewCellIdentifier];
        
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
            [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
         self.preferredContentSize = kPopoverContentSize;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupRightButtons];
    [self setBackButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupAssets];
}


- (void)setupRightButtons
{
    
    _numberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _numberBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [_numberBtn setBackgroundColor:[UIColor whiteColor]];
    [_numberBtn setTitleColor:kNavigationColor forState:UIControlStateNormal];
    [_numberBtn setFrame:CGRectMake(-20, 0, 20, 20)];
    _numberBtn.layer.cornerRadius = _numberBtn.frame.size.width/2;
    _numberBtn.layer.borderColor = [UIColor clearColor].CGColor;
    _numberBtn.layer.borderWidth = 0.5;
    _numberBtn.clipsToBounds = YES;
    _numberBtn.adjustsImageWhenHighlighted = NO;
    _numberBtn.hidden = YES;
    
    _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightBtn.exclusiveTouch = YES;
    _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [_rightBtn setBackgroundColor:[UIColor clearColor]];
    [_rightBtn setTitle:@"完成" forState:UIControlStateNormal];
    [_rightBtn setTitleColor:kUnTitleColor forState:UIControlStateNormal];
    [_rightBtn setFrame:CGRectMake(0, 0, 40, 20)];
    _rightBtn.userInteractionEnabled = NO;
    [_rightBtn addSubview:_numberBtn];
    //    [self setRightBarButtons:@[rightBtn,_numberBtn]];
    
    [self setRightBarButtonWithButton:_rightBtn];
    
    //    self.navigationItem.rightBarButtonItem =
    //    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
    //                                     style:UIBarButtonItemStylePlain
    //                                    target:self
    //                                    action:@selector(finishPickingAssets:)];
}
- (void)setRightBarButtons:(NSArray *)buttons
{
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    for (UIView *tmpView in buttons) {
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:tmpView];
        UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSeperator.width = -6;
        [barItems addObject:negativeSeperator];
        [barItems addObject:item];
    }
    self.navigationItem.rightBarButtonItems = barItems;
}

- (void)setRightBarButtonWithButton:(UIButton *)button
{
    [button addTarget:self action:@selector(finishPickingAssets:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSeperator.width = -6;
        if (item)
        {
            [self.navigationItem setRightBarButtonItems:@[negativeSeperator,item]];
        }
        else
        {
            [self.navigationItem setRightBarButtonItems:@[negativeSeperator]];
        }
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:item animated:NO];
    }
}
- (void)setBackButton
{
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 50, 30);
    [backBtn setImage:[UIImage imageNamed:@"public_back_w"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(onBackButtonItemAction:) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setBackgroundColor:[UIColor clearColor]];
    [backBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 15)];
    if (backBtn.imageView.image)
    {
        [self setLeftBarButtonWithButton:backBtn];
    }
}
- (void)setLeftBarButtonWithButton:(UIButton *)button
{
    [button addTarget:self action:@selector(onBackButtonItemAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSeperator.width = -18;
        if (item)
        {
            [self.navigationItem setLeftBarButtonItems:@[negativeSeperator,item]];
        }
        else
        {
            [self.navigationItem setLeftBarButtonItems:@[negativeSeperator]];
        }
    }
    else
    {
        [self.navigationItem setLeftBarButtonItem:item animated:NO];
    }
}
- (void)onBackButtonItemAction:(UIButton *)btn
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupAssets
{
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.numberOfPhotos = 0;
    self.numberOfVideos = 0;
    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        [self.assets removeAllObjects];
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        
        if (asset)
        {
            [self.assets addObject:asset];
            
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            
            if ([type isEqual:ALAssetTypePhoto])
                self.numberOfPhotos ++;
            if ([type isEqual:ALAssetTypeVideo])
                self.numberOfVideos ++;
        }
        
        else if (self.assets.count > 0)
        {
            [self.collectionView reloadData];
            //            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.assets.count-1 inSection:0]
            //                                        atScrollPosition:UICollectionViewScrollPositionTop
            //                                                animated:YES];
        }
    };
    
    [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kAssetsViewCellIdentifier;
    FGAssetsPickerController *picker = (FGAssetsPickerController *)self.navigationController;
    FGAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ALAsset* asset = [self.assets objectAtIndex:indexPath.row];
    [cell bind:asset];
    cell.disabled = YES;
    cell.disabled = ! [picker.selectionFilter evaluateWithObject:asset];
    [cell setBackgroundColor:indexPath.row%2==0?[UIColor purpleColor]:[UIColor greenColor]];

    return cell;
}


#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGAssetsPickerController *vc = (FGAssetsPickerController *)self.navigationController;
    ALAsset* asset = [self.assets objectAtIndex:indexPath.row];
    BOOL selectable = [vc.selectionFilter evaluateWithObject:asset];
    if (selectable && collectionView.indexPathsForSelectedItems.count >= vc.maximumNumberOfSelection)
    {
        if (vc.delegate && [vc.delegate respondsToSelector:@selector(assetsPickerController:didSelectedMaximumNumberItem:)]) {
            [vc.delegate assetsPickerController:vc didSelectedMaximumNumberItem:vc.maximumNumberOfSelection];
        }
    }
    BOOL should = selectable && collectionView.indexPathsForSelectedItems.count < vc.maximumNumberOfSelection;
    return should;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGAssetsPickerController *vc = (FGAssetsPickerController *)self.navigationController;
    vc.indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems;
    
    if ([vc.delegate respondsToSelector:@selector(assetsPickerController:didSelectItemAtIndexPath:)])
        [vc.delegate assetsPickerController:vc didSelectItemAtIndexPath:indexPath];
    
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGAssetsPickerController *vc = (FGAssetsPickerController *)self.navigationController;
    vc.indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems;
    
    if ([vc.delegate respondsToSelector:@selector(assetsPickerController:didDeselectItemAtIndexPath:)])
        [vc.delegate assetsPickerController:vc didDeselectItemAtIndexPath:indexPath];
    
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}


#pragma mark - Title

- (void)setTitleWithSelectedIndexPaths:(NSArray *)indexPaths
{
    self.numberBtn.hidden = NO;
    _rightBtn.userInteractionEnabled = YES;
    [_rightBtn setTitleColor:kTitleColor forState:UIControlStateNormal];
    if (indexPaths.count == 0)
    {
        self.numberBtn.hidden = YES;
        _rightBtn.userInteractionEnabled = NO;
        [_rightBtn setTitleColor:kUnTitleColor forState:UIControlStateNormal];
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        return;
    }
    self.numberBtn.hidden = !indexPaths.count;
    _rightBtn.userInteractionEnabled = indexPaths.count;
    [_rightBtn setTitleColor:indexPaths.count?kTitleColor:kUnTitleColor forState:UIControlStateNormal];
    
    [self.numberBtn setTitle:[NSString stringWithFormat:@"%zi",indexPaths.count] forState:UIControlStateNormal];
}


#pragma mark - Actions

- (void)finishPickingAssets:(id)sender
{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems)
    {
        [assets addObject:[self.assets objectAtIndex:indexPath.item]];
    }
    
    FGAssetsPickerController *picker = (FGAssetsPickerController *)self.navigationController;
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)])
        [picker.delegate assetsPickerController:picker didFinishPickingAssets:assets];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end



#pragma mark - FGAssetsViewCell

@implementation FGAssetsViewCell

static UIFont *titleFont = nil;

static CGFloat titleHeight;
static UIImage *videoIcon;
static UIColor *titleColor;
static UIImage *checkedIcon;
static UIColor *selectedColor;
static UIColor *disabledColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    videoIcon       = [UIImage imageNamed:@"public_unselected"];
    titleColor      = [UIColor whiteColor];
    checkedIcon = [UIImage imageNamed:@"public_unselected"];
    selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
    disabledColor   = [UIColor colorWithWhite:1 alpha:0.9];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                     = YES;
        self.isAccessibilityElement     = YES;
        self.accessibilityTraits        = UIAccessibilityTraitImage;
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset
{
    self.asset  = asset;
    self.image  = [UIImage imageWithCGImage:asset.thumbnail];
    self.type   = [asset valueForProperty:ALAssetPropertyType];
    self.title  = [self timeDescriptionOfTimeInterval:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]];
}

- (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponents *components = [self componetsWithTimeInterval:timeInterval];
    
    if (components.hour > 0)
    {
        return [NSString stringWithFormat:@"%zi:%02zi:%02zi", components.hour, components.minute, components.second];
    }
    
    else
    {
        return [NSString stringWithFormat:@"%zi:%02zi", components.minute, components.second];
    }
}

- (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:date1];
    
    unsigned int unitFlags =
    NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |
    NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    
    return [calendar components:unitFlags
                       fromDate:date1
                         toDate:date2
                        options:0];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


// Draw everything to improve scrolling responsiveness

- (void)drawRect:(CGRect)rect
{
    // Image
    [self.image drawInRect:CGRectMake(0, 0, kThumbnailLength, kThumbnailLength)];
    
    // Video title
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        // Create a gradient from transparent to black
        CGFloat colors [] = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.8,
            0.0, 0.0, 0.0, 1.0
        };
        
        CGFloat locations [] = {0.0, 0.75, 1.0};
        
        CGColorSpaceRef baseSpace   = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient      = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
        
        CGContextRef context    = UIGraphicsGetCurrentContext();
        
        CGFloat height          = rect.size.height;
        CGPoint startPoint      = CGPointMake(CGRectGetMidX(rect), height - titleHeight);
        CGPoint endPoint        = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
        
        CGSize titleSize        = [self.title sizeWithFont:titleFont];
        [titleColor set];
        [self.title drawAtPoint:CGPointMake(rect.size.width - titleSize.width - 2 , startPoint.y + (titleHeight - 12) / 2)
                       forWidth:kThumbnailLength
                       withFont:titleFont
                       fontSize:12
                  lineBreakMode:NSLineBreakByTruncatingTail
             baselineAdjustment:UIBaselineAdjustmentAlignCenters];
        
        [videoIcon drawAtPoint:CGPointMake(2, startPoint.y + (titleHeight - videoIcon.size.height) / 2)];
    }
    if (self.disabled)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, disabledColor.CGColor);
        CGContextFillRect(context, rect);
    }
    else if (self.selected)
    {
        checkedIcon = [UIImage imageNamed:@"public_selected"];
        
        CGContextRef context    = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, selectedColor.CGColor);
        CGContextFillRect(context, rect);
        
        [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
    }
    else if (!self.selected)
    {
        checkedIcon = [UIImage imageNamed:@"public_unselected"];
        [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
    }
}

@end