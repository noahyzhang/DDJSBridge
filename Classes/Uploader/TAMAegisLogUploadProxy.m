//
//  TAMAegisLogUploadProxy.m
//  TAMAegis
//
//  Created by carlyhuang on 2020/5/26.
//  Copyright © 2020 falco. All rights reserved.
//

#import "TAMAegisLogUploadProxy.h"
#import "TAMAccumulateTimer.h"
#import "TAMAegisConfig.h"
#import "TAMAegisUtil.h"
#import "TAMDRAsyncBlockOperation.h"


#define AEGIS_URL               @"https://aegis.qq.com/collect"
#define AEGIS_WHITELIST_URL     @"https://aegis.qq.com/aegis/whitelist"

#define LOCK(lock, ...) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER); \
    __VA_ARGS__; \
dispatch_semaphore_signal(lock);

#define GetAIfSet(A, B) ((A) > 0 ? (A) : (B))


#define DEFAULT_TIMEOUT_SEC              30 // 默认30s超时
#define DEFAULT_GET_WHITELIST_SEC        30 // 白名单30s重试一次
#define DEFAULT_GET_WHITELIST_COUNT      10 // 白名单重试10次5min


typedef enum {
    WhiteListStatus_NONE          = 0, /// 初始状态
    WhiteListStatus_Requesting    = 1, /// 请求中
    WhiteListStatus_IN            = 2, /// 在白名单中
    WhiteListStatus_OUT           = 3, /// 不在白名单中
    WhiteListStatus_NetError      = 4, /// 网络导致请求失败
} WhiteListStatus;



/**
 TAMAegisLogUploadProxy
 */
@interface TAMAegisLogUploadProxy() <TAMAccumulateTimerDelegate>

// sessionId
@property (nonatomic, strong) NSString *sessionId;

// 上传队列
@property(nonatomic, strong) NSOperationQueue *uploadOptQueue;

// 延时合并上传
@property(nonatomic, strong) NSMutableArray<TAMAegisLogData *> *cacheDelayUploadArray;

// property
@property (nonatomic, strong) dispatch_semaphore_t cacheDelayUploadArrayLock;

// property
@property(nonatomic, strong) dispatch_queue_t aegisLogUploadQueue;

// 定时器
@property (nonatomic, strong) id<TAMAccumulateTimer> accTimer;

// 白名单
@property (nonatomic, assign) WhiteListStatus isInWhitListStatus;

// property
@property (nonatomic, strong) dispatch_semaphore_t whitListLock;

// property
@property (nonatomic, strong) NSMutableArray<TAMAegisLogData *> *cacheWhiteListLogArray;

// 上次请求白名单的时间
@property(nonatomic, assign) NSTimeInterval lastRequestWhitListTime;

// 请求白名单累计次数
@property(nonatomic, assign) NSInteger currentRequestWhitListCount;

@end


/**
 TAMAegisLogUploadProxy
 */
@implementation TAMAegisLogUploadProxy

- (instancetype)initWithConfig:(id<TAMAegisConfigProtocol>)config
{
    if (self = [super init]) {
        
        self.sessionId = [NSString stringWithFormat:@"session-%llu", [TAMAegisUtil getSystemMillis]];
        
        self.accTimer = [TAMAccumulateTimer new];
        
        NSUInteger maxNums = 15;
        NSTimeInterval maxTime = 30;
        NSTimeInterval maxInterval = 5;
        [self.accTimer setMaxTotalNums:maxNums maxTotalTime:maxTime maxIntervalTime:maxInterval delegate:self];
        
        self.isInWhitListStatus = WhiteListStatus_NONE;
        self.whitListLock = dispatch_semaphore_create(1);
        
        self.cacheDelayUploadArrayLock = dispatch_semaphore_create(1);
        self.cacheWhiteListLogArray = [[NSMutableArray alloc] init];
        self.cacheDelayUploadArray = [[NSMutableArray alloc] init];
        self.aegisLogUploadQueue = dispatch_queue_create("com.tam.aegis.upload.queue", DISPATCH_QUEUE_SERIAL);
        
        self.uploadOptQueue = [[NSOperationQueue alloc] init];
        self.uploadOptQueue.maxConcurrentOperationCount = GetAIfSet(config.systemConfig.uploadMaxConcurrentOptCount, 6);
    }
    
    return self;
}

