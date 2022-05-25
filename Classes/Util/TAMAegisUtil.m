//
//  TAMAegisUtil.m
//  TAMAegis
//
//  Created by Qinmin on 2021/4/1.
//  Copyright © 2021年 tencent. All rights reserved.
//

#import "TAMAegisUtil.h"
#import <sys/sysctl.h>
#import <sys/types.h>

/**
 TAMAegisUtil
 */
@implementation TAMAegisUtil

+ (NSString *)getPreferredLanguage
{
    static NSString *preferredLang;
    if (!preferredLang) {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        NSArray *languages = [defs objectForKey:@"AppleLanguages"];
        preferredLang = [languages objectAtIndex:0];
    }
    return preferredLang;
}

+ (BOOL)languageIsChinese
{
    static dispatch_once_t onceToken;
    static BOOL isChinese;
    dispatch_once(&onceToken, ^{
        // zh前缀表示是中文,iOS9.3,目前是:台湾zh-TW,香港zh-HK,简体中文zh-Hans.
        isChinese = [[self getPreferredLanguage] hasPrefix:@"zh-Hans"];
    });
    return isChinese;
}

+ (NSString *)appVer
{
    static dispatch_once_t onceToken;
    static NSString *strAppVer;
    dispatch_once(&onceToken, ^{
        NSDictionary *dicInfo = [[NSBundle mainBundle] infoDictionary];
        strAppVer = [dicInfo objectForKey:@"CFBundleShortVersionString"];
    });

    return strAppVer;
}

+ (NSString *)appBuild
{
    static dispatch_once_t onceToken;
    static NSString *strAppBuild;
    dispatch_once(&onceToken, ^{
        NSDictionary *dicInfo = [[NSBundle mainBundle] infoDictionary];
        strAppBuild = [dicInfo objectForKey:@"CFBundleVersion"];
    });

    return strAppBuild;
}

+ (BOOL)isJailBroken
{
    static BOOL isJailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cydiaPath = @"/Applications/Cydia.app";
        NSString *aptPath = @"/private/var/lib/apt/";
        if ([[NSFileManager defaultManager] fileExistsAtPath:cydiaPath]) {
            isJailBroken = YES;
        }

        if ([[NSFileManager defaultManager] fileExistsAtPath:aptPath]) {
            isJailBroken = YES;
        }
    });

    NSURL *url = [NSURL URLWithString:@"cydia://package/com.example.package"];
    BOOL cydiaJailBroken = [[UIApplication sharedApplication] canOpenURL:url];

    return isJailBroken || cydiaJailBroken;
}

+ (NSString *)deviceInfo
{
    NSString *sysVer = [[UIDevice currentDevice] systemVersion];

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);

    platform = [platform stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

    NSString *languageStr = ([self languageIsChinese] ? @"CN" : @"EN");
    BOOL isJailBroken = [self isJailBroken];
    

    NSString *jailBrokenMark = isJailBroken ? @"JB" : @"";

    NSString *result = [NSString stringWithFormat:@"IOS_Apple_%@_%@_%@.%@_%@_%@", platform, sysVer, [self appVer],
                                                  [self appBuild], jailBrokenMark, languageStr];

    return result;
}


+ (NSString *)urlEncode:(NSString *)str
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (__bridge CFStringRef)str,
                                                                                             NULL,
                                                                                             CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                             kCFStringEncodingUTF8));
    
    return result;
}

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return dateFormatter;
}

+ (uint64_t)getSystemMillis
{
    struct timeval v;
    gettimeofday(&v, NULL);

    double ms = v.tv_sec; // long定义的话在iphone5上会溢出
    UInt64 millis = ms * 1000 + (v.tv_usec / 1000);

    return millis;
}


+ (NSString *)getSeq
{
    return [NSString stringWithFormat:@"%@", @([self getTid])];
}

+ (uint64_t)getTid
{
    uint64_t msec = [self getSystemMillis];
    int32_t maxRandNumber = 4194304; //最大22位正整数
    uint64_t rand = [self getRandomNumber:0 to:maxRandNumber];

    uint64_t t = msec << 22;
    uint64_t result = t | rand;

    return result;
}

+ (int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

+ (NSString *)urlEncodeLog:(NSString *)msg tag:(NSString *)tag
{
    NSString *date = [[self dateFormatter] stringFromDate:[NSDate date]];
    NSString *log = [NSString stringWithFormat:@"%@ [%@] %@", date, tag, msg];
    
    return [self urlEncode:log];
}

@end
