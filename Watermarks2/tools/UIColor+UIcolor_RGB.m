//
//  UIColor+UIcolor_RGB.m
//  GuoJin001
//
//  Created by 国金 on 17/4/19.
//  Copyright © 2017年 seasar. All rights reserved.
//

#import "UIColor+UIcolor_RGB.h"
@implementation UIColor (UIcolor_RGB)
+ (UIColor*)colorWithHexString:(NSString*)stringToConvert{
    if([stringToConvert hasPrefix:@"#"])
    {
        stringToConvert = [stringToConvert substringFromIndex:1];
    }
    NSScanner*scanner = [NSScanner scannerWithString:stringToConvert];
    unsigned hexNum;
    if(![scanner scanHexInt:&hexNum])
    {
        return nil;
    }
    return[UIColor colorWithRGBHex:hexNum];
}
+(UIColor *)colorWithRGBRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

+ (UIColor*)colorWithRGBHex:(UInt32)hex{
    int r = (hex >>16) &0xFF;
    int g = (hex >>8) &0xFF;
    int b = (hex) &0xFF;
    return[UIColor colorWithRed:r /255.0f
                         green:g /255.0f
                          blue:b /255.0f
                         alpha:1.0f];
}
@end