- (void)uploadLog:(TAMAegisLogLevel)level
              tag:(NSString *)tag
              msg:(NSString *)msg
           config:(id<TAMAegisConfigProtocol>)config
   uploadStrategy:(TAMAegisUploadStrategy)uploadStrategy
    whiteListOnly:(BOOL)whiteListOnly
{
    if (uploadStrategy == TAMAegisUploadStrategy_NOT) {
        NSLog(@"[TAMAegis]: 上传策略为不上传");
        return;
    }
    
    if (whiteListOnly && self.isInWhitListStatus != WhiteListStatus_IN) {
        LOCK(self.whitListLock, {
            if (self.isInWhitListStatus == WhiteListStatus_NONE) {
                TAMAegisLogData *cacheLogData = [TAMAegisLogData new];
                cacheLogData.level = level;
                cacheLogData.tag = tag;
                cacheLogData.msg = msg;
                cacheLogData.seq = [TAMAegisUtil getSeq];
                cacheLogData.uploadStrategy = uploadStrategy;
                cacheLogData.whiteListOnly = whiteListOnly;
                [self.cacheWhiteListLogArray addObject:cacheLogData];
                
                self.isInWhitListStatus = WhiteListStatus_Requesting;
                [self requestIsInWhiteList:config];
                
            } else if (self.isInWhitListStatus == WhiteListStatus_NetError) {
                TAMAegisLogData *cacheLogData = [TAMAegisLogData new];
                cacheLogData.level = level;
                cacheLogData.tag = tag;
                cacheLogData.msg = msg;
                cacheLogData.seq = [TAMAegisUtil getSeq];
                cacheLogData.uploadStrategy = uploadStrategy;
                cacheLogData.whiteListOnly = whiteListOnly;
                [self.cacheWhiteListLogArray addObject:cacheLogData];
                NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                if (now - self.lastRequestWhitListTime >= DEFAULT_GET_WHITELIST_SEC) {
                    [self requestIsInWhiteList:config];
                }
            } else if (self.isInWhitListStatus == WhiteListStatus_Requesting) {
                TAMAegisLogData *cacheLogData = [TAMAegisLogData new];
                cacheLogData.level = level;
                cacheLogData.tag = tag;
                cacheLogData.msg = msg;
                cacheLogData.seq = [TAMAegisUtil getSeq];
                cacheLogData.uploadStrategy = uploadStrategy;
                cacheLogData.whiteListOnly = whiteListOnly;
                [self.cacheWhiteListLogArray addObject:cacheLogData];
            } else if (self.isInWhitListStatus == WhiteListStatus_OUT) {
                // nothing to do
            }
        });
    } else {
        if (uploadStrategy == TAMAegisUploadStrategy_INMMIDIATELY) {
            [self immediatelyUploadLog:level tag:tag msg:msg config:config];
        } else if (uploadStrategy == TAMAegisUploadStrategy_DELAY) {
            [self delayUploadLog:level tag:tag msg:msg config:config];
        }
    }
}

#pragma mark - Upload
- (void)immediatelyUploadLog:(TAMAegisLogLevel)level
                         tag:(NSString *)tag
                         msg:(NSString *)msg
                      config:(id<TAMAegisConfigProtocol>)config
{
    __weak __typeof(self)weakSelf = self;
    TAMDRAsyncBlockOperationExecutionBlock block = ^(TAMDRAsyncBlockOperationFinishBlock finishBlock) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSString *encodedLog = [TAMAegisUtil urlEncodeLog:msg tag:tag];
        NSString *dataStr = [NSString stringWithFormat:@"msg[0]=%@&level[0]=%lu&&tag[0]=%@&seq[0]=%@&count=1", encodedLog, (unsigned long)level, tag, [TAMAegisUtil getSeq]];
        NSData *bodyData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSInteger retryTime = config.systemConfig.uploadRetryCount;
        [strongSelf sendUploadRequest:bodyData retryTime:retryTime config:config finishBlock:finishBlock];
    };
    
    TAMDRAsyncBlockOperation *opt = [[TAMDRAsyncBlockOperation alloc] initWithBlock:block];
    [self.uploadOptQueue addOperation:opt];
}

- (void)delayUploadLog:(TAMAegisLogLevel)level
                   tag:(NSString *)tag
                   msg:(NSString *)msg
                config:(id<TAMAegisConfigProtocol>)config
{
    LOCK(self.cacheDelayUploadArrayLock, {
        TAMAegisLogData *cacheLogData = [TAMAegisLogData new];
        cacheLogData.level = level;
        cacheLogData.tag = tag;
        cacheLogData.msg = msg;
        cacheLogData.seq = [TAMAegisUtil getSeq];
        cacheLogData.uploadStrategy = TAMAegisUploadStrategy_DELAY;
        cacheLogData.whiteListOnly = NO;
        
        [self.cacheDelayUploadArray addObject:cacheLogData];
        [self.accTimer increase];
    });
}

