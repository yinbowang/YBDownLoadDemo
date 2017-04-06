//
//  YBDownloadManager.h
//  YBDownLoadDemo
//
//  Created by wyb on 2017/4/5.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBFileModel.h"

@interface YBDownloadManager : NSObject

/** 最大同时下载数 */
@property (assign, nonatomic) int maxDownloadingCount;

+ (instancetype)defaultManager;

/**
 *  获得某个文件的下载信息
 *
 *  @param url 文件的URL
 */
- (YBFileModel *)downloadFileModelForURL:(NSString *)url;

/**
 *  下载一个文件
 *
 *  @param url          文件的URL路径
 *  @param progress     下载进度的回调
 *  @param state        状态改变的回调
 
 */
- (YBFileModel *)download:(NSString *)url progress:(ProgressBlock)progress state:(StateBlock)state;

/**
 *  暂停下载某个文件
 */
- (void)suspend:(NSString *)url;

/**
 *  全部文件暂停下载
 */
- (void)suspendAll;

/**
 * 全部文件开始\继续下载
 */
- (void)resumeAll;

@end
