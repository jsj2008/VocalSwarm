//
//  UIView+FindSubview.m
//  VocalSwarm
//
//  Created by Алексей on 27.01.14.
//  Copyright (c) 2014 injoit. All rights reserved.
//

#import "UIView+FindSubview.h"

@implementation UIView (FindSubview)

- (UIView *) findSubviewOfClass:(Class)subviewClass {
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:subviewClass]) {
            return subview;
        }
        UIView *res = [subview findSubviewOfClass:subviewClass];
        if (res) {
            return res;
        }
    }
    return nil;
}

@end
