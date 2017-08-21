
//
//  VGAutoScrollView.m
//  u8show
//
//  Created by 周智伟 on 2017/6/14.
//  Copyright © 2017年 weking. All rights reserved.
//

#import "VGAutoScrollView.h"


static NSInteger preferredFramesPerSecond = 60.0;//每秒刷新次数


@interface VGAutoScrollViewSectionModel : NSObject
@property(nonatomic,assign)CGFloat goPtPerFresh;//每次刷新需要前进的pt值
@property(nonatomic,assign)CGFloat itemSpace;   //  item 间距
@property(nonatomic,assign)CGFloat itemWidth;   //  item 宽度
@property(nonatomic,assign)NSInteger willAppearIndex; //即将出现的总体数据中的index
@property(nonatomic,assign)NSInteger viewArrayWillDisappearIndex;//即将消失的数组中view 的index
@property(nonatomic,assign)BOOL isReloading;   //是否正在刷新
@property(nonatomic,assign)BOOL isOverLenth;   //整体数量平铺是否超过容器边缘
@property(nonatomic,assign)NSInteger itemCount;//每个section 中 item个数
@property(nonatomic,assign)VGAutoScrollViewScrollDirection direction; //移动方向
@property(nonatomic,assign)UIEdgeInsets sectionInset;  //section 缩进
@property(nonatomic,assign)CGFloat sectionHeight; //每个section 的高度
@property(nonatomic,assign)CGFloat sectionHeaderHeight;//section header 高度
@property(nonatomic,strong)NSMutableArray <VGAutoScrllViewItem *> * itemViewArray;//section上所有的item
@property(nonatomic,weak)UIView * contentView;
@property(nonatomic,assign)CGFloat initX;//第一个item的起始位置
@end
@implementation VGAutoScrollViewSectionModel
@end

@implementation VGAutoScrllViewItem
@end

@interface VGAutoScrollView()<UITableViewDelegate>
{
    //调用多次刷新时刷新view 在数组中的位置记录
    NSInteger oneMoreReloadingViewIndex;
}
@property(nonatomic,copy)NSArray <UIView *> * sectionViewArray;
@property(nonatomic,strong)NSMutableArray <VGAutoScrollViewSectionModel *>* sectionModelArray;
@property(nonatomic,assign)NSInteger sectionCount;
@property(nonatomic,strong)CADisplayLink * displayLink;
@property(nonatomic,copy)NSArray <VGAutoScrllViewItem *> * allItemsArray;
@end
@implementation VGAutoScrollView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        oneMoreReloadingViewIndex = -1;
    }
    return self;
}

