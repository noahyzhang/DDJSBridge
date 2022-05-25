//
//  TAMAegisLogUploadProxy.h
//  TAMAegis
//
//  Created by carlyhuang on 2020/5/26.
//  Copyright © 2020 falco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TAMAegisProtocol.h"
#import "TAMAegis.h"


/**
 TAMAegisLogUploadProxy
 */
@interface TAMAegisLogUploadProxy : NSObject<TAMAegisUploadProtocol>
- (instancetype)initWithConfig:(id<TAMAegisConfigProtocol>)config;
@end
