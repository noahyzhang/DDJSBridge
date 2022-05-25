//
//  DRAsyncBlockOperation.m
//  DRAsyncOperations
//
//  Created by David Rodrigues on 23/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import "TAMDRAsyncBlockOperation.h"


/**
 TAMDRAsyncBlockOperation
 */
@interface TAMDRAsyncBlockOperation ()


// property
@property (nonatomic, copy) TAMDRAsyncBlockOperationExecutionBlock executionBlock;

@end


/**
 TAMDRAsyncBlockOperation
 */
@implementation TAMDRAsyncBlockOperation

- (instancetype)initWithBlock:(TAMDRAsyncBlockOperationExecutionBlock)executionBlock
{
    NSParameterAssert(executionBlock);

    // Protection for the cases where asserts are disabled
    if (!executionBlock) {
        return nil;
    }

    if ((self = [super init])) {
        _executionBlock = executionBlock;
    }

    return self;
}

#pragma mark -
#pragma mark DRAsyncOperation methods

- (void)asyncTask
{
    // Invoke execution block
    __weak __typeof(self) weakSelf = self;
    self.executionBlock(^{
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf finish];
    });
}

- (void)finish
{
    // Release the execution block after completion
    self.executionBlock = nil;

    [super finish];
}

#pragma mark -
#pragma mark DRAsyncOperation+DRConvenienceInitializer

+ (instancetype)asyncBlockOperationWithBlock:(TAMDRAsyncBlockOperationExecutionBlock)executionBlock
{
    return [[TAMDRAsyncBlockOperation alloc] initWithBlock:executionBlock];
}

@end
