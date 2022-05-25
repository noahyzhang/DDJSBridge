//
//  TAMAegisLogData.h
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TAMAegis.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TAMAegisConfigProtocol;


/**
 TAMAegisLogData
 */
@interface TAMAegisLogData : NSObject

// msg
@property (nonatomic, copy) NSString *msg; 

// tag
@property (nonatomic, copy) NSString *tag; 

// seq
@property (nonatomic, copy) NSString *seq; 

// level
@property (nonatomic, assign) TAMAegisLogLevel level; 

// uploadStrategy
@property(nonatomic, assign) TAMAegisUploadStrategy uploadStrategy; 

// whiteListOnly
@property(nonatomic, assign) BOOL whiteListOnly; 

// config
@property(nonatomic, strong) id<TAMAegisConfigProtocol> config; 
@end

NS_ASSUME_NONNULL_END

