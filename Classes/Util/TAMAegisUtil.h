//
//  TAMAegisUtil.h
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 TAMAegisUtil
 */
@interface TAMAegisUtil : NSObject

+ (BOOL)languageIsChinese;

+ (uint64_t)getSystemMillis;

+ (NSString *)deviceInfo;

+ (NSString *)urlEncode:(NSString *)str;

+ (NSString *)urlEncodeLog:(NSString *)msg tag:(NSString *)tag;

+ (NSString *)getSeq;

@end

NS_ASSUME_NONNULL_END