-(void)firstLoad
{
    if ([_dataSource respondsToSelector:@selector(numberOfSectionsInAutoScrollView:)]) {
        _sectionCount = [_dataSource numberOfSectionsInAutoScrollView:self];
    }else{
        _sectionCount = 1;
    }
    
    _sectionModelArray =[NSMutableArray arrayWithCapacity:_sectionCount];
    CGFloat Y = 0.0;
    for (int i = 0; i < _sectionCount; i ++) {
        VGAutoScrollViewSectionModel * sectionModel = [[VGAutoScrollViewSectionModel alloc]init];
        [_sectionModelArray addObject:sectionModel];
        
        sectionModel.sectionInset = _sectionInsets;
        sectionModel.sectionHeight = _sectionHeight == 0 ?44:_sectionHeight;
        
        sectionModel.itemWidth = _itemWidth == 0?44:_itemWidth;
        if ([_delegate respondsToSelector:@selector(autoScrollView:itemWidthInSection:)]) {
            sectionModel.itemWidth = [_delegate autoScrollView:self itemWidthInSection:i];
        }
        
        sectionModel.itemSpace = _itemSpace;
        if ([_delegate respondsToSelector:@selector(autoScrollView:itemSpaceInSection:)]) {
            sectionModel.itemSpace = [_delegate autoScrollView:self itemSpaceInSection:i];
        }
        sectionModel.willAppearIndex = 0;
        sectionModel.viewArrayWillDisappearIndex = 0;
        sectionModel.isReloading = YES;
        sectionModel.itemCount = [_dataSource autoScrollView:self numbersOfItemsInSection:i];
        sectionModel.itemViewArray = [NSMutableArray arrayWithCapacity:0];
        sectionModel.goPtPerFresh = _speed == 0?0.5:_speed;
        sectionModel.direction = _direction;
        sectionModel.sectionHeaderHeight = _sectionHeaderHeight;
        if ([_delegate respondsToSelector:@selector(autoScrollView:sectionInsetsInSection:)]) {
            sectionModel.sectionInset = [_delegate autoScrollView:self sectionInsetsInSection:i];
        }if ([_delegate respondsToSelector:@selector(autoScrollView:sectionHeightInSection:)]) {
            sectionModel.sectionHeight = [_delegate autoScrollView:self sectionHeightInSection:i];
        }if ([_delegate respondsToSelector:@selector(autoScrollView:speedInSection:)]){
            sectionModel.goPtPerFresh = [_delegate autoScrollView:self speedInSection:i];
        }if ([_delegate respondsToSelector:@selector(autoScrollView:directionInSection:)]){
            sectionModel.direction = [_delegate autoScrollView:self directionInSection:i];
        }if ([_delegate respondsToSelector:@selector(autoScrellView:sectionHeaderHeightInSection:)]) {
            sectionModel.sectionHeaderHeight = [_delegate autoScrellView:self sectionHeaderHeightInSection:i];
        }
        
        
        Y = Y + sectionModel.sectionHeaderHeight;
        
        UIView * sectionView = [[UIView alloc]initWithFrame:CGRectMake(0,Y, self.frame.size.width, sectionModel.sectionHeight)];
        [self addSubview:sectionView];
        Y = Y+sectionModel.sectionHeight;
        
        UIView * contentView = [[UIView alloc]initWithFrame:CGRectMake(sectionModel.sectionInset.left, sectionModel.sectionInset.top, sectionView.frame.size.width-sectionModel.sectionInset.left-sectionModel.sectionInset.right, sectionModel.sectionHeight-sectionModel.sectionInset.top-sectionModel.sectionInset.bottom)];
        contentView.clipsToBounds = YES;
        [sectionView addSubview:contentView];
        sectionModel.contentView = contentView;
        
        CGFloat X = [self loadXWithSectionModel:sectionModel];
        
        CGFloat changeX = [self loadChangeXWithSectionModel:sectionModel];
        for (int j = 0; j < sectionModel.itemCount; j ++) {
            
            X = X+changeX;
            BOOL isInRange = [self loadIsInRangeWithSectionModel:sectionModel X:X];
            if (isInRange){
                NSIndexPath * indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                
                //添加需要显示的item
                UIView * view = [_dataSource autoScrollView:self viewForItemAtIndexPath:indexPath];
                
                view.frame = CGRectMake(X,0, sectionModel.itemWidth, contentView.frame.size.height);
                [contentView addSubview:view];
                VGAutoScrllViewItem * item = [[VGAutoScrllViewItem alloc]init];
                item.itemView = view;
                item.indexPath = indexPath;
                [sectionModel.itemViewArray addObject:item];
                
                
                
                sectionModel.willAppearIndex = j+1;
                if (sectionModel.willAppearIndex > sectionModel.itemCount-1) {
                    sectionModel.willAppearIndex = 0;
                }

            }
            //
            else{
                sectionModel.isReloading = NO;
                sectionModel.isOverLenth = YES;
                break;
            }
            //count 数量不足以铺满视图
            if (i == sectionModel.itemCount-1) {
                sectionModel.isOverLenth = NO;
                sectionModel.isReloading = NO;
            }
            
            
        }
        
        //没有铺满的情况 不启动动画和定时器
        if (sectionModel.isOverLenth == NO || sectionModel.itemViewArray.count < 2) {
            NSAssert(NO, @"数量太少或长度太短导致无法滑动");
        }
        
    }
    [self startInitAnimate];
}

