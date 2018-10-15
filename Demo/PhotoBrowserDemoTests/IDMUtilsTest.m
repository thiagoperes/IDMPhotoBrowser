//
//  IDMUtilsTest.m
//  PhotoBrowserDemoTests
//
//  Created by Oliver ONeill on 2/12/17.
//

#import <XCTest/XCTest.h>
#import "IDMUtils.h"

@interface IDMUtilsTest : XCTestCase

@end

@implementation IDMUtilsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAdjustRectForSafeAreaInsets {
    // given
    CGRect rect = CGRectMake(0, 0, 100, 200);
    CGRect bounds = rect;
    UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
    BOOL adjust = YES;
    int statusBarHeight = 0;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    // since its moved 10 down and 10 to the left, the width and height are then
    // decreased by 20
    CGRect expected = CGRectMake(10, 10, 80, 180);
    XCTAssert(CGRectEqualToRect(result, expected));
}

- (void)testAdjustRectForSafeAreaInsetsDoesntModifyGivenZeroInsets {
    // given
    CGRect rect = CGRectMake(0, 0, 100, 200);
    CGRect bounds = rect;
    // no inset changes
    UIEdgeInsets insets = UIEdgeInsetsZero;
    BOOL adjust = YES;
    int statusBarHeight = 0;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    // since there were no insets, the result should not change the rect
    XCTAssert(CGRectEqualToRect(result, rect));
}

- (void)testAdjustRectForSafeAreaInsetsWithSmallBounds {
    // given
    CGRect rect = CGRectMake(0, 0, 100, 200);
    // small bounds should not affect the view
    CGRect bounds = CGRectMake(10, 10, 10, 20);
    UIEdgeInsets insets = UIEdgeInsetsZero;
    BOOL adjust = YES;
    int statusBarHeight = 0;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    XCTAssert(CGRectEqualToRect(result, rect));
}

- (void)testAdjustRectForSafeAreaInsetsWithoutStatusBarAdjustment {
    // given
    CGRect rect = CGRectMake(0, 0, 100, 200);
    CGRect bounds = CGRectMake(0, 0, 100, 200);
    UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
    BOOL adjust = NO;
    int statusBarHeight = 0;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    // since its moved 10 down and 10 to the left, the width and height are then
    // decreased by 20
    CGRect expected = CGRectMake(10, 0, 80, 190);
    XCTAssert(CGRectEqualToRect(result, expected));
}

- (void)testAdjustRectForSafeAreaInsetsShiftsViewsUpInsteadOfResize {
    // given
    CGRect rect = CGRectMake(0, 20, 100, 200);
    CGRect bounds = CGRectMake(0, 0, 100, 200);
    UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
    BOOL adjust = NO;
    int statusBarHeight = 0;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    // the view was moved up by 10 on the y axis to move above the inset
    CGRect expected = CGRectMake(10, 10, 80, 200);
    XCTAssert(CGRectEqualToRect(result, expected));
}

- (void)testAdjustRectForSafeAreaInsetsUsesStatusBarHeight {
    // given
    CGRect rect = CGRectMake(0, 0, 100, 200);
    CGRect bounds = CGRectMake(0, 0, 100, 200);
    UIEdgeInsets insets = UIEdgeInsetsZero;
    BOOL adjust = YES;
    int statusBarHeight = 10;
    // when
    CGRect result = [IDMUtils adjustRect:rect forSafeAreaInsets:insets forBounds:bounds adjustForStatusBar:adjust statusBarHeight:statusBarHeight];
    // then
    // the view is moved down by 10 and the height is decreased
    CGRect expected = CGRectMake(0, 10, 100, 190);
    XCTAssert(CGRectEqualToRect(result, expected));
}
@end
