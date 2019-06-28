//
//  FSAttentionListViewController.m
//  FSIPM
//
//  Created by nickwong on 2019/1/14.
//  Copyright © 2019 nickwong. All rights reserved.

#import "FSAttentionListViewController.h"
#import "FSInfoDetailViewController.h"
#import "FSInfoListTableViewCell.h"
#import "FSInfoOfAllListTableViewCell.h"
#import "UIView+SDAutoLayout.h"
#import "UITableView+SDAutoTableViewCellHeight.h"
#import "CQScrollMenuView.h"
#import "UIView+frameAdjust.h"

@interface FSAttentionListViewController ()<CQScrollMenuViewDelegate,recevFinish>
{
    FS_Request *_request;
}

@property (nonatomic,strong) CQScrollMenuView *menuView;
@property (nonatomic, strong) NSMutableArray *dataResourceArr;
@property (nonatomic,strong) UIView *headerView;
@property (nonatomic, assign) NSInteger currentTerminalCustomInfoId;

@end

@implementation FSAttentionListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [Tools getColor:@"F7F7F7" isSingleColor:YES];
    _dataResourceArr = [[NSMutableArray alloc]init];
    _currentTerminalCustomInfoId = 0;
    FSNSUserDefault(FSUser);
    NSString *isCustomSite = [FSUser objectForKey:@"isCustomSite"];
    FSLog(@"在关注列表中isCustomSite为%@",isCustomSite);
    if(![FSUser objectForKey:Ipm_Uid]){
        self.tableView.hidden = YES;
        [self addPersonalCustomBtn];
    }else{
        if([isCustomSite isEqualToString:@"1"]){
            for (UIView *subview in [self.view subviews]) {
                if (subview.tag == 100) {
                    [subview removeFromSuperview];
                }
            }
            [self addMJRefresh];
            self.tableView.hidden = NO;
            // 设置tableView的sectionHeadHeight为segmentViewHeight
            self.tableView.sectionHeaderHeight = 44;
            //            [self setHeaderView];
            [self sendAttentionListRequest];
        }else{
            self.tableView.hidden = YES;
            [self addPersonalCustomBtn];
        }
    }
    
    [self setUpNotification];
}

-(void)setUpNotification
{
    [FSNotificationCenter addObserver:self selector:@selector(refreshAttentionPage) name:@"refreshAttentionPage" object:nil];

    [FSNotificationCenter addObserver:self selector:@selector(loadAttentionList) name:@"loadAttentionList" object:nil];
//
//    [FSNotificationCenter addObserver:self selector:@selector(resetMenuView) name:@"resetMenuView" object:nil];
    
}


#pragma mark --销毁通知
- (void)dealloc
{
    [FSNotificationCenter removeObserver:self name:@"refreshAttentionPage" object:nil];
    [FSNotificationCenter removeObserver:self name:@"loadAttentionList" object:nil];
//    [FSNotificationCenter removeObserver:self name:@"resetMenuView" object:nil];
}

-(void)refreshAttentionPage
{
    if(_dataResourceArr.count > 0){
        [_dataResourceArr removeAllObjects];
    }
    
    for (UIView *subview in [self.view subviews]) {
        if (subview.tag == 100) {
            [subview removeFromSuperview];
        }
    }
    
    // 上拉刷新
    [self.tableView reloadData];
    
    self.tableView.hidden = YES;
    self.tableView.mj_footer.hidden = YES;
    self.tableView.mj_header.hidden = YES;
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer endRefreshing];
    [self addPersonalCustomBtn];
    
}

-(void)loadAttentionList{
    FSNSUserDefault(FSUser);
    NSString *isCustomSite = [FSUser objectForKey:@"isCustomSite"];
    if([isCustomSite isEqualToString:@"0"]){
        return;
    }
    
    for (UIView *subview in [self.view subviews]) {
        if (subview.tag == 100) {
            [subview removeFromSuperview];
        }
    }
    
    [self addMJRefresh];
    
    [FSNotificationCenter postNotificationName:@"changeMenuViewAlpha" object:nil];
    
    _currentTerminalCustomInfoId = 0;
    self.tableView.hidden = NO;
//    [self menuEventClickWithIndex:0];

    [self sendAttentionListRequest];
}


