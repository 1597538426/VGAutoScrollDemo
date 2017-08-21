//
//  VGAutoScrollView.h
//  u8show
//
//  Created by 周智伟 on 2017/6/14.
//  Copyright © 2017年 weking. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, VGAutoScrollViewScrollDirection) {
    VGAutoScrollViewScrollDirectionFromLeftToRight,
    VGAutoScrollViewScrollDirectionFromRightToLeft,
};

@class VGAutoScrollView;
@class VGAutoScrllViewItem;

@protocol VGAutoScrollViewDataSource<NSObject>

@required

- (NSInteger)autoScrollView:(VGAutoScrollView *)autoScrollView numbersOfItemsInSection:(NSInteger)section;

// 给当前item赋值
// 触发时机: 在上一个item 即将消失的时候
// 使用复用方法
- (UIView *)autoScrollView:(VGAutoScrollView *)autoScrollView viewForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
// 默认为1
- (NSInteger)numberOfSectionsInAutoScrollView:(VGAutoScrollView *)autoScrollView;

@end

@protocol VGAutoScrollViewDelegate <NSObject>
@optional
// 默认为（0，0，0，0）
- (UIEdgeInsets)autoScrollView:(VGAutoScrollView *)autoScrollView sectionInsetsInSection:(NSInteger)section;

// 默认为sectionHeight 属性值
- (CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView sectionHeightInSection:(NSInteger)section;

// section 距上个section的长度 默认为sectionHeaderHeight属性值
-(CGFloat)autoScrellView:(VGAutoScrollView *)autoScrollView sectionHeaderHeightInSection:(NSInteger)section;

//前进速度 每1/60s 前进的 pt 值。默认speed属性值
- (CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView speedInSection:(NSInteger)section;

// 前进方向 默认 direction 属性值
- (VGAutoScrollViewScrollDirection)autoScrollView:(VGAutoScrollView *)autoScrollView directionInSection:(NSInteger)section;

//每个section中item的宽度 默认itemWidth属性值
-(CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView itemWidthInSection:(NSInteger)section;

//每个section中item 的距离 默认itemSpace属性值
-(CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView itemSpaceInSection:(NSInteger)section;

//每次displayLink刷新item 会触发
-(void)autoScrollView:(VGAutoScrollView *)autoScrollView
    itemFreshWithItem:(VGAutoScrllViewItem *)item;
@end



/**
 每个滚动的item 相当于cell
 */
@interface VGAutoScrllViewItem : NSObject
@property(nonatomic,weak)UIView * itemView;
@property(nonatomic,strong)NSIndexPath * indexPath;
@end



@interface VGAutoScrollView : UIView
@property (nonatomic, weak) id <VGAutoScrollViewDataSource> dataSource;
@property (nonatomic, weak) id <VGAutoScrollViewDelegate>   delegate;
-(instancetype)initWithFrame:(CGRect)frame;

//获取到 复用该indexPath下的view
-(UIView *)dequeueReusableItemViewWithIndex:(NSIndexPath *)indexPath;

//与tableview 用法一样
//刷新之后保持原位置不变
//只可以刷新 section下item的数辆和数据 暂时无法改变其他值（如 section数量，速度，方向等）
-(void)reloadData;

//获取到所有的可复用的item
-(NSArray <VGAutoScrllViewItem *> *)allReuseableItemsFromSection:(NSInteger)section;

//退出后要调用来销毁displaylink，否则会内存泄漏
-(void)destory;

//暂停displayLink
-(void)pause;

//恢复displayLink
-(void)resume;
@property(nonatomic,assign)CGFloat speed;//每次刷新需要前进的pt值 默认0.5
@property(nonatomic,assign)CGFloat itemWidth;
@property(nonatomic,assign)CGFloat itemSpace;
@property(nonatomic,assign)CGFloat direction;
@property(nonatomic,assign)UIEdgeInsets sectionInsets;
@property(nonatomic,assign)CGFloat sectionHeight;
@property(nonatomic,assign)CGFloat sectionHeaderHeight;

@end


