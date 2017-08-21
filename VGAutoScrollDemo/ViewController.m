//
//  ViewController.m
//  VGAutoScrollDemo
//
//  Created by 伟哥 on 2017/8/19.
//  Copyright © 2017年 vege. All rights reserved.
//

#import "ViewController.h"
#import "VGAutoScrollView.h"
@interface ViewController ()<VGAutoScrollViewDelegate,VGAutoScrollViewDataSource>
@property(nonatomic,assign)NSInteger reloadStyle;
@property(nonatomic,strong)VGAutoScrollView * autoScrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _reloadStyle = 0;
    
    _autoScrollView = [[VGAutoScrollView alloc]initWithFrame:self.view.frame];
    _autoScrollView.backgroundColor = [UIColor orangeColor];
    _autoScrollView.delegate = self;
    _autoScrollView.dataSource = self;
    _autoScrollView.sectionHeight = 50;
    [self.view addSubview:_autoScrollView];
    
    
    [_autoScrollView reloadData];
    
    CGFloat buttonWidth = 50.0,buttonHeight = 50.0;
    
    UIButton * resumeButton = [UIButton buttonWithType:0];
    resumeButton.frame = CGRectMake(50, self.view.frame.size.height - buttonHeight, buttonWidth, buttonHeight);
    [resumeButton setTitle:@"暂停" forState:UIControlStateNormal];
    [resumeButton setTitle:@"开始" forState:UIControlStateSelected];
    resumeButton.backgroundColor = [UIColor darkGrayColor];
    [resumeButton addTarget:self action:@selector(resumeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resumeButton];
    
    UIButton * reloadButton = [UIButton buttonWithType:0];
    reloadButton.frame = CGRectMake(self.view.frame.size.width - 50 - buttonWidth, resumeButton.frame.origin.y, resumeButton.frame.size.width, resumeButton.frame.size.height) ;
    
    [reloadButton setTitle:@"刷新" forState:UIControlStateNormal];
    reloadButton.backgroundColor = [UIColor blackColor];
    [reloadButton addTarget:self action:@selector(reloadButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reloadButton];
}

#pragma mark - action
-(void)resumeButtonClick:(UIButton *)button{
    
    if (button.selected) {
        [_autoScrollView resume];
    }else{
        [_autoScrollView pause];
    }
    button.selected = !button.selected;
}

-(void)reloadButtonClick:(UIButton *)button{
    _reloadStyle ++;
    if (_reloadStyle >= 3) {
        _reloadStyle = 0;
    }
    
    [_autoScrollView reloadData];
}
#pragma mark - VGAutoScrollViewDelegate
- (CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView speedInSection:(NSInteger)section{
    int y = (arc4random() % 10);
    CGFloat x = (CGFloat)y * 3.2 /9.0;
    return x;
}
//每个section中item的宽度 默认属性值
-(CGFloat)autoScrollView:(VGAutoScrollView *)autoScrollView itemWidthInSection:(NSInteger)section
{
    return 50.0+arc4random()%50;
}

- (VGAutoScrollViewScrollDirection)autoScrollView:(VGAutoScrollView *)autoScrollView directionInSection:(NSInteger)section
{
    return section % 2 == 0?VGAutoScrollViewScrollDirectionFromLeftToRight:VGAutoScrollViewScrollDirectionFromRightToLeft;
}
#pragma mark - VGAutoScrollViewDataSource

- (NSInteger)numberOfSectionsInAutoScrollView:(VGAutoScrollView *)autoScrollView{
    return 12;
}
- (NSInteger)autoScrollView:(VGAutoScrollView *)autoScrollView numbersOfItemsInSection:(NSInteger)section{
    return 10000;
}

- (UIView *)autoScrollView:(VGAutoScrollView *)autoScrollView viewForItemAtIndexPath:(NSIndexPath *)indexPath{
    UILabel * label = (UILabel *) [autoScrollView dequeueReusableItemViewWithIndex:indexPath];
    if (label == nil) {
        label = [[UILabel alloc]init];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor greenColor];
        label.font = [UIFont systemFontOfSize:10];
        
        
    }
    
    switch (_reloadStyle) {
        case 0:
            label.text = [NSString stringWithFormat:@"row:%ld",(long)indexPath.row];
            label.backgroundColor = indexPath.row %2 == 0?[UIColor redColor]:[UIColor greenColor];
            break;
        case 1:
            label.text = [NSString stringWithFormat:@"滚动到%ld",(long)indexPath.row];
            label.backgroundColor = indexPath.row %2 == 0?[UIColor lightGrayColor]:[UIColor darkGrayColor];
            break;
        default:
            label.text = @"😊😊❤️🦐🦐";
            label.backgroundColor = indexPath.row %2 == 0?[UIColor purpleColor]:[UIColor blueColor];
            break;
            break;
    }
    
    return label;
}

@end
