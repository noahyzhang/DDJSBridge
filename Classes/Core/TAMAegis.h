//
//  TAMAegis.h
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TAMAegisConfig.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger
{
    TAMAegisLogLevel_Debug = 1,
    TAMAegisLogLevel_Info =  2,
    TAMAegisLogLevel_Error = 4,
    TAMAegisLogLevel_Fatal = 8,
} TAMAegisLogLevel;


// TAMAegis
@interface TAMAegis : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(TAMAegisUserConfig *)config;

- (instancetype)initWithConfig:(TAMAegisUserConfig *)config
                     logConfig:(nullable TAMAegisLogConfig *)logConfig
                  systemConfig:(nullable TAMAegisSystemConfig *)systemConfig;

/// 配置更新（比如登录之后设置用户uin时用）
/// @param uin 更新用户uin
- (void)updateUin:(NSString *)uin;


/// 打印日志（默认只针对白名单用户，非实时上传到后台）
/// @param tag 标签
/// @param msg 日志内容
- (void)debug:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3);

/// 打印日志（默认针对所有用户，非实时上传到后台）
/// @param tag 标签
/// @param msg 日志内容
- (void)info:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3);

/// 打印日志（默认针对所有用户，实时上传到后台）
/// @param tag 标签
/// @param msg 日志内容
- (void)error:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3);

/// 打印日志（默认针对所有用户，实时上传到后台）
/// @param tag 标签
/// @param msg 日志内容
- (void)fatal:(NSString *)tag msg:(NSString *)msg, ... NS_FORMAT_FUNCTION(2, 3);


/// 打印日志
/// @param level 日志级别
/// @param tag 日志标签
/// @param msg 日志内容
/// @param uploadStrategy 上传策略
/// @param whiteListOnly 是否只针对白名单
- (void)log:(TAMAegisLogLevel)level
        tag:(NSString *)tag
        msg:(NSString *)msg
uploadStrategy:(TAMAegisUploadStrategy)uploadStrategy
whiteListOnly:(BOOL)whiteListOnly;

@end

NS_ASSUME_NONNULL_END
