

//
//  FileCell.m
//  YBDownLoadDemo
//
//  Created by wyb on 2017/3/31.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import "FileCell.h"
#import "YBDownloadManager.h"
#define kScreen_width [UIScreen mainScreen].bounds.size.width
#define kScreen_height [UIScreen mainScreen].bounds.size.height

@interface FileCell ()

@property(nonatomic,strong)UIButton *downLoadBtn;

@property(nonatomic,strong)UILabel *progressLab;
@end

@implementation FileCell


- (void)setUrl:(NSString *)url
{
    _url = url;
    
    // 控制状态
    YBFileModel *info = [[YBDownloadManager defaultManager] downloadFileModelForURL:url];
    if (info.state == DownloadStateResumed) {
        
        
        if (info.totalExpectedSize) {
        
            NSString *str = [NSString stringWithFormat:@"%.2f%%",1.0*info.totlalReceivedSize / info.totalExpectedSize*100];
            NSLog(@"%@",str);
            self.progressLab.text = str;
        }
        
    }else if (info.state == DownloadStateCompleted)
    {
        self.progressLab.text = @"下载完毕";
    }else if (info.state == DownloadStateWait)
    {
        self.progressLab.text = @"等待中";
    }
    
    
    
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self loadUI];
        
    }
    return self;
}

- (void)loadUI
{
    UIButton *downloadBtn = [[UIButton alloc]init];
    downloadBtn.backgroundColor = [UIColor greenColor];
    [downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    [downloadBtn setTitle:@"暂停" forState:UIControlStateSelected];
    [self.contentView addSubview:downloadBtn];
    
    self.downLoadBtn = downloadBtn;
    [self.downLoadBtn addTarget:self action:@selector(downLoadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.progressLab = [[UILabel alloc]init];
    
    [self.contentView addSubview:self.progressLab];
    
    
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.downLoadBtn.frame = CGRectMake(kScreen_width- 60, (self.frame.size.height - 40)/2.0, 50, 40);
    self.progressLab.frame = CGRectMake(kScreen_width- 60-80, (self.frame.size.height - 40)/2.0, 100, 40);
}

- (void)downLoadBtnAction:(UIButton *)btn
{
    btn.selected = !btn.selected;
    
    YBFileModel *info = [[YBDownloadManager defaultManager] downloadFileModelForURL:self.url];
    
    if (info.state == DownloadStateResumed || info.state == DownloadStateWait) {
        // 暂停下载某个文件
        [[YBDownloadManager defaultManager] suspend:self.url];
        
    } else {
        //下载文件
        [[YBDownloadManager defaultManager] download:self.url progress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.url = self.url;
            });
        } state:^(DownloadState state, NSString *file, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.url = self.url;
            });
        }];
    }
}

@end
