//
//  YBFileModel.h
//  YBDownLoadDemo
//
//  Created by wyb on 2017/4/5.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 下载的状态 */
typedef NS_ENUM(NSInteger, DownloadState) {
    DownloadStateNone = 0,     // 还没下载
    DownloadStateResumed,      // 下载中
    DownloadStateWait,      // 等待中
    DownloadStateStoped,     // 暂停中
    DownloadStateCompleted,     // 已经完全下载完毕
    DownloadStateError     // 下载出错
};


/**
 下载进度的回调

 @param thisTimeWrittenSize 这次回调返回的数据大小
 @param totlalReceivedSize 已经下载了的文件的大小
 @param TotalExpectedSize 总共期望下载文件的大小
 */
typedef void (^ProgressBlock)(NSInteger thisTimeWrittenSize, NSInteger totlalReceivedSize, NSInteger TotalExpectedSize);

/**
 *  状态改变的回调
 *
 *  @param filePath 文件的下载路径
 *  @param error    失败的描述信息
 */
typedef void (^StateBlock)(DownloadState state, NSString *filePath, NSError *error);


/**
 下载的文件信息
 */
@interface YBFileModel : NSObject

/** 下载状态 */
@property (assign, nonatomic) DownloadState state;
/** 文件名 */
@property (copy, nonatomic) NSString *filename;
/** 文件路径 */
@property (copy, nonatomic) NSString *filePath;
/** 文件url */
@property (copy, nonatomic) NSString *fileUrl;
/** 这次写入的数量 */
@property (assign, nonatomic) NSInteger thisTimeWrittenSize;
/** 已下载的数量 */
@property (assign, nonatomic) NSInteger totlalReceivedSize;
/** 文件的总大小 */
@property (assign, nonatomic) NSInteger totalExpectedSize;
/** 下载的错误信息 */
@property (strong, nonatomic) NSError *error;
/** 进度block */
@property (copy, nonatomic) ProgressBlock progressBlock;
/** 状态block */
@property (copy, nonatomic) StateBlock stateBlock;
/** 任务 */
@property (strong, nonatomic) NSURLSessionDataTask *task;
/** 文件流 */
@property (strong, nonatomic) NSOutputStream *stream;

- (void)setupTask:(NSURLSession *)session;

/**
 *  恢复
 */
- (void)resume;

- (void)suspend;

/**
 * 等待下载
 */
- (void)waitDownload;

- (void)didReceiveResponse:(NSHTTPURLResponse *)response;

- (void)didReceiveData:(NSData *)data;

- (void)didCompleteWithError:(NSError *)error;

@end
