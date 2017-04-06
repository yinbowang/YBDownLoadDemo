//
//  YBViewController.m
//  YBDownLoadDemo
//
//  Created by wyb on 2017/3/31.
//  Copyright © 2017年 中天易观. All rights reserved.
//

// 获取当前设备屏幕的宽度和高度
#define kScreen_width [UIScreen mainScreen].bounds.size.width
#define kScreen_height [UIScreen mainScreen].bounds.size.height

#import "YBViewController.h"
#import "FileCell.h"
#import "YBDownloadManager.h"

@interface YBViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView *tableView;

@property(nonatomic,strong)NSArray *downloadUrls;

@end

@implementation YBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"全部暂停" style:UIBarButtonItemStyleDone target:self action:@selector(allPause)];
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"全部继续" style:UIBarButtonItemStyleDone target:self action:@selector(allSuspend)];
    
    self.downloadUrls = @[@"http://jlzg.cnrmobile.com/resource/index/sp/jlzg0226.mp4", @"http://sbslive.cnrmobile.com/storage/storage2/51/34/18/3e59db9bb51802c2ef7034793296b724.3gp", @"http://sbslive.cnrmobile.com/storage/storage2/05/61/05/f2609b3b964bbbcfb3e3703dde59a994.3gp", @"http://sbslive.cnrmobile.com/storage/storage2/28/11/28/689f8a52fbef0fbbf51db19ee3276ae5.3gp", @"http://sbslive.cnrmobile.com/storage/storage2/71/28/05/512551c6fcf71615ad5f8ae9bd524069.3gp"];
    
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreen_width, kScreen_height-64) style:UITableViewStylePlain]; 
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerClass:[FileCell class] forCellReuseIdentifier:@"cellid"];
    
    [self.view addSubview:self.tableView];
    
    [YBDownloadManager defaultManager].maxDownloadingCount = 2;
}

- (void)allPause {
   
    [[YBDownloadManager defaultManager] suspendAll];
    
}

- (void)allSuspend {
 
    [[YBDownloadManager defaultManager] resumeAll];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.downloadUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"cellid";
    FileCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    cell.url = self.downloadUrls[indexPath.row];
    cell.selectionStyle =  UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

@end
