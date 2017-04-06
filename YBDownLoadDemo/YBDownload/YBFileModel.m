//
//  YBFileModel.m
//  YBDownLoadDemo
//
//  Created by wyb on 2017/4/5.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import "YBFileModel.h"
#import <CommonCrypto/CommonDigest.h>

// 缓存主文件夹，所有下载下来的文件都放在这个文件夹下
#define YBCacheDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YBCacheDir"]


@interface YBFileModel ()
{
      DownloadState _state;
    
}

/** 存放所有的文件大小 */
//@property(nonatomic,strong)NSMutableDictionary *totalFilesSizeDic;
/** 存放所有的文件大小的文件路径 */
@property(nonatomic,copy)NSString *totalFilesSizePath;

@end

@implementation YBFileModel

- (NSString *)totalFilesSizePath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDic = false;
    BOOL isDirExist = [manager fileExistsAtPath:YBCacheDirectory isDirectory:&isDic];
    if (!isDic && !isDirExist) {
        
        //创建文件夹存放下载的文件
        [manager createDirectoryAtPath:YBCacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //文件路径
    if (_totalFilesSizePath == nil) {
        _totalFilesSizePath = [YBCacheDirectory stringByAppendingPathComponent:@"downloadFileSizes.plist"];
    }
    
    return  _totalFilesSizePath;
}

- (NSString *)filePath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDic = false;
    BOOL isDirExist = [manager fileExistsAtPath:YBCacheDirectory isDirectory:&isDic];
    if (!isDic && !isDirExist) {
        
        //创建文件夹存放下载的文件
        [manager createDirectoryAtPath:YBCacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //文件路径
    if (_filePath == nil) {
        _filePath = [YBCacheDirectory stringByAppendingPathComponent:self.filename];
    }
    
    return  _filePath;
    
}

- (NSString *)filename
{
    if (_filename == nil) {
        //url的扩展名，如.mp4啥的
        NSString *fileExtension = self.fileUrl.pathExtension;
        NSString *fileNameMd5 = [self encryptFileNameWithMD5:self.fileUrl];
        if (fileExtension.length) {
            _filename = [NSString stringWithFormat:@"%@.%@", fileNameMd5, fileExtension];
        } else {
            _filename = fileNameMd5;
        }
    }
    return _filename;
}


/**
   将文件名md5加密
 */
- (NSString *)encryptFileNameWithMD5:(NSString *)str
{
    //要进行UTF8的转码
    const char* input = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    
    return digest;
}

- (NSOutputStream *)stream
{
    if (_stream == nil) {
        _stream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:YES];
    }
    return _stream;
}

- (NSInteger)totlalReceivedSize
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    
    NSInteger reveiveSize = [[manager attributesOfItemAtPath:self.filePath error:nil][NSFileSize] integerValue];
    
    return reveiveSize;
}

- (NSInteger)totalExpectedSize
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.totalFilesSizePath];
    if (dict == nil){
        _totalExpectedSize = 0;
    }else{
       
        _totalExpectedSize = [dict[self.fileUrl] integerValue];
        
    }
    
    return _totalExpectedSize;
}



- (void)setState:(DownloadState)state
{
    DownloadState oldState = self.state;
    if (state == oldState) return;
    
    _state = state;
    
    // 发通知
    [self notifyStateChange];
}

- (void)notifyStateChange
{
    if (self.stateBlock) {
        self.stateBlock(self.state, self.filePath, self.error);
    }
 
}




- (DownloadState)state
{
    
    
    //下载完了
    if (self.totalExpectedSize && self.totalExpectedSize == self.totlalReceivedSize) {
        return DownloadStateCompleted;
    }
    
    //下载出错
    if (self.task.error) {
        
        return DownloadStateError;
    }
    
    return _state;
}

- (void)setupTask:(NSURLSession *)session
{
    if (self.task) return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.fileUrl]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.totlalReceivedSize];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    self.task = [session dataTaskWithRequest:request];
    // 设置描述
    self.task.taskDescription = self.fileUrl;
}

/**
 *  恢复
 */
- (void)resume
{
    if (self.state == DownloadStateCompleted || self.state == DownloadStateResumed) return;
    
    [self.task resume];
    self.state = DownloadStateResumed;
}

/**
 * 等待下载
 */
- (void)waitDownload
{
    if (self.state == DownloadStateCompleted || self.state == DownloadStateWait) return;
    
    self.state = DownloadStateWait;
}

#pragma mark - 代理方法处理
- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    // 获得文件总长度
    if (!self.totalExpectedSize) {
      NSInteger totalExpectedSize = [response.allHeaderFields[@"Content-Length"] integerValue] + self.totlalReceivedSize;
        
        // 存储文件总长度
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.totalFilesSizePath];
        if (dict == nil) dict = [NSMutableDictionary dictionary];
        
        dict[self.fileUrl] = @(totalExpectedSize);
        
       bool b =  [dict writeToFile:self.totalFilesSizePath atomically:YES];
        
        if (b == YES) {
            NSLog(@"%@",self.totalFilesSizePath);
        }
    }
    
    // 打开流
    [self.stream open];
    
    // 清空错误
    self.error = nil;
}

- (void)didReceiveData:(NSData *)data
{
    // 写数据
    NSInteger result = [self.stream write:data.bytes maxLength:data.length];
    
    if (result == -1) {
        self.error = self.stream.streamError;
        [self.task cancel]; // 取消请求
    }else{
        self.thisTimeWrittenSize = data.length;
         [self notifyProgressChange]; // 通知进度改变
        
    }
}

- (void)notifyProgressChange
{
    if (self.progressBlock) {
    
        self.progressBlock(self.thisTimeWrittenSize, self.totlalReceivedSize, self.totalExpectedSize);
        
    }
   
}

- (void)didCompleteWithError:(NSError *)error
{
    // 关闭流
    [self.stream close];
    self.thisTimeWrittenSize = 0;
    self.stream = nil;
    self.task = nil;
    
    // 错误(避免nil的error覆盖掉之前设置的self.error)
    self.error = error ? error : self.error;
    
    // 通知(如果下载完毕 或者 下载出错了)
    if (self.state == DownloadStateCompleted || error) {
        // 设置状态
        self.state = error ? DownloadStateError : DownloadStateCompleted;
    }
}

/**
 *  暂停
 */
- (void)suspend
{
    if (self.state == DownloadStateCompleted || self.state == DownloadStateStoped) return;
    
    if (self.state == DownloadStateResumed) { // 如果是正在下载
        [self.task suspend];
        self.state = DownloadStateStoped;
    } else { // 如果是等待下载
        self.state = DownloadStateWait;
    }
}



@end
