//
//  NSTimer+BTWeak.m
//  HuaYang
//
//  Created by britayin on 2017/5/23.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "NSTimer+BTWeak.h"


/**
 NSTimer (BTWeak)
 */
@implementation NSTimer (BTWeak)

+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)ti
                                target:(id)aTarget
                              selector:(SEL)aSelector
                               repeats:(BOOL)yesOrNo
{
    __weak typeof(aTarget) weakTarget = aTarget;
    return [self timerWithTimeInterval:ti
                                target:weakTarget
                              selector:aSelector
                              userInfo:nil
                               repeats:yesOrNo];
}

+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti
                                         target:(id)aTarget
                                       selector:(SEL)aSelector
                                        repeats:(BOOL)yesOrNo
{
    __weak typeof(aTarget) weakTarget = aTarget;
    return [self scheduledTimerWithTimeInterval:ti
                                         target:weakTarget
                                       selector:aSelector
                                       userInfo:nil
                                        repeats:yesOrNo];
}

+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                          block:(void (^)(void))inBlock
                                        repeats:(BOOL)inRepeats
{
    void (^block)(void) = [inBlock copy];
    NSTimer * timer = [self scheduledTimerWithTimeInterval:inTimeInterval
                                                    target:self
                                                  selector:@selector(tam_executeTimerBlock:)
                                                  userInfo:block
                                                   repeats:inRepeats];
    return timer;
}

+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)inTimeInterval
                                 block:(void (^)(void))inBlock
                               repeats:(BOOL)inRepeats
{
    void (^block)(void) = [inBlock copy];
    NSTimer * timer = [self timerWithTimeInterval:inTimeInterval
                                           target:self
                                         selector:@selector(tam_executeTimerBlock:)
                                         userInfo:block
                                          repeats:inRepeats];
    return timer;
}

+ (void)tam_executeTimerBlock:(NSTimer *)inTimer;
{
    if([inTimer userInfo])
    {
        void (^block)(void) = (void (^)(void))[inTimer userInfo];
        block();
    }
}

@end