-(void)addPersonalCustomBtn
{
    /** 添加定制按钮 */
    UIButton *personalCustomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    personalCustomBtn.frame = CGRectMake((FSScreenWidth-120)/2, self.view.centerY, 120, 45);
    personalCustomBtn.tag = 100;
    [personalCustomBtn addTarget:self action:@selector(usePersonalCustom) forControlEvents:UIControlEventTouchUpInside];
    [personalCustomBtn setTitle:@"定制" forState:UIControlStateNormal];
    personalCustomBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    personalCustomBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [personalCustomBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [personalCustomBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    personalCustomBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [personalCustomBtn setBackgroundImage:[UIImage imageNamed:@"btn01_normal"] forState:UIControlStateNormal];
    [personalCustomBtn setBackgroundImage:[UIImage imageNamed:@"btn01_highlighted"] forState:UIControlStateHighlighted];
    [personalCustomBtn.layer setMasksToBounds:YES];
    [personalCustomBtn.layer setCornerRadius:5.0];
    [self.view addSubview:personalCustomBtn];
}


#pragma mark --关于刷新
- (void)addMJRefresh
{
    // 下拉刷新
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(headerRereshing)];
    self.tableView.mj_header.ignoredScrollViewContentInsetTop = -44;
}

#pragma mark -- 下拉刷新
- (void)headerRereshing
{
    [FSNotificationCenter postNotificationName:kScrollViewRefreshStateNSNotification object:nil userInfo:@{@"isRefreshing":@(YES)}];
    
    //    [ProgressHUD show:@"最新加载"];
    [self sendAttentionListRequest];
}

-(void)sendAttentionListRequest
{
    FSLog(@"发送请求");

    [ProgressHUD show:@"正在加载"];
    
    [[self getRequest] sendRequestWithUrl:getModifiedLastestFocusInfoList
                               parameters:[FSRequestDictionary
                                           get_ModifiedLastestFocusInfoList:0
                                           pageNumber:1
                                           pageSize:10
                                           terminalCustomInfoId:_currentTerminalCustomInfoId]
                              NetWorkType:getModifiedLastestFocusInfoListTag];
}

#pragma mark -- 上拉加载更多
- (void)footerRereshing
{
    [FSNotificationCenter postNotificationName:kScrollViewRefreshStateNSNotification object:nil userInfo:@{@"isRefreshing":@(YES)}];
    
    FSInfoListModel *model = [_dataResourceArr lastObject];
    FSLog(@"array的最后一个newsSimplifyId为%ld",(long)model.newsSimplifyId);
    
    [[self getRequest] sendRequestWithUrl:getModifiedLastestFocusInfoList
                               parameters:[FSRequestDictionary
                                           get_ModifiedLastestFocusInfoList:model.newsSimplifyId
                                           pageNumber:1
                                           pageSize:10
                                           terminalCustomInfoId:_currentTerminalCustomInfoId]
                              NetWorkType:getBeforeModifiedLastestFocusInfoListTag];
}



// 自定义表头
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = nil;
    
    return header;
}