-(void)loadOneMoreTimes{

    //这里只做到刷新列表数据，改变section中item数量。无法reload 其他属性（如 方向，section数量等）
    [_sectionModelArray enumerateObjectsUsingBlock:^(VGAutoScrollViewSectionModel * _Nonnull sectionModel, NSUInteger sectionIdx, BOOL * _Nonnull stop) {
  
        //在这里获取count数量。可能跟原来相等，减小，或变大
        //更新itemcount
        sectionModel.itemCount = [_dataSource autoScrollView:self numbersOfItemsInSection:sectionIdx];
        
        //这里要加一个判断大小的
        if (sectionModel.willAppearIndex > sectionModel.itemCount - 1) {
            sectionModel.willAppearIndex = 0;
        }
        
        [sectionModel.itemViewArray enumerateObjectsUsingBlock:^(VGAutoScrllViewItem * _Nonnull obj, NSUInteger itemIdx, BOOL * _Nonnull stop) {

            oneMoreReloadingViewIndex = itemIdx;

            //如果刷新前的index，超过了刷新后的数组。就要更新 indexpath
            if (obj.indexPath.row > sectionModel.itemCount-1) {
                obj.indexPath = [NSIndexPath indexPathForRow:obj.indexPath.row - sectionModel.itemCount inSection:obj.indexPath.section];
                
                //续上willAppearindex 避免数据重复
                sectionModel.willAppearIndex = obj.indexPath.row + 1;
                if (sectionModel.willAppearIndex > sectionModel.itemCount - 1) {
                    sectionModel.willAppearIndex = 0;
                }
            }
            [_dataSource autoScrollView:self viewForItemAtIndexPath:obj.indexPath];
        }];
    }];
    oneMoreReloadingViewIndex = -1;
}
#pragma mark - outside method

-(void)reloadData
{
    if (_sectionModelArray.count == 0) {
        [self firstLoad];
    }else{
        [self loadOneMoreTimes];
    }
}

-(UIView *)dequeueReusableItemViewWithIndex:(NSIndexPath*)indexPath{
    
    //section 已经确定。
    VGAutoScrollViewSectionModel * sectionModel = _sectionModelArray[indexPath.section];
    if (sectionModel.isReloading) {
        return nil;
    }if (oneMoreReloadingViewIndex > -1) {
        
//warning 这里之所以用oneMoreReloadingViewIndex， 因为indexPath 主要用来刷新外部数据要接着刷新之前的indexpath。就还需要oneMoreReloadingViewIndex 从 0 开始刷新现在所有的itemView。

        VGAutoScrllViewItem * item = sectionModel.itemViewArray[oneMoreReloadingViewIndex];
        return item.itemView;
    }
    VGAutoScrllViewItem * item = sectionModel.itemViewArray[sectionModel.viewArrayWillDisappearIndex];
    return item.itemView;
}

-(NSArray <VGAutoScrllViewItem *> *)allReuseableItemsFromSection:(NSInteger)section
{
    if (_allItemsArray.count == 0) {
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:0];
        if (section > _sectionModelArray.count-1) {
            return nil;
        }
        VGAutoScrollViewSectionModel * sectionModel = _sectionModelArray[section];
        
        [sectionModel.itemViewArray enumerateObjectsUsingBlock:^(VGAutoScrllViewItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop){
            [array addObject:item];
        }];
      

        self.allItemsArray = array;
    }
    return _allItemsArray;
    
}

//销毁
-(void)destory{
   
    _displayLink.paused = YES;
    [_displayLink invalidate];
    _displayLink = nil;
    
}
#pragma mark - method
-(void)startInitAnimate{
    
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTriggered)];
    _displayLink.frameInterval = 1;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
   
}

-(void)pause{
    if (_displayLink.isPaused == NO) {
        [_displayLink setPaused:YES];
    }
}

-(void)resume{
    if (_displayLink.isPaused == YES) {
        [_displayLink setPaused:NO];
    }
}
#pragma mark - action

