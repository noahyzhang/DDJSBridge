//
//  TAMCopyableObject.m
//  TAMAegis
//
//  Created by Qinmin on 2021/4/14.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import "TAMCopyableObject.h"
#import <objc/runtime.h>


/**
 TAMCopyableObject
 */
@implementation TAMCopyableObject

+ (NSDictionary<NSString *, NSNumber *> *)objectPropertiesDict
{
    static dispatch_once_t onceToken;
    static NSDictionary *propertyDict = nil;
    dispatch_once(&onceToken, ^{
        uint32_t count = 0;
        objc_property_t* properties = class_copyPropertyList([NSObject class], &count);
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (int i = 0; i < count; i++)
        {
            const char *cpropertyName = property_getName(properties[i]);
            NSString *propertyName = [NSString stringWithCString:cpropertyName encoding:NSUTF8StringEncoding];
            dict[propertyName] = @(YES);
        }
        
        propertyDict = dict.copy;
    });
    
    return propertyDict;
}

- (id)copyWithZone:(NSZone *)zone
{
    id objCopy = [[[self class] allocWithZone:zone] init];
    Class clazz = [self class];
    uint32_t count = 0;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];

    for (int i = 0; i < count; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
    }

    if (properties != NULL) {
        free(properties);
        properties = NULL;
    }
    
    for (int i = 0; i < count; i++)
    {
        NSString *name = [propertyArray objectAtIndex:i];
        
        // 过滤掉NSObject的相关属性
        NSDictionary<NSString *, NSNumber *> *propertiesDict = [self.class objectPropertiesDict];
        if ([propertiesDict[name] boolValue]) {
            continue;
        }
        
        id value = [self valueForKey:name];
        if([value respondsToSelector:@selector(copyWithZone:)]) {
            [objCopy setValue:[value copy] forKey:name];
        }
        else
        {
            [objCopy setValue:value forKey:name];
        }
    }
    
    return objCopy;
}

@end