- (BOOL)immediatelyUploadLogArray:(NSArray<TAMAegisLogData *> *)logArray
{
    if (logArray.count <= 0) {
        return NO;
    }
    
    __weak __typeof(self)weakSelf = self;
    TAMDRAsyncBlockOperationExecutionBlock block = ^(TAMDRAsyncBlockOperationFinishBlock finishBlock) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        NSString * dataStr = @"";
        for (int i = (int)logArray.count - 1; i >= 0; i--) {
            
            int index = (int)logArray.count - 1 - i;
            
            TAMAegisLogData *logData = logArray[i];
            NSString *encodedLog = [TAMAegisUtil urlEncodeLog:logData.msg tag:logData.tag];
            dataStr = [dataStr stringByAppendingFormat:@"msg[%d]=%@&level[%d]=%lu&tag[%d]=%@&seq[%d]=%@&", index, encodedLog, index, (unsigned long)logData.level, index, logData.tag, index, logData.seq];
        }
        dataStr = [dataStr stringByAppendingFormat:@"count=%lu", (unsigned long)logArray.count];
        NSData *bodyData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        
        id<TAMAegisConfigProtocol> config = logArray.firstObject.config;
        NSInteger retryTime = config.systemConfig.uploadRetryCount;
        [strongSelf sendUploadRequest:bodyData retryTime:retryTime config:config finishBlock:finishBlock];
        
    };
    
    TAMDRAsyncBlockOperation *opt = [[TAMDRAsyncBlockOperation alloc] initWithBlock:block];
    [self.uploadOptQueue addOperation:opt];
    
    return YES;
}

#pragma mark - WhiteList
- (BOOL)requestIsInWhiteList:(id<TAMAegisConfigProtocol>)config
{
    if (!config || config.userConfig.appid.length <= 0 || config.userConfig.uin.length <= 0) {
        NSLog(@"[TAMAegis]: appid必填和uin必填");
        return NO; // appid必填 uin必填
    }
    
    self.isInWhitListStatus = YES;
    NSString * urlStr = [NSString stringWithFormat:@"%@?id=%@&uin=%@&version=%@&aid=%@&sessionId=%@",
                         AEGIS_WHITELIST_URL,
                         config.userConfig.appid,
                         config.userConfig.uin,
                         config.userConfig.version,
                         config.userConfig.aid,
                         self.sessionId
    ];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    int timeout = GetAIfSet(config.systemConfig.uploadTimeout, DEFAULT_TIMEOUT_SEC);
    NSURLSession *urlSession = [self sessionWithTimeoutInSec:timeout];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (error) {
            NSLog(@"[TAMAegis]: requestisWhiteList fail: err:%@ data:%@", error, data);
            LOCK(strongSelf.whitListLock, {
                strongSelf.lastRequestWhitListTime = [[NSDate date] timeIntervalSince1970];
                if (strongSelf.currentRequestWhitListCount > DEFAULT_GET_WHITELIST_COUNT) {
                    strongSelf.isInWhitListStatus = WhiteListStatus_OUT;
                } else {
                    strongSelf.isInWhitListStatus = WhiteListStatus_NetError;
                }
            });
        } else {
            [strongSelf parseRequestIsInWhiteListResult:data];
        }
    }];
    [task resume];
    
    return YES;
}

- (void)parseRequestIsInWhiteListResult:(NSData *)data
{
    NSDictionary *rspDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (rspDic) {
        NSObject *resultObj = rspDic[@"result"];
        if (resultObj && [resultObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *resultDic = (NSDictionary *)resultObj;
            NSNumber *isInWhiteListObj = resultDic[@"is_in_white_list"];
            if ([isInWhiteListObj isKindOfClass:[NSNumber class]] && [isInWhiteListObj boolValue]) {
                BOOL isInWhiteList = [isInWhiteListObj boolValue];
                NSLog(@"AegisRequestisWhiteList:%d", isInWhiteList ? 1 : 0);
                [self refreshIsInWhitListStatus:isInWhiteList ? WhiteListStatus_IN : WhiteListStatus_OUT];
                return;
            }
        }
    }
    
    [self refreshIsInWhitListStatus:WhiteListStatus_OUT];
}

- (void)refreshIsInWhitListStatus:(WhiteListStatus)isInWhitListStatus
{
    NSMutableArray *array = [NSMutableArray array];
    
    LOCK(self.whitListLock, {
        self.isInWhitListStatus = isInWhitListStatus;
        
        if (isInWhitListStatus == WhiteListStatus_IN) {
            array = self.cacheWhiteListLogArray.copy;
            [self.cacheWhiteListLogArray removeAllObjects];
        } else if (isInWhitListStatus == WhiteListStatus_NONE || isInWhitListStatus == WhiteListStatus_OUT) {
            [self.cacheWhiteListLogArray removeAllObjects];
        }
    });
    
    NSMutableArray *immediatelyArray = [[NSMutableArray alloc] init];
    NSMutableArray *delayArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(TAMAegisLogData *obj, NSUInteger idx, BOOL *stop) {
        if (obj.uploadStrategy == TAMAegisUploadStrategy_INMMIDIATELY) {
            [immediatelyArray addObject:obj];
        } else if (obj.uploadStrategy == TAMAegisUploadStrategy_DELAY) {
            [delayArray addObject:obj];
        }
    }];
    
    if (immediatelyArray.count > 0) {
        [self immediatelyUploadLogArray:array];
    }
    
    if (delayArray.count > 0) {
        LOCK(self.cacheDelayUploadArrayLock, {
            [self.cacheDelayUploadArray addObjectsFromArray:delayArray];
            [self.accTimer add:delayArray.count];
        });
    }
}

