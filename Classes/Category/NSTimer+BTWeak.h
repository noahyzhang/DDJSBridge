//
//  NSTimer+BTWeak.h
//  HuaYang
//
//  Created by britayin on 2017/5/23.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (BTWeak)

+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector repeats:(BOOL)yesOrNo;
+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector repeats:(BOOL)yesOrNo;
+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;
+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;

@end
