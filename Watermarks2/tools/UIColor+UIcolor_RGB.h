//
//  UIColor+UIcolor_RGB.h
//  GuoJin001
//
//  Created by 国金 on 17/4/19.
//  Copyright © 2017年 seasar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@interface UIColor (UIcolor_RGB)
+ (UIColor*)colorWithHexString:(NSString*)stringToConvert;
+ (UIColor*)colorWithRGBRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
@end
