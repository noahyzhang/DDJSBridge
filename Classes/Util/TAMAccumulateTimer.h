//
//  TAMAccumulateTimerDelegate.h
//  TAMAegis
//
//  Created by carlyhuang on 2020/5/27.
//  Copyright © 2020 Carly 黄. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 TAMAccumulateTimerDelegate
 */
@protocol TAMAccumulateTimerDelegate <NSObject>
/**
 积攒执行回调
 */
- (void)onAccumulateTimer;

@end


/**
 TAMAccumulateTimer
 */
@protocol TAMAccumulateTimer <NSObject>

/**
 设置累积计时器
 
 @param maxTotalNum 最大累积个数（加入超过maxNum个数据-触发回调）
 @param maxTotalTime 最大累积时间 （距离第一个数据超过maxTotalTime-触发回调）
 @param maxIntervalTime 最大间隔时间（2个数据间隔超过maxIntervalTime-触发回调）
 @param delegate 回调delegate
 */
- (void)setMaxTotalNums:(NSUInteger)maxTotalNum
           maxTotalTime:(NSTimeInterval)maxTotalTime
        maxIntervalTime:(NSTimeInterval)maxIntervalTime
               delegate:(id<TAMAccumulateTimerDelegate>)delegate;

/**
 增加计次
 
 @param count 要累积的次数
 */
- (void)add:(NSInteger)count;

/**
 增加计次
 */
- (void)increase;

@end


/**
 TAMAccumulateTimer
 */
@interface TAMAccumulateTimer : NSObject<TAMAccumulateTimer>

@end