#pragma mark - Delegate - 菜单栏
// 菜单按钮点击时回调
- (void)menuEventClickWithIndex:(NSInteger)index
{
    // tableView滚动到对应组
    FSLog(@"注意index为%ld",(long)index);
    if(_currentTerminalCustomInfoId != index){
        _currentTerminalCustomInfoId = index;
    }else{
        return;
    }
    
    if (_dataResourceArr.count > 0) {
        [_dataResourceArr removeAllObjects];
    }
    
    // 上拉刷新
    self.tableView.mj_footer.hidden = NO;
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(footerRereshing)];
    [self sendAttentionListRequest];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataResourceArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_currentTerminalCustomInfoId == 0){
        static NSString *flag = @"cellOne";
        FSInfoOfAllListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:flag];
        if (!cell) {
            cell = [[FSInfoOfAllListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        }
        if (_dataResourceArr.count) {
            cell.model = _dataResourceArr[indexPath.row];
            [cell useCellFrameCacheWithIndexPath:indexPath tableView:tableView];
        }
        return cell;
    }else{
        static NSString *flag = @"cellTwo";
        FSInfoListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:flag];
        if (!cell) {
            cell = [[FSInfoListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        }
        
        //    FSInfoOfAllListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:flag];
        //    if (!cell) {
        //        cell = [[FSInfoOfAllListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        //    }
        
        if (_dataResourceArr.count) {
            cell.model = _dataResourceArr[indexPath.row];
            [cell useCellFrameCacheWithIndexPath:indexPath tableView:tableView];
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id model;
    if (_dataResourceArr.count>0) {
        model= self.dataResourceArr[indexPath.row];
        if(_currentTerminalCustomInfoId == 0){
            return [self.tableView cellHeightForIndexPath:indexPath model:model keyPath:@"model" cellClass:[FSInfoOfAllListTableViewCell class] contentViewWidth:[self cellContentViewWith]];
        }else{
            return [self.tableView cellHeightForIndexPath:indexPath model:model keyPath:@"model" cellClass:[FSInfoListTableViewCell class] contentViewWidth:[self cellContentViewWith]];
        }
    }else{
        return 0;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSNSUserDefault(FSUser);
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FSInfoListModel *model = _dataResourceArr[indexPath.row];
    if ([FSUser objectForKey:Ipm_Uid]) {
        FSInfoDetailViewController *infoDetailVC = [[FSInfoDetailViewController alloc]init];
        infoDetailVC.newsSimplifyId = model.newsSimplifyId;
        infoDetailVC.title = @"资讯详情";
        [self.navigationController pushViewController:infoDetailVC animated:YES];
    }else{
        FSInfoDetailForVisitorViewController *infoDetailForVisitorVC = [[FSInfoDetailForVisitorViewController alloc]init];
        infoDetailForVisitorVC.newsSimplifyId = model.newsSimplifyId;
        infoDetailForVisitorVC.title = @"资讯详情";
        [self.navigationController pushViewController:infoDetailForVisitorVC animated:YES];
    }
}

- (CGFloat)cellContentViewWith
{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    // 适配ios7横屏
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait && [[UIDevice currentDevice].systemVersion floatValue] < 8) {
        width = [UIScreen mainScreen].bounds.size.height;
    }
    return width;
}

#pragma mark 网络请求成功与否的代理方法
- (void)requestDidSuccess:(NSData *)receiveData andNetWorkType:(NSInteger)netType
{
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:receiveData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    [ProgressHUD dismiss];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    for (UIView *subview in [self.view subviews]) {
        if (subview.tag == 10000) {
            [subview removeFromSuperview];
        }
    }
    
    [FSNotificationCenter postNotificationName:kScrollViewRefreshStateNSNotification object:nil userInfo:@{@"isRefreshing":@(NO)}];
    
    if (getModifiedLastestFocusInfoListTag == netType) {
        [self.tableView.mj_header endRefreshing];
        if ([dict[@"message"] isEqualToString:@"成功"]) {
            FSLog(@"成功获取指定的资讯消息id之后的指定数量的资讯列表");
            if(receiveData.length == 0)
            {
                return;
            }
            
            if(_dataResourceArr.count > 0){
                [_dataResourceArr removeAllObjects];
            }
            
            FS_Jason *json = [[FS_Jason alloc]init];
            NSArray *array = [json getArrayFromJason:receiveData withConnectType:getModifiedLastestFocusInfoListTag];
            
            if (array.count > 0){
                [_dataResourceArr addObjectsFromArray:array];
            }else{
                //                [self.tableView tableViewDisplayWitMsg:@"我的关注暂无数据" ifNecessaryForRowCount:_dataResourceArr.count];
            }
            
            FSLog(@"数据的长度为%lu",(unsigned long)_dataResourceArr.count);
            if (array.count >= kPageCount)
            {
                // 上拉刷新
                self.tableView.mj_footer.hidden = NO;
                self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(footerRereshing)];
            }
            else
            {
                self.tableView.mj_footer.hidden = YES;
            }
            
            // 刷新表格
            [self.tableView reloadData];
            
            if (array.count < kPageCount)
            {
                self.tableView.mj_footer.hidden = NO;
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            if (self.tableView.visibleCells.count > 0)
            {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
            }
            
        }else{
            FSLog(@"返回信息是%@",dict[@"message"]);
            [Tools showTipsWithHUD:dict[@"message"] showTime:1];
        }
    }
    
    if (getBeforeModifiedLastestFocusInfoListTag == netType) {
        if ([dict[@"message"] isEqualToString:@"成功"]) {
            if(receiveData.length == 0)
            {
                return;
            }
            FS_Jason *json = [[FS_Jason alloc]init];
            NSArray *array = [json getArrayFromJason:receiveData withConnectType:getBeforeModifiedLastestFocusInfoListTag];
            
            // 将最新的资讯数据，添加到总数组的最后面
            if (array.count > 0)
            {
                [_dataResourceArr addObjectsFromArray:array];
                [self.tableView.mj_footer endRefreshing];
            }
            else
            {
                self.tableView.mj_footer.hidden = NO;
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            //            [self.tableView tableViewDisplayWitMsg:@"我的关注暂无数据" ifNecessaryForRowCount:_dataResourceArr.count];
            // 刷新表格
            [self.tableView reloadData];
        }else{
            FSLog(@"返回信息是%@",dict[@"message"]);
            [Tools showTipsWithHUD:dict[@"message"] showTime:1];
        }
    }
}

-(void)usePersonalCustom
{
    FSLog(@"使用个人定制");
    FSNSUserDefault(FSUser);
    if(![FSUser objectForKey:Ipm_Uid]){
        if([WXApi isWXAppInstalled]) {
            FSWechatViewController *FSWechatMesVC = [[FSWechatViewController alloc]init];
            FSWechatMesVC.title = @"微信登陆";
            [self.navigationController pushViewController:FSWechatMesVC animated:YES];
        }else{
            //            FSBindPhoneViewController *FSBindPhoneVC = [[FSBindPhoneViewController alloc]init];
            //            FSBindPhoneVC.title = @"手机登陆";
            //            [self.navigationController pushViewController:FSBindPhoneVC animated:YES];
            
            FSMobileLoginViewController *FSMobileLoginVC = [[FSMobileLoginViewController alloc]init];
            FSMobileLoginVC.title = @"手机登陆";
            [self.navigationController pushViewController:FSMobileLoginVC animated:YES];
            
        }
        return;
    }else{
        if([[FSUser objectForKey:@"isValidMember"] isEqualToString:@"1"]){
            FSPersonalCustomViewController *FSPersonalCustomVC = [[FSPersonalCustomViewController alloc]init];
            FSPersonalCustomVC.title = @"定制";
            [self.navigationController pushViewController:FSPersonalCustomVC animated:YES];
        }else{
            if([FSUser objectForKey:@"inviteMeCode"]){
                FSMemberServiceViewController *FSMemberServiceVC = [[FSMemberServiceViewController alloc]init];
                FSMemberServiceVC.title = @"会员";
                [self.navigationController pushViewController:FSMemberServiceVC animated:YES];
            }else{
                FSInviteMeCodeViewController *FSInviteMeCodeVC = [[FSInviteMeCodeViewController alloc]init];
                FSInviteMeCodeVC.title = @"邀请码";
                [self.navigationController pushViewController:FSInviteMeCodeVC animated:YES];
            }
        }
    }
}

- (void)requestDidFailure:(NSError *)error andNetWorkType:(NSInteger)netType
{
    [ProgressHUD dismiss];
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer endRefreshing];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showTipsWithHUD:netWork_isAbnormal showTime:1.0];
    
    FSNSUserDefault(FSUser);
    NSString *isCustomSite = [FSUser objectForKey:@"isCustomSite"];
    
    /** 添加提示 */
    if(_dataResourceArr.count == 0 && [isCustomSite isEqualToString:@"1"]){
        [self.tableView reloadData];
        UILabel *networkLb  = [[UILabel alloc] initWithFrame:CGRectMake((FSScreenWidth-250)/2, self.view.centerY + 20, 250, 45)];
        networkLb.tag = 10000;
        networkLb.text = @"请检查网络情况，再下拉刷新...";
        networkLb.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        networkLb.textAlignment = NSTextAlignmentCenter;
        networkLb.textColor = [UIColor lightGrayColor];
        [self.view addSubview:networkLb];
    }
    
    [FSNotificationCenter postNotificationName:kScrollViewRefreshStateNSNotification object:nil userInfo:@{@"isRefreshing":@(NO)}];
}

#pragma mark --发送网络请求
- (FS_Request *)getRequest
{
    if (_request == nil)
    {
        _request = [[FS_Request alloc]init];
        _request.delegate = self;
    }
    return _request;
}

@end
















//-(UIView *)headerView
//{
//    FSNSUserDefault(FSUser);
//    if(!_headerView && [FSUser objectForKey:@"terminalCustomInfoIdArray"] && [FSUser objectForKey:@"webSiteNameArray"]){
//        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,FSScreenWidth, 44)];
//        _headerView.backgroundColor =  [Tools getColor:@"F7F7F7" isSingleColor:YES];
//        // 创建滚动菜单栏
//        self.menuView = [[CQScrollMenuView alloc]initWithFrame:CGRectMake(5, 0, self.view.width-10, 44)];
//        self.menuView.menuButtonClickedDelegate = self;
//        self.menuView.titleIdArray = [FSUser objectForKey:@"terminalCustomInfoIdArray"];
//        self.menuView.titleArray = [FSUser objectForKey:@"webSiteNameArray"];
////        self.menuView.backgroundColor = nil;
//        self.menuView.backgroundColor = [Tools getColor:@"F7F7F7" isSingleColor:YES];
//        [_headerView addSubview: self.menuView];
//    }
//    return _headerView;
//}


//
//-(void)resetMenuView
//{
////    if(_headerView){
////        [_headerView removeFromSuperview];
////         _headerView = nil;
////    }
//
//    if(self.menuView){
//        [self.menuView removeFromSuperview];
//        self.menuView = nil;
//    }
//
//    FSNSUserDefault(FSUser);
////    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,FSScreenWidth, 44)];
////    _headerView.backgroundColor =  [Tools getColor:@"F7F7F7" isSingleColor:YES];
////    // 创建滚动菜单栏
////
////    self.menuView = [[CQScrollMenuView alloc]initWithFrame:CGRectMake(5, 0, self.view.width-10, 44)];
////    self.menuView.menuButtonClickedDelegate = self;
////    self.menuView.titleIdArray = [FSUser objectForKey:@"terminalCustomInfoIdArray"];
////    self.menuView.titleArray = [FSUser objectForKey:@"webSiteNameArray"];
////    //        self.menuView.backgroundColor = nil;
////    self.menuView.backgroundColor = [Tools getColor:@"F7F7F7" isSingleColor:YES];
////    [_headerView addSubview: self.menuView];
//
////    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,FSScreenWidth, 44)];
//    _headerView.backgroundColor =  [Tools getColor:@"F7F7F7" isSingleColor:YES];
//    // 创建滚动菜单栏
//    self.menuView = [[CQScrollMenuView alloc]initWithFrame:CGRectMake(5, 0, self.view.width-10, 44)];
//    self.menuView.menuButtonClickedDelegate = self;
//    self.menuView.titleIdArray = [FSUser objectForKey:@"terminalCustomInfoIdArray"];
//    self.menuView.titleArray = [FSUser objectForKey:@"webSiteNameArray"];
//    //        self.menuView.backgroundColor = nil;
//    self.menuView.backgroundColor = [Tools getColor:@"F7F7F7" isSingleColor:YES];
//    [_headerView addSubview: self.menuView];
//}

//-(void)setHeaderView
//{
//    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, FSScreenWidth,  40)];
//    headerView.backgroundColor =[UIColor redColor];
//    self.tableView.tableHeaderView = headerView;
//}

//    [[self getRequest] sendRequestWithUrl:getModifiedFocusInfoSearchNewsList
//                               parameters:[FSRequestDictionary
//                                           get_ModifiedFocusInfoSearchNewsList:0
//                                           searchString:@"广东"
//                                           pageNumber:1
//                                           pageSize:10
//                               terminalCustomInfoId:_currentTerminalCustomInfoId]
//                              NetWorkType:getModifiedFocusInfoSearchNewsListTag];

//    [[self getRequest] sendRequestWithUrl:getModifiedFocusInfoSearchNewsList
//                               parameters:[FSRequestDictionary
//                                           get_ModifiedFocusInfoSearchNewsList:model.newsSimplifyId
//                                           searchString:@"广东"
//                                           pageNumber:1
//                                           pageSize:10
//                                           terminalCustomInfoId:_currentTerminalCustomInfoId]
//                              NetWorkType:getBeforeModifiedFocusInfoSearchNewsListTag];
