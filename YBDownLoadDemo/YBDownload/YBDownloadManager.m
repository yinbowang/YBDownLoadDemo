//
//  YBDownloadManager.m
//  YBDownLoadDemo
//
//  Created by wyb on 2017/4/5.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import "YBDownloadManager.h"

// 缓存主文件夹，所有下载下来的文件都放在这个文件夹下
#define YBCacheDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YBCacheDir"]


@interface YBDownloadManager ()<NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *session;
/** 存放所有文件的下载信息 */
@property (strong, nonatomic) NSMutableArray *downloadFileModelArray;

@end

@implementation YBDownloadManager



static YBDownloadManager *_downloadManager;

- (NSMutableArray *)downloadFileModelArray
{
    if (_downloadFileModelArray == nil) {
        _downloadFileModelArray = [NSMutableArray array];
    }
    return _downloadFileModelArray;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return _downloadManager;
}

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}

- (YBFileModel *)downloadFileModelForURL:(NSString *)url
{
    if (url == nil) {
        return  nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileUrl==%@",url];
    
    YBFileModel *model = [[self.downloadFileModelArray filteredArrayUsingPredicate:predicate] firstObject];
    if (model == nil) {
        
        model = [[YBFileModel alloc]init];
        model.fileUrl = url;
        [self.downloadFileModelArray addObject:model];
        
    }
    
    return model;
}

- (YBFileModel *)download:(NSString *)url progress:(ProgressBlock)progress state:(StateBlock)state
{
    if (url == nil) {
        return  nil;
    }
    
    YBFileModel *model = [self downloadFileModelForURL:url];
    model.progressBlock = progress;
    model.stateBlock = state;
    
    if (model.state == DownloadStateCompleted) {
        return model;
    }else if (model.state == DownloadStateResumed)
    {
        return model;
    }
    
    // 创建任务
    [model setupTask:self.session];
    
    //开始任务
    [self resume:url];
    
    return model;
    
}

- (NSURLSession *)session
{
    if (!_session) {
        // 配置
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        // session
        self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    }
    return _session;
}



#pragma mark - <NSURLSessionDataDelegate>
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    YBFileModel *model = [self downloadFileModelForURL:dataTask.taskDescription];
    
    // 处理响应
    [model didReceiveResponse:response];
    
    // 继续
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    YBFileModel *model = [self downloadFileModelForURL:dataTask.taskDescription];
    
    // 处理数据
    [model didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    YBFileModel *model = [self downloadFileModelForURL:task.taskDescription];
    
    // 处理结束
    [model didCompleteWithError:error];
    
    // 让第一个等待下载的文件开始下载
    [self resumeFirstWillResume];
}

#pragma mark - 文件操作
/**
 * 让第一个等待下载的文件开始下载
 */
- (void)resumeFirstWillResume
{
    
   YBFileModel *model = [self.downloadFileModelArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", DownloadStateWait]].firstObject;
    [self resume:model.fileUrl];
}

- (void)resume:(NSString *)url
{
    if (url == nil) return;
    
    YBFileModel *model = [self downloadFileModelForURL:url];
    
    // 正在下载的
    NSArray *downloadingModelArray = [self.downloadFileModelArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", DownloadStateResumed]];
    if (self.maxDownloadingCount && downloadingModelArray.count == self.maxDownloadingCount) {
        // 等待下载
        [model waitDownload];
    } else {
        // 继续
        [model resume];
    }
}


- (void)suspend:(NSString *)url
{
    if (url == nil) return;
    
    // 暂停
    [[self downloadFileModelForURL:url] suspend];
    
    // 取出第一个等待下载的
    [self resumeFirstWillResume];
}

/**
 *  全部文件暂停下载
 */
- (void)suspendAll
{
    [self.downloadFileModelArray enumerateObjectsUsingBlock:^(YBFileModel* model, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [model suspend];
    }];
}

/**
 * 全部文件开始\继续下载
 */
- (void)resumeAll
{
    [self.downloadFileModelArray enumerateObjectsUsingBlock:^(YBFileModel* model, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self resume:model.fileUrl];
    }];
}

@end
