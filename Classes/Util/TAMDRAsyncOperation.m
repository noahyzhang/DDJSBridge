//
//  DRAsyncOperation.m
//  DRAsyncOperations
//
//  Created by David Rodrigues on 17/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import "TAMDRAsyncOperation.h"

typedef NS_ENUM(char, TAMDRAsyncOperationState) {
    TAMDRAsyncOperationStateReady,
    TAMDRAsyncOperationStateExecuting,
    TAMDRAsyncOperationStateFinished
};

static inline NSString *tamDRKeyPathFromAsyncOperationState(TAMDRAsyncOperationState state)
{
    switch (state) {
        case TAMDRAsyncOperationStateReady:
            return @"isReady";
        case TAMDRAsyncOperationStateExecuting:
            return @"isExecuting";
        case TAMDRAsyncOperationStateFinished:
            return @"isFinished";
    }
}


/**
 TAMDRAsyncBlockOperation
 */
@interface TAMDRAsyncOperation ()

// property
@property (nonatomic, assign) TAMDRAsyncOperationState state;

// property
@property (nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;

@end


/**
 TAMDRAsyncBlockOperation
 */
@implementation TAMDRAsyncOperation

#pragma mark -
#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *identifier =
            [NSString stringWithFormat:@"com.dmcrodrigues.%@(%p)", NSStringFromClass(self.class), self];

        _dispatchQueue = dispatch_queue_create([identifier UTF8String], DISPATCH_QUEUE_SERIAL);

        dispatch_queue_set_specific(_dispatchQueue, (__bridge const void *)(_dispatchQueue), (__bridge void *)(self),
                                    NULL);
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation methods

#if defined(__IPHONE_OS_VERSION_MIN_ALLOWED) && __IPHONE_OS_VERSION_MIN_ALLOWED >= __IPHONE_7_0
- (BOOL)isAsynchronous
{
    return YES;
}
#endif

#if defined(__IPHONE_OS_VERSION_MIN_ALLOWED) && __IPHONE_OS_VERSION_MIN_ALLOWED < __IPHONE_7_0
- (BOOL)isConcurrent
{
    return YES;
}
#endif

- (BOOL)isExecuting
{
    __block BOOL isExecuting;

    [self performBlockAndWait:^{
        isExecuting = self.state == TAMDRAsyncOperationStateExecuting;
    }];

    return isExecuting;
}

- (BOOL)isFinished
{
    __block BOOL isFinished;

    [self performBlockAndWait:^{
        isFinished = self.state == TAMDRAsyncOperationStateFinished;
    }];

    return isFinished;
}

- (void)start
{
    @autoreleasepool {
        if ([self isCancelled]) {
            [self finish];
            return;
        }

        __block BOOL isExecuting = YES;

        [self performBlockAndWait:^{
            // Ignore this call if the operation is already executing or if has finished already
            if (self.state != TAMDRAsyncOperationStateReady) {
                isExecuting = NO;
            } else {
                // Signal the beginning of operation
                self.state = TAMDRAsyncOperationStateExecuting;
            }
        }];

        if (isExecuting) {
            // Execute async task
            [self asyncTask];
        }
    }
}

#pragma mark -
#pragma mark DRAsyncOperation methods

- (void)setState:(TAMDRAsyncOperationState)state
{
    __weak __typeof(self)weakSelf = self;
    [self performBlockAndWait:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSString *oldStateKey = tamDRKeyPathFromAsyncOperationState(strongSelf->_state);
        NSString *newStateKey = tamDRKeyPathFromAsyncOperationState(state);

        [self willChangeValueForKey:oldStateKey];
        [self willChangeValueForKey:newStateKey];

        strongSelf->_state = state;

        [self didChangeValueForKey:newStateKey];
        [self didChangeValueForKey:oldStateKey];
    }];
}

#pragma mark Protected methods

- (void)asyncTask
{
    [self finish];
}

- (void)finish
{
    [self performBlockAndWait:^{
        // Signal the completion of operation
        if (self.state != TAMDRAsyncOperationStateFinished) {
            self.state = TAMDRAsyncOperationStateFinished;
        }
    }];
}

#pragma mark - Dispatch Queue

- (void)performBlockAndWait:(dispatch_block_t)block
{
    void *context = dispatch_get_specific((__bridge const void *)(self.dispatchQueue));
    BOOL runningInDispatchQueue = context == (__bridge void *)(self);

    if (runningInDispatchQueue) {
        block();
    } else {
        dispatch_sync(self.dispatchQueue, block);
    }
}

@end
