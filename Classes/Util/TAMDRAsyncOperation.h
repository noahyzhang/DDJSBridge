//
//  DRAsyncOperation.h
//  DRAsyncOperations
//
//  Created by David Rodrigues on 17/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The \c DRAsyncOperation is an abstract class to encapsulate and manage execution of an asynchronous task in a very
 similar way as a common \c NSOperation. Because it is abstract, this class should not be used directly but instead
 subclass to implement the asynchronous task.

 To subclass and implement an async task please refer to \c DRAsyncOperationSubclass.
 */
@interface TAMDRAsyncOperation : NSOperation

/// 异步操作名字
@property (nonatomic, copy, nullable) NSString *operationName;

@end


/**
 Extensions to be used by subclasses of \c DRAsyncOperation to encapsulate the code of an async task.

 The code that uses \c DRAsyncOperation must never call these methods.
 */
@interface TAMDRAsyncOperation (TAMDRAsyncOperationProtected)

/**
 Performs the receiver's asynchronous task.

 \b Discussion \n

 You must override this method to perform the desired asynchronous task but do not invoke \c super at any time. \n

 When the asynchronous task has completed, you must call \c -finish to mark his completion and terminate the operation.
 */
- (void)asyncTask;

/**
 Marks the completion of receiver's asynchronous task.
 */
- (void)finish NS_REQUIRES_SUPER;

@end


NS_ASSUME_NONNULL_END