#pragma mark - Request
- (BOOL)sendUploadRequest:(NSData *)data
                retryTime:(NSInteger)retryTime
                   config:(id<TAMAegisConfigProtocol>)config
              finishBlock:(TAMDRAsyncBlockOperationFinishBlock)finishBlock
{
    if (!config.userConfig || config.userConfig.appid.length <= 0) {
        NSLog(@"[TAMAegis]: appid必填和uin必填");
        return NO; // appid必填
    }
    
    NSString * urlStr = [NSString stringWithFormat:@"%@?id=%@&uin=%@&version=%@&aid=%@&sessionId=%@",
                         AEGIS_URL,
                         config.userConfig.appid,
                         config.userConfig.uin,
                         config.userConfig.version,
                         config.userConfig.aid,
                         self.sessionId];
    
    NSURL * url = [NSURL URLWithString:urlStr];
    return [self sendRequest:data url:url retryTime:retryTime config:config finishBlock:finishBlock];
}

- (BOOL)sendRequest:(NSData *)data
                url:(NSURL *)url
          retryTime:(NSInteger)retryTime
             config:(id<TAMAegisConfigProtocol>)config
        finishBlock:(TAMDRAsyncBlockOperationFinishBlock)finishBlock
{
    if (!url) {
        if (finishBlock) {
            finishBlock();
        }
        return NO;
    }
    
    __weak __typeof(self)weakSelf = self;
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithData:data]];
    int timeout = GetAIfSet(config.systemConfig.uploadTimeout, DEFAULT_TIMEOUT_SEC);
    NSURLSession *urlSession = [self sessionWithTimeoutInSec:timeout];
    NSURLSessionDataTask* task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (error && retryTime > 0) {
            NSLog(@"[TAMAegis]: aegisLog upload fail: err:%@ data:%@", error, data);
            [strongSelf sendRequest:data url:url retryTime:(retryTime - 1) config:config finishBlock:finishBlock];
        } else {
            if (finishBlock) {
                finishBlock();
            }
        }
    }];
    
    [task resume];
    
    return YES;
}

- (NSURLSession *)sessionWithTimeoutInSec:(int)timeVal
{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;//是否允许使用蜂窝连接
    sessionConfig.discretionary = NO;  //当系统在前台启动时，忽略电量、网络等
    sessionConfig.timeoutIntervalForRequest = timeVal;//单位是s
    sessionConfig.timeoutIntervalForResource = timeVal * 10; //按照解释，真正生效的应该是这个
    
    return [NSURLSession sessionWithConfiguration:sessionConfig];
}

#pragma mark - TAMAccumulateTimerDelegate
- (void)onAccumulateTimer
{
    dispatch_async(self.aegisLogUploadQueue, ^{
        NSLog(@"[TAMAegis]: onAccumulateTimer");
        NSArray<TAMAegisLogData *> *logDatas = nil;
        LOCK(self.cacheDelayUploadArrayLock, {
            logDatas = self.cacheDelayUploadArray.copy;
            [self.cacheDelayUploadArray removeAllObjects];
        });
        
        if (logDatas.count > 0) {
            NSMutableDictionary<NSString *, NSMutableArray *> *dict = [NSMutableDictionary dictionary];
            for (TAMAegisLogData *log in logDatas)
            {
                NSString *key = [self keyForUpload:log.config];
                NSMutableArray *filterLogArray = dict[key];
                if (filterLogArray == nil) {
                    dict[key] = [NSMutableArray array];
                    filterLogArray = dict[key];
                }
                
                [filterLogArray addObject:log];
            }

            for (NSString *key in dict)
            {
                [self immediatelyUploadLogArray:dict[key]];
            }
        }
    });
}

- (NSString *)keyForUpload:(id<TAMAegisConfigProtocol>)config
{
    return [NSString stringWithFormat:@"%@", config.userConfig.uin];
}

@end