-(void)displayLinkTriggered
{
    
    for (int i = 0; i < _sectionModelArray.count ; i ++) {
        VGAutoScrollViewSectionModel * sectionModel = _sectionModelArray[i];
        
        if (sectionModel.viewArrayWillDisappearIndex >= sectionModel.itemViewArray.count){
            return;
        }
        VGAutoScrllViewItem * item = sectionModel.itemViewArray[sectionModel.viewArrayWillDisappearIndex];
        UIView * willDisappearView = item.itemView;
        // view 循环
        BOOL overSide = [self runOversideWithSectionModel:sectionModel viewDisappearView:willDisappearView];
        
        if (overSide) {
            
            //更新即将显示的item的indexPath
            NSIndexPath * willAppearIndexPath = [NSIndexPath indexPathForRow:sectionModel.willAppearIndex inSection:i];
            
            item.indexPath = willAppearIndexPath;
            //跳到位置的时侯刷新数据
            willDisappearView = [_dataSource autoScrollView:self viewForItemAtIndexPath:willAppearIndexPath];
            sectionModel.willAppearIndex=sectionModel.willAppearIndex+1;
            if (sectionModel.willAppearIndex > sectionModel.itemCount-1) {
                sectionModel.willAppearIndex = 0;
            }
            
            
            
            NSInteger beforeIndex = sectionModel.viewArrayWillDisappearIndex-1;
            if (beforeIndex < 0) {
                beforeIndex = sectionModel.itemViewArray.count-1;
            }
            UIView * beforeObj = sectionModel.itemViewArray[beforeIndex].itemView;
            
           
            willDisappearView.frame = [self willDisappearViewFrameWithBeforeItem:beforeObj sectionModel:sectionModel];
            
            sectionModel.viewArrayWillDisappearIndex = sectionModel.viewArrayWillDisappearIndex+1;
            if (sectionModel.viewArrayWillDisappearIndex > sectionModel.itemViewArray.count-1) {
                sectionModel.viewArrayWillDisappearIndex = 0;
            }
            
            
        }
        
        [sectionModel.itemViewArray enumerateObjectsUsingBlock:^(VGAutoScrllViewItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            UIView * itemView = obj.itemView;
            itemView.frame = CGRectMake(itemView.frame.origin.x + [self runDistancePerFresh:sectionModel], itemView.frame.origin.y, itemView.frame.size.width, itemView.frame.size.height);
            if ([_delegate respondsToSelector:@selector(autoScrollView:itemFreshWithItem:)]) {
                [_delegate autoScrollView:self itemFreshWithItem:obj];
            }
           
        }];
        
    }

    
    
}

#pragma mark - 方向不同需要所需不同的判断方法
#pragma mark - 初始化reload过程中
-(CGFloat)loadXWithSectionModel:(VGAutoScrollViewSectionModel *)sectionModel{
    CGFloat X = sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight? sectionModel.contentView.frame.size.width:-sectionModel.itemWidth-sectionModel.itemSpace;
    return X;
}

-(CGFloat)loadChangeXWithSectionModel:(VGAutoScrollViewSectionModel *)sectionModel{
    CGFloat changeX = sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight?-(sectionModel.itemWidth+sectionModel.itemSpace): sectionModel.itemWidth + sectionModel.itemSpace;
    return changeX;
}

-(BOOL)loadIsInRangeWithSectionModel:(VGAutoScrollViewSectionModel *)sectionModel X:(CGFloat )X{
    BOOL isInRange;
    if (sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight) {
       isInRange  = X +3*sectionModel.itemWidth+ 2*sectionModel.itemSpace>= 0;
    }else{
        isInRange = X -3*sectionModel.itemWidth - 2*sectionModel.itemSpace <= sectionModel.contentView.frame.size.width;
    }
    return isInRange;
}
#pragma mark - 运动过程中
-(BOOL)runOversideWithSectionModel:(VGAutoScrollViewSectionModel *)sectionModel viewDisappearView:(UIView *)disappearView{
    BOOL overSide;
    
    if (sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight) {
        overSide =  disappearView.frame.origin.x >= sectionModel.contentView.frame.size.width;
    }else{
        overSide = disappearView.frame.origin.x<= -sectionModel.itemWidth;
    }
    return overSide;
}

-(CGRect)willDisappearViewFrameWithBeforeItem:(UIView *)beforeItem sectionModel:(VGAutoScrollViewSectionModel *)sectionModel{
    CGRect frame;
    if (sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight) {
       frame = CGRectMake(beforeItem.frame.origin.x-sectionModel.itemWidth-sectionModel.itemSpace, 0, sectionModel.itemWidth, sectionModel.contentView.frame.size.height);
    }else{
        frame = CGRectMake(beforeItem.frame.origin.x + sectionModel.itemWidth + sectionModel.itemSpace, 0, sectionModel.itemWidth, sectionModel.contentView.frame.size.height);
    }
    return frame;
}

-(CGFloat)runDistancePerFresh:(VGAutoScrollViewSectionModel *)sectionModel{
    return sectionModel.direction == VGAutoScrollViewScrollDirectionFromLeftToRight?sectionModel.goPtPerFresh:-sectionModel.goPtPerFresh;
}

@end


