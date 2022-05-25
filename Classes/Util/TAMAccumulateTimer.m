//
//  TAMAccumulateTimer.m
//  TAMAegis
//
//  Created by carlyhuang on 2020/5/27.
//  Copyright © 2020 Carly 黄. All rights reserved.
//

#import "TAMAccumulateTimer.h"
#import "NSTimer+BTWeak.h"


/**
 TAMAccumulateTimer
 */
@interface TAMAccumulateTimer()

// maxTotalNum
@property (nonatomic, assign) NSUInteger     maxTotalNum;

// maxTotalTime
@property (nonatomic, assign) NSTimeInterval maxTotalTime;

// maxIntervalTime
@property (nonatomic, assign) NSTimeInterval maxIntervalTime;

// intervalTimer
@property (nonatomic, strong) NSTimer * intervalTimer;

// totalTimer
@property (nonatomic, strong) NSTimer * totalTimer;

// accumulateArray
@property (nonatomic, strong) NSMutableArray * accumulateArray;

// delegate
@property (nonatomic, weak) id<TAMAccumulateTimerDelegate> delegate;

// count
@property(nonatomic, assign) uint64_t count;
@end


/**
 TAMAccumulateTimer
 */
@implementation TAMAccumulateTimer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accumulateArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self releaseTimer];
}

- (void)releaseTimer
{
    if (self.intervalTimer) {
        [self.intervalTimer invalidate];
        self.intervalTimer = nil;
    }
    if (self.totalTimer) {
        [self.totalTimer invalidate];
        self.totalTimer = nil;
    }
}

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
               delegate:(id<TAMAccumulateTimerDelegate>)delegate
{
    self.maxTotalNum = maxTotalNum;
    self.maxTotalTime = maxTotalTime;
    self.maxIntervalTime = maxIntervalTime;
    self.delegate = delegate;
}

- (void)add:(NSInteger)count
{
    if (![NSThread isMainThread]) {
        // NSLog(@"FalcoAccumulateTimer|在子线程新加入对象");
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf internalAdd:count];
        });
    } else {
        [self internalAdd:count];
    }
}

- (void)increase
{
    [self add:1];
}

- (void)internalAdd:(NSInteger)count
{
    self.count = self.count + count;
    
    if (self.count > self.maxTotalNum) {
        [self callBack];
        self.count = 0;
        return;
    }
    
    if (self.intervalTimer) {
        [self.intervalTimer invalidate];
        self.intervalTimer = nil;
    }
    self.intervalTimer = [NSTimer scheduledWeakTimerWithTimeInterval:self.maxIntervalTime target:self selector:@selector(onTimer:) repeats:NO];
    
    if (!self.totalTimer) {
        self.totalTimer = [NSTimer scheduledWeakTimerWithTimeInterval:self.maxTotalTime target:self selector:@selector(onTimer:) repeats:YES];
    }
}

/**
 添加数据
 
 @param object 要累积的对象
 @param force 是否强制刷新当次累积
 */
- (void)accumulate:(id)object force:(BOOL)force
{
    if (![NSThread isMainThread]) {
        NSLog(@"FalcoAccumulateTimer|在子线程新加入对象%@", object);
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf internalAccumulate:object force:force];
        });
    } else {
        [self internalAccumulate:object force:force];
    }
}

- (void)internalAccumulate:(id)object force:(BOOL)force
{
    if (object) {
        [self.accumulateArray addObject:object];
        
        if (force) {
            [self callBack];
            return;
        }
        
        if (self.accumulateArray.count > self.maxTotalNum) {
            [self callBack];
            return;
        }
        
        if (self.intervalTimer) {
            [self.intervalTimer invalidate];
            self.intervalTimer = nil;
        }
        self.intervalTimer = [NSTimer scheduledWeakTimerWithTimeInterval:self.maxIntervalTime target:self selector:@selector(onTimer:) repeats:NO];
        
        if (!self.totalTimer) {
            self.totalTimer = [NSTimer scheduledWeakTimerWithTimeInterval:self.maxTotalTime target:self selector:@selector(onTimer:) repeats:YES];
        }
    }
}

- (void)onTimer:(NSTimer *)timer
{
    [self releaseTimer];
    [self callBack];
}

- (void)callBack
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onAccumulateTimer)]) {
        [self.delegate onAccumulateTimer];
    }
    
    [self.accumulateArray removeAllObjects];
    self.count = 0;
}

@end
