//
//  IDMUtils.m
//  PhotoBrowserDemo
//
//  Created by Oliver ONeill on 2/12/17.
//

#import "IDMUtils.h"

@implementation IDMUtils
/**
 * Adjust a rect to be moved into a safe area specified by `insets`.
 *
 * NOTE: this does not cover all cases. Given a rect it will reposition it if it
 * falls into an unsafe area according to `insets` and `bounds`. When
 * `adjustForStatusBar` is true, the rect y position will be based from the edge
 * of the safe area, otherwise it will be based from zero. This allows views to
 * sit behind the status bar. Status bar height is also used
 * to keep positioning consistent when toggling the status bar on and off
 */
+ (CGRect)adjustRect:(CGRect)rect forSafeAreaInsets:(UIEdgeInsets)insets forBounds:(CGRect)bounds adjustForStatusBar:(BOOL)adjust statusBarHeight:(int)statusBarHeight {
    BOOL isLeft = rect.origin.x <= insets.left;
    // If the safe area is not specified via insets we should fall back to the
    // status bar height
    CGFloat insetTop = insets.top > 0 ? insets.top : statusBarHeight;
    // Don't adjust for y positioning when adjustForStatusBar is false
    BOOL isAtTop = (rect.origin.y <= insetTop);
    BOOL isRight = rect.origin.x + rect.size.width >= bounds.size.width - insets.right;
    BOOL isAtBottom = rect.origin.y + rect.size.height >= bounds.size.height - insets.bottom;
    if ((isLeft) && (isRight)) {
        rect.origin.x += insets.left;
        rect.size.width -= insets.right + insets.left;
    } else if (isLeft) {
        rect.origin.x += insets.left;
    } else if (isRight) {
        rect.origin.x -= insets.right;
    }
    // if we're adjusting for status bar then we should move the view out of
    // the inset
    if ((adjust) && (isAtTop) && (isAtBottom)) {
        rect.origin.y += insetTop;
        rect.size.height -= insets.bottom + insetTop;
    } else if ((adjust) && (isAtTop)) {
        rect.origin.y += insetTop;
    } else if ((isAtTop) && (isAtBottom)) {
        rect.size.height -= insets.bottom;
    } else if (isAtBottom) {
        rect.origin.y -= insets.bottom;
    }
    return rect;
}
@end
