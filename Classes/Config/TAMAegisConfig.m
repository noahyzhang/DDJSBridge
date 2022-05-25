//
//  TAMAegisConfig.m
//  FalcoAegisLog
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import "TAMAegisConfig.h"

/// TAMAegisUserConfig
@implementation TAMAegisUserConfig
@end


/// TAMAegisLogStrategy
@implementation TAMAegisLogStrategy
@end


/// TAMAegisSystemConfig
@implementation TAMAegisSystemConfig

+ (instancetype)defaultTAMAegisSystemConfig
{
    TAMAegisSystemConfig *config = [TAMAegisSystemConfig new];
    config.uploadMaxConcurrentOptCount = 6;
    config.uploadRetryCount = 0;
    config.uploadTimeout = 30;
    
    return config;
}

@end


/// TAMAegisLogConfig
@implementation TAMAegisLogConfig

+ (instancetype)defaultTAMAegisLogConfig
{
    TAMAegisLogConfig *config = [TAMAegisLogConfig new];
    config.debug = [TAMAegisLogStrategy new];
    config.info = [TAMAegisLogStrategy new];
    config.error = [TAMAegisLogStrategy new];
    config.fatal = [TAMAegisLogStrategy new];
    
    config.debug.isWhiteListOnly = YES;
    config.debug.uploadStrategy = TAMAegisUploadStrategy_DELAY;
    
    config.info.isWhiteListOnly = NO;
    config.info.uploadStrategy = TAMAegisUploadStrategy_DELAY;
    
    config.error.isWhiteListOnly = NO;
    config.error.uploadStrategy = TAMAegisUploadStrategy_INMMIDIATELY;
    
    config.fatal.isWhiteListOnly = NO;
    config.fatal.uploadStrategy = TAMAegisUploadStrategy_INMMIDIATELY;
    
    return config;
}

@end
