//
//  TAMAegisConfig.h
//  FalcoAegisLog
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TAMCopyableObject.h"

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger
{
    TAMAegisUploadStrategy_NOT, // 不上传
    TAMAegisUploadStrategy_INMMIDIATELY,    // 立即上传
    TAMAegisUploadStrategy_DELAY,   // 合并缓存上传
} TAMAegisUploadStrategy;


/**
 TAMAegisUserConfig
 */
@interface TAMAegisUserConfig : TAMCopyableObject
// property
@property (nonatomic, copy) NSString *appid; /// 项目ID

// property
@property (nonatomic, copy) NSString *version; /// 用户自定义版本

// property
@property (nonatomic, copy) NSString *uin; /// 当前用户uin

// property
@property (nonatomic, copy) NSString *aid; /// 当前设备guid
@end

/**
 TAMAegisSystemConfig
 */
@interface TAMAegisSystemConfig : TAMCopyableObject

// property
@property(nonatomic, assign) uint32_t uploadMaxConcurrentOptCount; /// 上传队列并发数

// property
@property (nonatomic, assign) uint32_t uploadRetryCount; /// 上传重试次数(默认1次)

// property
@property (nonatomic, assign) uint32_t uploadTimeout; /// 上传超时时间(默认30s)
+ (instancetype)defaultTAMAegisSystemConfig;
@end

/**
 TAMAegisLogStrategy
 */
@interface TAMAegisLogStrategy : TAMCopyableObject
//uploadStrategy
@property (nonatomic, assign) TAMAegisUploadStrategy uploadStrategy; //uploadStrategy

//isWhiteListOnly
@property (nonatomic, assign) BOOL isWhiteListOnly; //isWhiteListOnly
@end

/**
 TAMAegisLogConfig
 */
@interface TAMAegisLogConfig : TAMCopyableObject

// property
@property (nonatomic, strong) TAMAegisLogStrategy *debug; //debug

// property
@property (nonatomic, strong) TAMAegisLogStrategy *info; //info

// property
@property (nonatomic, strong) TAMAegisLogStrategy *error; //error

// property
@property (nonatomic, strong) TAMAegisLogStrategy *fatal; //fatal
+ (instancetype)defaultTAMAegisLogConfig;
@end

NS_ASSUME_NONNULL_END
