//
//  TAMAegispProtocol.h
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TAMAegisLogData.h"

NS_ASSUME_NONNULL_BEGIN

/**
 配置
 */
@protocol TAMAegisConfigProtocol <NSObject, NSCopying>
//userConfig
@property (nonatomic, strong, readonly) TAMAegisUserConfig *userConfig; 

//logConfig
@property (nonatomic, strong, readonly) TAMAegisLogConfig *logConfig; 

//systemConfig
@property (nonatomic, strong, readonly) TAMAegisSystemConfig *systemConfig;
@end


/**
 TAMAegisUploadProtocol
 */
@protocol TAMAegisUploadProtocol <NSObject>

/// 上传日志
/// @param level 日志级别
/// @param tag 日志标签
/// @param msg 日志内容
/// @param uploadStrategy 上传策略
/// @param whiteListOnly 是否只针对白名单
- (void)uploadLog:(TAMAegisLogLevel)level
              tag:(NSString *)tag
              msg:(NSString *)msg
           config:(id<TAMAegisConfigProtocol>)config
   uploadStrategy:(TAMAegisUploadStrategy)uploadStrategy
    whiteListOnly:(BOOL)whiteListOnly;

@end


/**
 TAMAegisUploadProtocol
 */
@protocol TAMAegisDiskCacheProtocol <NSObject>

- (void)cacheLog:(TAMAegisLogLevel)level
             tag:(NSString *)tag
             msg:(NSString *)msg
          config:(id<TAMAegisConfigProtocol>)config
  uploadStrategy:(TAMAegisUploadStrategy)uploadStrategy
   whiteListOnly:(BOOL)whiteListOnly;

@end

NS_ASSUME_NONNULL_END
