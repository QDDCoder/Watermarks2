//
//  UIImage+Extension.m
//  PushLogo2
//
//  Created by people on 2018/10/13.
//  Copyright © 2018 people. All rights reserved.
//

#import "UIImage+Extension.h"
#import <objc/runtime.h>
static NSString *nameWithSetterGetterKey = @"0";
@implementation UIImage (Extension)
//运行时实现setter方法
- (void)setNameWithSetterGetter:(NSString *)nameWithSetterGetter {
    objc_setAssociatedObject(self, &nameWithSetterGetterKey, nameWithSetterGetter, OBJC_ASSOCIATION_COPY);
}
//运行时实现getter方法
- (NSString *)nameWithSetterGetter {
    return objc_getAssociatedObject(self, &nameWithSetterGetterKey);
}
@end
