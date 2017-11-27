//
//  IDMUtils.h
//  PhotoBrowserDemo
//
//  Created by Oliver ONeill on 2/12/17.
//

#import <Foundation/Foundation.h>

@interface IDMUtils : NSObject
+ (CGRect)adjustRect:(CGRect)rect forSafeAreaInsets:(UIEdgeInsets)insets forBounds:(CGRect)bounds adjustForStatusBar:(BOOL)adjust statusBarHeight:(int)statusBarHeight;
@end
