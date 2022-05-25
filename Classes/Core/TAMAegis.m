//
//  TAMAegis.m
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import "TAMAegis.h"
#import "TAMAegisProtocol.h"
#import "TAMAegisUtil.h"
#import "TAMAegisLogUploadProxy.h"

/**
 配置协议
 */
@interface TAMAegisConfig : TAMCopyableObject <TAMAegisConfigProtocol>
// property
@property(nonatomic, strong) TAMAegisUserConfig *userConfig;

// property
@property(nonatomic, strong) TAMAegisLogConfig *logConfig;

// property
@property(nonatomic, strong) TAMAegisSystemConfig *systemConfig;
@end

/**
 TAMAegisConfig
 */
@implementation TAMAegisConfig
@end


/**
 TAMAegis
 */
@interface TAMAegis ()
// property
@property(nonatomic, strong) id<TAMAegisUploadProtocol> aegisUploader;

// property
@property(nonatomic, strong) id<TAMAegisConfigProtocol> config;
@end


// TAMAegis
@implementation TAMAegis

- (instancetype)initWithConfig:(TAMAegisUserConfig *)config
{
    return [self initWithConfig:config logConfig:nil systemConfig:nil];
}

- (instancetype)initWithConfig:(TAMAegisUserConfig *)config
                     logConfig:(TAMAegisLogConfig *)logConfig
                  systemConfig:(TAMAegisSystemConfig *)systemConfig
{
    if (self = [super init]) {
        if (logConfig == nil) {
            logConfig = [TAMAegisLogConfig defaultTAMAegisLogConfig];
        }
        
        if (systemConfig == nil) {
            systemConfig = [TAMAegisSystemConfig defaultTAMAegisSystemConfig];
        }
        
        if (config.aid.length == 0) {
            config.aid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        
        if (config.version.length == 0) {
            config.version = [TAMAegisUtil deviceInfo];
        }
        
        if (config.appid.length == 0) {
            NSLog(@"appid mustn't be  nil");
            return nil;
        }
        
        TAMAegisConfig *aegisConfig = [TAMAegisConfig new];
        aegisConfig.logConfig = logConfig;
        aegisConfig.systemConfig = systemConfig;
        aegisConfig.userConfig = config;
        self.config = aegisConfig;
        
        self.aegisUploader = [[TAMAegisLogUploadProxy alloc] initWithConfig:aegisConfig];
    }
    
    return self;
}

- (void)updateUin:(NSString *)uin
{
    TAMAegisConfig *aegisConfig = [(NSObject *)self.config copy];
    aegisConfig.userConfig.uin = [uin copy];
    
    self.config = aegisConfig;
}

#pragma mark - API
- (void)debug:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3)
{
    va_list argList;
    va_start(argList, msg);
    NSString *aMessage = [[NSString alloc] initWithFormat:msg arguments:argList];
    va_end(argList);
    
    TAMAegisLogStrategy *strategy = self.config.logConfig.debug;
    
    [self.aegisUploader uploadLog:TAMAegisLogLevel_Debug
                              tag:tag
                              msg:aMessage
                           config:self.config
                   uploadStrategy:strategy.uploadStrategy
                    whiteListOnly:strategy.isWhiteListOnly];
}

- (void)info:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3)
{
    va_list argList;
    va_start(argList, msg);
    NSString *aMessage = [[NSString alloc] initWithFormat:msg arguments:argList];
    va_end(argList);
    
    TAMAegisLogStrategy *strategy = self.config.logConfig.info;
    
    [self.aegisUploader uploadLog:TAMAegisLogLevel_Info
                              tag:tag
                              msg:aMessage
                           config:self.config
                   uploadStrategy:strategy.uploadStrategy
                    whiteListOnly:strategy.isWhiteListOnly];
}

- (void)error:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3)
{
    va_list argList;
    va_start(argList, msg);
    NSString *aMessage = [[NSString alloc] initWithFormat:msg arguments:argList];
    va_end(argList);
    
    TAMAegisLogStrategy *strategy = self.config.logConfig.error;
    
    [self.aegisUploader uploadLog:TAMAegisLogLevel_Error
                              tag:tag
                              msg:aMessage
                           config:self.config
                   uploadStrategy:strategy.uploadStrategy
                    whiteListOnly:strategy.isWhiteListOnly];
}

- (void)fatal:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3)
{
    va_list argList;
    va_start(argList, msg);
    NSString *aMessage = [[NSString alloc] initWithFormat:msg arguments:argList];
    va_end(argList);
    
    TAMAegisLogStrategy *strategy = self.config.logConfig.fatal;
    
    [self.aegisUploader uploadLog:TAMAegisLogLevel_Fatal
                              tag:tag
                              msg:aMessage
                           config:self.config
                   uploadStrategy:strategy.uploadStrategy
                    whiteListOnly:strategy.isWhiteListOnly];
}

- (void)log:(TAMAegisLogLevel)level
        tag:(NSString *)tag
        msg:(NSString *)msg
uploadStrategy:(TAMAegisUploadStrategy)uploadStrategy
whiteListOnly:(BOOL)whiteListOnly
{
    [self.aegisUploader uploadLog:level
                              tag:tag
                              msg:msg
                           config:self.config
                   uploadStrategy:uploadStrategy
                    whiteListOnly:whiteListOnly];
}

@end
