//
//  IDMPhotoBrowser.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "IDMPhotoBrowser.h"
#import "IDMZoomingScrollView.h"
#define DEFAULT_GREEN_COLOR [UIColor colorWithRed:66.0f/255.0f green:167.0f/255.0f blue:126.0f/255.0f alpha:1.000000]
#define TEXT_COLOR [UIColor colorWithRed:51.000000/255.0f green:51.000000/255.0f blue:51.000000/255.0f alpha:1.000000]


#import "pop/POP.h"

#ifndef IDMPhotoBrowserLocalizedStrings
#define IDMPhotoBrowserLocalizedStrings(key) \
NSLocalizedStringFromTableInBundle((key), nil, [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"IDMPBLocalizations" ofType:@"bundle"]], nil)
#endif

// Private
@interface IDMPhotoBrowser () {
    // Data
    NSMutableArray *_photos;
    UIImage* bgImage;
    // Views
    UIView *fadeView;
    UIImageView*headerImageView;
    UIView*premiumColorView;
    CAGradientLayer* gradientLayer;
    UIScrollView *_pagingScrollView;
    UIPopoverPresentationController *alertPopoverPresentationController;
    UIView*headerView;

    // Gesture
    UIPanGestureRecognizer *_panGesture;

    // Paging
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _pageIndexBeforeRotation;
    NSUInteger _currentPageIndex;
    NSUInteger _offsetPageIndex;

    // Buttons
    UIButton *_doneButton;
    UIButton *_actionRightButton;

    // Toolbar
    UIToolbar *_toolbar;
    UIBarButtonItem *_previousButton, *_nextButton, *_actionButton;
    UIBarButtonItem *_counterButton;
    UILabel *_counterLabel;

    // Actions
    UIActionSheet *_actionsSheet;
    UIActivityViewController *activityViewController;

    // Control
    NSTimer *_controlVisibilityTimer;

    // Appearance
    //UIStatusBarStyle _previousStatusBarStyle;
    BOOL _statusBarOriginallyHidden;

    // Present
    UIView *_senderViewForAnimation;

    // Misc
    BOOL _areControlsHidden;
    BOOL _performingLayout;
    BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _autoHide;
    NSInteger _initalPageIndex;

    BOOL _isdraggingPhoto;

    CGRect _senderViewOriginalFrame;
    //UIImage *_backgroundScreenshot;

    UIWindow *_applicationWindow;

    // iOS 7
    UIViewController *_applicationTopViewController;
    int _previousModalPresentationStyle;
}

// Private Properties
@property (nonatomic, strong) UIActionSheet *actionsSheet;
@property (nonatomic, strong) UIActivityViewController *activityViewController;

// Private Methods

// Layout
//- (void)performLayoutFromDeletion;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (IDMZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (IDMZoomingScrollView *)pageDisplayingPhoto:(id<IDMPhoto>)photo;
- (IDMZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(IDMZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForCaptionView:(IDMCaptionView *)captionView atIndex:(NSUInteger)index;

// Toolbar
- (void)updateToolbar;

// Navigation
- (void)jumpToPageAtIndex:(NSUInteger)index;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (id<IDMPhoto>)photoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<IDMPhoto>)photo;
- (void)loadAdjacentPhotosIfNecessary:(id<IDMPhoto>)photo;
- (void)releaseAllUnderlyingPhotos;

@end

// IDMPhotoBrowser
@implementation IDMPhotoBrowser

// Properties
@synthesize displayDoneButton = _displayDoneButton, displayActionRightButton = _displayActionRightButton, displayToolbar = _displayToolbar, displayActionButton = _displayActionButton, displayCounterLabel = _displayCounterLabel, useWhiteBackgroundColor = _useWhiteBackgroundColor, doneButtonImage = _doneButtonImage, headerImage = _headerImage, actionRightButtonImage = _actionRightButtonImage, statusBarHeight = _statusBarHeight, headerHeight = _headerHeight, premiumColorEnabled = _premiumColorEnabled;
@synthesize leftArrowImage = _leftArrowImage, rightArrowImage = _rightArrowImage, leftArrowSelectedImage = _leftArrowSelectedImage, rightArrowSelectedImage = _rightArrowSelectedImage;
@synthesize displayArrowButton = _displayArrowButton, actionButtonTitles = _actionButtonTitles;
@synthesize arrowButtonsChangePhotosAnimated = _arrowButtonsChangePhotosAnimated;
@synthesize forceHideStatusBar = _forceHideStatusBar;
@synthesize usePopAnimation = _usePopAnimation;
@synthesize disableVerticalSwipe = _disableVerticalSwipe;
@synthesize actionButtonIsAbuseAction = _actionButtonIsAbuseAction;
@synthesize actionsSheet = _actionsSheet, activityViewController = _activityViewController;
@synthesize trackTintColor = _trackTintColor, progressTintColor = _progressTintColor;
@synthesize delegate = _delegate;
@synthesize photoImageViews = _photoImageViews;
@synthesize reportAbuseString;
@synthesize blockUserString;
#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        // Defaults
        self.hidesBottomBarWhenPushed = YES;
        reportAbuseString = NSLocalizedString(@"Report abuse", @"");
        blockUserString = NSLocalizedString(@"Block user", @"");
        _currentPageIndex = 0;
        _performingLayout = NO; // Reset on view did appear
        _rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [NSMutableSet new];
        _recycledPages = [NSMutableSet new];
        _photos = [NSMutableArray new];
        _photoImageViews = [NSMutableArray new];
        _premiumColorEnabled = NO;
        _initalPageIndex = 0;
        _offsetPageIndex = 0;
        _autoHide = NO;

        _statusBarHeight = 0;
        _displayDoneButton = YES;
        _displayActionRightButton = YES;
        _doneButtonImage = nil;
        _headerImage = nil;
        _actionRightButtonImage = nil;

        _displayToolbar = YES;
        _displayActionButton = YES;
        _displayArrowButton = YES;
        _displayCounterLabel = NO;

        _areControlsHidden = NO;
        
        _forceHideStatusBar = NO;
        _usePopAnimation = NO;
        _disableVerticalSwipe = NO;
        _actionButtonIsAbuseAction = NO;

        _useWhiteBackgroundColor = NO;
        _leftArrowImage = _rightArrowImage = _leftArrowSelectedImage = _rightArrowSelectedImage = nil;

        _arrowButtonsChangePhotosAnimated = YES;

        _backgroundScaleFactor = 1.0;
        _animationDuration = 0.17;
        _senderViewForAnimation = nil;
        _scaleImage = nil;

        _isdraggingPhoto = NO;

        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
            self.automaticallyAdjustsScrollViewInsets = NO;

        _applicationWindow = [[[UIApplication sharedApplication] delegate] window];

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {
            self.modalPresentationStyle = UIModalPresentationCustom;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            self.modalPresentationCapturesStatusBarAppearance = YES;
        }
        else
        {
            _applicationTopViewController = [self topviewController];
            _previousModalPresentationStyle = _applicationTopViewController.modalPresentationStyle;
            _applicationTopViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }

        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        // Listen for IDMPhoto notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleIDMPhotoLoadingDidEndNotification:)
                                                     name:IDMPhoto_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
    }

    return self;
}

- (id)initWithPhotos:(NSArray *)photosArray {
    if ((self = [self init])) {
        _photos = [[NSMutableArray alloc] initWithArray:photosArray];
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithPhotos:(NSArray *)photosArray animatedFromView:(UIView*)view {
    if ((self = [self init])) {
        _photos = [[NSMutableArray alloc] initWithArray:photosArray];
        _senderViewForAnimation = view;
    }
    return self;
}

- (id)initWithPhotoURLs:(NSArray *)photoURLsArray {
    if ((self = [self init])) {
        NSArray *photosArray = [IDMPhoto photosWithURLs:photoURLsArray];
        _photos = [[NSMutableArray alloc] initWithArray:photosArray];
    }
    return self;
}

- (id)initWithPhotoURLs:(NSArray *)photoURLsArray animatedFromView:(UIView*)view {
    if ((self = [self init])) {
        NSArray *photosArray = [IDMPhoto photosWithURLs:photoURLsArray];
        _photos = [[NSMutableArray alloc] initWithArray:photosArray];
        _senderViewForAnimation = view;
    }
    return self;
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // [self releaseAllUnderlyingPhotos];
}

-(void)setBgImage:(UIImage *)bgImage1
{
    bgImage = bgImage1;
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; } // Release photos
}

- (void)didReceiveMemoryWarning {
    // Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos];
    [_recycledPages removeAllObjects];

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - Pan Gesture

- (void)panGestureRecognized:(id)sender {
    // Initial Setup
    IDMZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
    //IDMTapDetectingImageView *scrollView.photoImageView = scrollView.photoImageView;

    static float firstX, firstY;

    float viewHeight = scrollView.frame.size.height;
    float viewHalfHeight = viewHeight/2;

    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];

    // Gesture Began
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        // [self setControlsHidden:YES animated:YES permanent:YES];

        firstX = [scrollView center].x;
        firstY = [scrollView center].y;

        _senderViewForAnimation.hidden = (_currentPageIndex == _initalPageIndex);

        _isdraggingPhoto = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }

    translatedPoint = CGPointMake(firstX, firstY+translatedPoint.y);
    [scrollView setCenter:translatedPoint];

    float newY = scrollView.center.y - viewHalfHeight;
    float newAlpha = 1 - fabsf(newY)/viewHeight;
    _pagingScrollView.alpha = newAlpha;

    self.view.opaque = YES;

    // Gesture Ended
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(scrollView.center.y > viewHalfHeight+40 || scrollView.center.y < viewHalfHeight-40) // Automatic Dismiss View
        {

            NSUInteger numVisibleItems = _photoImageViews.count;
            for (NSUInteger i = 0; i < numVisibleItems; i++) {
                NSDictionary *dict = [_photoImageViews objectAtIndex:i];
                NSUInteger visiblePageIndex = [dict[@"pageIndex"] integerValue];

                if (_currentPageIndex == visiblePageIndex) {
                    UIImageView*tmpView = dict[@"imageView"];
                    _senderViewForAnimation = tmpView;
                    //[self performCloseAnimationWithScrollView:scrollView];
                    NSLog(@"%@",dict[@"pageIndex"]);
                    _initalPageIndex = visiblePageIndex;
                    NSArray*rectParam = dict[@"rectVisibleCell"];
                    _senderViewOriginalFrame = CGRectMake([rectParam[0] floatValue], [rectParam[1] floatValue], [rectParam[2] floatValue], [rectParam[3] floatValue]);
                    //return;
                }
                //int visiblePageIndex = dict[]
            }


            if (_senderViewForAnimation && _currentPageIndex == _initalPageIndex) {
                [self performCloseAnimationWithScrollView:scrollView];
                return;
            }

            CGFloat finalX = firstX, finalY;

            CGFloat windowsHeigt = [_applicationWindow frame].size.height;

            if(scrollView.center.y > viewHalfHeight+30) // swipe down
                finalY = windowsHeigt*2;
            else // swipe up
                finalY = -viewHalfHeight;

            CGFloat animationDuration = _animationDuration;

            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDelegate:self];
            [scrollView setCenter:CGPointMake(finalX, finalY)];
            [UIView commitAnimations];

            [self performSelector:@selector(doneButtonPressed:) withObject:self afterDelay:animationDuration];
        }
        else // Continue Showing View
        {
            _isdraggingPhoto = NO;
            [self setNeedsStatusBarAppearanceUpdate];

            CGFloat velocityY = (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);

            CGFloat finalX = firstX;
            CGFloat finalY = viewHalfHeight;

            CGFloat animationDuration = (ABS(velocityY)*.0002)+.2;

            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView setAnimationDelegate:self];
            [scrollView setCenter:CGPointMake(finalX, finalY)];
            [UIView commitAnimations];
        }
    }
}

#pragma mark - Animation

- (UIImage*)rotateImageToCurrentOrientation:(UIImage*)image
{
    return image;
}

- (void)performPresentAnimation {

    self.view.alpha = 0.0f;
    _pagingScrollView.alpha = 0.0f;
    UIImage *imageFromView = _scaleImage ? _scaleImage : [self getImageFromView:_senderViewForAnimation];
    imageFromView = [self rotateImageToCurrentOrientation:imageFromView];

    _senderViewOriginalFrame = [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil];

    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;

    fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    fadeView.alpha = 0.0f;
    fadeView.backgroundColor = [UIColor colorWithRed:238.0f / 255.0f green:238.0f / 255.0f blue:238.0f / 255.0f alpha:1.0];
    [_applicationWindow addSubview:fadeView];

    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = _senderViewOriginalFrame;
    resizableImageView.clipsToBounds = YES;
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    [_applicationWindow addSubview:resizableImageView];
    _senderViewForAnimation.hidden = YES;
    [self animateHeader];
    void (^completion)() = ^() {
        self.view.alpha = 1.0f;
        _pagingScrollView.alpha = 1.0f;
        [UIView animateWithDuration:_animationDuration animations:^{
            resizableImageView.backgroundColor = [UIColor clearColor];
            fadeView.alpha = 1.0f;
            resizableImageView.alpha = 1.0f;

        } completion:^(BOOL finished) {
            
            [fadeView removeFromSuperview];
            [resizableImageView removeFromSuperview];
            [self.view insertSubview:fadeView atIndex:0];
        }];

    };
    float scaleFactor = (imageFromView ? imageFromView.size.width : screenWidth) / screenWidth;
    CGRect finalImageViewFrame = CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2), screenWidth, imageFromView.size.height / scaleFactor);
    if (finalImageViewFrame.size.height>screenHeight) {
        float scaleFactor2 = finalImageViewFrame.size.height/screenHeight;
        finalImageViewFrame = CGRectMake((screenWidth-(finalImageViewFrame.size.width/scaleFactor2))/2, 0, finalImageViewFrame.size.width/scaleFactor2, screenHeight);
    }
    
    if(_usePopAnimation)
    {
        [self animateView:resizableImageView toFrame:finalImageViewFrame completion:completion];
    }
    else
    {
        [UIView animateWithDuration:(_animationDuration+0.15f) animations:^{
            fadeView.alpha = 1.0f;
            resizableImageView.layer.frame = finalImageViewFrame;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
}


- (void)performCloseAnimationWithScrollView:(IDMZoomingScrollView*)scrollView {
    if ([_delegate respondsToSelector:@selector(photoBrowser:didHidePhotoAtIndex:)]) {
        [_delegate photoBrowser:self didHidePhotoAtIndex:_currentPageIndex];
    }
    [_toolbar removeFromSuperview];
    [_doneButton removeFromSuperview];
    [_actionRightButton removeFromSuperview];
    [headerView removeFromSuperview];
    float fadeAlpha = 1 - fabs(scrollView.frame.origin.y)/scrollView.frame.size.height;

    UIImage *imageFromView = [scrollView.photo underlyingImage];
    if (!imageFromView && [scrollView.photo respondsToSelector:@selector(placeholderImage)]) {
        imageFromView = [scrollView.photo placeholderImage];
    }

    imageFromView = [self rotateImageToCurrentOrientation:imageFromView];

    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;

    float scaleFactor = imageFromView.size.width / screenWidth;

    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = (imageFromView) ? CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2)+scrollView.frame.origin.y, screenWidth, imageFromView.size.height / scaleFactor) : CGRectZero;
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    resizableImageView.clipsToBounds = YES;
    [fadeView removeFromSuperview];
    [_applicationWindow addSubview:fadeView];
    [_applicationWindow addSubview:resizableImageView];
    self.view.hidden = YES;
    
    void (^completion)() = ^() {
        _senderViewForAnimation.hidden = NO;
        _senderViewForAnimation = nil;
        _scaleImage = nil;

        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];

        [self prepareForClosePhotoBrowser];
        [self dismissPhotoBrowserAnimated:NO];
    };

    [UIView animateWithDuration:_animationDuration animations:^{
        fadeView.alpha = 0;
    } completion:nil];

    if(_usePopAnimation)
    {
        [self animateView:resizableImageView
                  toFrame:_senderViewOriginalFrame
               completion:completion];
    }
    else
    {
        [UIView animateWithDuration:_animationDuration animations:^{
            resizableImageView.layer.frame = _senderViewOriginalFrame;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
}

#pragma mark - Genaral

- (void)prepareForClosePhotoBrowser {
    // Gesture
    [_applicationWindow removeGestureRecognizer:_panGesture];
    _autoHide = NO;

    // Controls
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
}

- (void)dismissPhotoBrowserAnimated:(BOOL)animated {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    if ([_delegate respondsToSelector:@selector(photoBrowser:didHidePhotoAtIndex:)]) {
        [_delegate photoBrowser:self didHidePhotoAtIndex:_currentPageIndex];
    }
    [_toolbar removeFromSuperview];
    [_doneButton removeFromSuperview];
    [_actionRightButton removeFromSuperview];
    [headerView removeFromSuperview];
    if ([_delegate respondsToSelector:@selector(photoBrowser:willDismissAtPageIndex:)])
        [_delegate photoBrowser:self willDismissAtPageIndex:_currentPageIndex];

    [self dismissViewControllerAnimated:animated completion:^{
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDismissAtPageIndex:)])
            [_delegate photoBrowser:self didDismissAtPageIndex:_currentPageIndex];

        if (SYSTEM_VERSION_LESS_THAN(@"8.0"))
        {
            _applicationTopViewController.modalPresentationStyle = _previousModalPresentationStyle;
        }
    }];
}

- (UIButton*)customToolbarButtonImage:(UIImage*)image imageSelected:(UIImage*)selectedImage action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:selectedImage forState:UIControlStateDisabled];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setContentMode:UIViewContentModeCenter];
    [button setFrame:CGRectMake(0,0, image.size.width, image.size.height)];
    return button;
}

- (UIImage*)getImageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIViewController *)topviewController
{
    UIViewController *topviewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topviewController.presentedViewController) {
        topviewController = topviewController.presentedViewController;
    }

    return topviewController;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    self.view.clipsToBounds = YES;
    // Setup paging scrolling view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor clearColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    if (@available(iOS 11.0, *)) {
        [_pagingScrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    } else {
        // Fallback on earlier versions
    }
    [self.view addSubview:_pagingScrollView];

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:currentOrientation]];
    _toolbar.backgroundColor = [UIColor clearColor];
    _toolbar.clipsToBounds = NO;
    _toolbar.translucent = YES;
    [_toolbar setBackgroundImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny
                      barMetrics:UIBarMetricsDefault];

    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, _headerHeight)];
    [self.view addSubview:headerView];
    headerView.backgroundColor = [UIColor clearColor];
    
    // Transition animation
    [self performPresentAnimation];
    
    if (_headerImage) {
        headerImageView = [[UIImageView alloc] initWithImage:_headerImage];
        [headerView addSubview:headerImageView];
        headerImageView.frame = headerView.bounds;
        headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        headerImageView.clipsToBounds = YES;
        headerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    } else {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = headerView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [headerView addSubview:blurEffectView];
    }
    premiumColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, _headerHeight)];
    if (premiumColorView) {
        premiumColorView.hidden = !_premiumColorEnabled;
    }
    [headerView addSubview:premiumColorView];
    premiumColorView.frame = headerView.bounds;
    gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.colors = [NSArray arrayWithObjects:(id)(id)[UIColor colorWithRed:229.0f / 255.0f green:104.0f / 255.0f blue:107.0f / 255.0f alpha:0.0f].CGColor, (id)[UIColor colorWithRed:229.0f / 255.0f green:104.0f / 255.0f blue:107.0f / 255.0f alpha:0.85f].CGColor, nil];
    [premiumColorView.layer addSublayer:gradientLayer];
    gradientLayer.frame = headerView.bounds;
    premiumColorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //action

    _actionRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_actionRightButton setFrame:[self frameForRightActionButtonAtOrientation:currentOrientation]];
    [_actionRightButton setAlpha:1.0f];
    [_actionRightButton addTarget:self action:@selector(rightActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    if(!_actionRightButtonImage) {
        [_actionRightButton.titleLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
        [_actionRightButton setBackgroundColor:[UIColor clearColor]];
        float topMarginDots = _actionRightButton.frame.size.height/2 - 2;
        float dDot = 5.0f;
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(5, topMarginDots, dDot, dDot)] CGPath]];
        [circleLayer setFillColor:[[UIColor whiteColor] CGColor]];

        CAShapeLayer *circleLayer1 = [CAShapeLayer layer];
        [circleLayer1 setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(14, topMarginDots, dDot, dDot)] CGPath]];
        [circleLayer1 setFillColor:[[UIColor whiteColor] CGColor]];

        CAShapeLayer *circleLayer2 = [CAShapeLayer layer];
        [circleLayer2 setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(23, topMarginDots, dDot, dDot)] CGPath]];
        [circleLayer2 setFillColor:[[UIColor whiteColor] CGColor]];

        [_actionRightButton.layer addSublayer:circleLayer];
        [_actionRightButton.layer addSublayer:circleLayer1];
        [_actionRightButton.layer addSublayer:circleLayer2];
    }
    else {
        [_actionRightButton setImage:_actionRightButtonImage forState:UIControlStateNormal];
        _actionRightButton.contentMode = UIViewContentModeScaleAspectFill;
    }
    // Close Button
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    [_doneButton setAlpha:1.0f];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    if(!_doneButtonImage) {
        [_doneButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal|UIControlStateHighlighted];
        [_doneButton setTitle:IDMPhotoBrowserLocalizedStrings(@"Back") forState:UIControlStateNormal];
        [_doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
        [_doneButton setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
        _doneButton.layer.cornerRadius = 3.0f;
        _doneButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.9].CGColor;
        _doneButton.layer.borderWidth = 1.0f;
    }
    else {
        [_doneButton setImage:_doneButtonImage forState:UIControlStateNormal];
        _doneButton.contentMode = UIViewContentModeScaleAspectFill;
    }
    _toolbar.alpha =headerView.alpha = _doneButton.alpha = _actionRightButton.alpha = self.navigationController.navigationBar.alpha = 1.0f;

    UIImage *leftButtonImage = (_leftArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeft.png"]          : _leftArrowImage;

    UIImage *rightButtonImage = (_rightArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRight.png"]         : _rightArrowImage;

    UIImage *leftButtonSelectedImage = (_leftArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeftSelected.png"]  : _leftArrowSelectedImage;

    UIImage *rightButtonSelectedImage = (_rightArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRightSelected.png"] : _rightArrowSelectedImage;

    _previousButton = [[UIBarButtonItem alloc] initWithCustomView:[self customToolbarButtonImage:leftButtonImage
                                                                                   imageSelected:leftButtonSelectedImage
                                                                                          action:@selector(gotoPreviousPage)]];

    _nextButton = [[UIBarButtonItem alloc] initWithCustomView:[self customToolbarButtonImage:rightButtonImage
                                                                               imageSelected:rightButtonSelectedImage
                                                                                      action:@selector(gotoNextPage)]];

    // Counter Label
    UIView*clView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 95, 44)];
    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _statusBarHeight/2, 95, 44)];
    _counterLabel.textAlignment = NSTextAlignmentCenter;
    _counterLabel.backgroundColor = [UIColor clearColor];
    _counterLabel.font = [UIFont fontWithName:@"roboto-medium" size:16];
    _counterLabel.textColor = [UIColor whiteColor];
    // Counter Button
    [clView addSubview:_counterLabel];
    _counterButton = [[UIBarButtonItem alloc] initWithCustomView:clView];


    // Action Button
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(actionButtonPressed:)];

    // Gesture
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [_panGesture setMinimumNumberOfTouches:1];
    [_panGesture setMaximumNumberOfTouches:1];

    // Update
    //[self reloadData];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFromStatusBar:) name:@"backFromStatusBar" object:nil];
    // Super
    [super viewDidLoad];
}

-(void)backFromStatusBar:(NSNotification*)notification
{
    [self doneButtonPressed:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    // Update
    [self reloadDataFromDeletionButton:NO];

    // Super
    [super viewWillAppear:animated];

    // Status Bar
    _statusBarOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;

    

    // Update UI
    //[self hideControlsAfterDelay];
}

-(void)animateHeader {
    _toolbar.alpha =headerView.alpha = _doneButton.alpha = _actionRightButton.alpha = self.navigationController.navigationBar.alpha = 0.0f;
        [UIView animateWithDuration:_animationDuration animations:^(void) {
            CGFloat alpha = 1.0f;
            [self.navigationController.navigationBar setAlpha:alpha];
            [_toolbar setAlpha:alpha];
            [_doneButton setAlpha:alpha];
            [headerView setAlpha:alpha];
            [_actionRightButton setAlpha:alpha];
        } completion:^(BOOL finished) {}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)updatePhotosArray:(NSArray*)array;
{
    _photos = [[NSMutableArray alloc] initWithArray:array];
    //[self reloadDataFromDeletionButton:NO];
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {

    _currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    _toolbar = nil;
    _doneButton = nil;
    _actionRightButton = nil;
    _previousButton = nil;
    _nextButton = nil;

    [super viewDidUnload];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    if(_forceHideStatusBar) {
        return YES;
    }

    if(_isdraggingPhoto) {
        if(_statusBarOriginallyHidden) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return [self areControlsHidden];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - Layout


- (void)viewWillLayoutSubviews {
    // Flag
    _performingLayout = YES;

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar.frame = [self frameForToolbarAtOrientation:currentOrientation];

    // Done button
    _doneButton.frame = [self frameForDoneButtonAtOrientation:currentOrientation];

    _actionRightButton.frame = [self frameForRightActionButtonAtOrientation:currentOrientation];

    if (alertPopoverPresentationController) {
        alertPopoverPresentationController.sourceRect = _actionRightButton.frame;
        alertPopoverPresentationController.sourceView = self.view;
    }

    // Remember index
    NSUInteger indexPriorToLayout = _currentPageIndex;

    // Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];

    // Frame needs changing
    _pagingScrollView.frame = pagingScrollViewFrame;

    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, _headerHeight);
    premiumColorView.frame = headerView.bounds;
    gradientLayer.frame = headerView.bounds;
    // Adjust frames and configuration of each visible page
    for (IDMZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
        page.frame = [self frameForPageAtIndex:index];
        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
        [page setMaxMinZoomScalesForCurrentBounds];
    }

    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    [self didStartViewingPageAtIndex:_currentPageIndex]; // initial

    // Reset
    _currentPageIndex = indexPriorToLayout;
    _performingLayout = NO;

    // Super
    [super viewWillLayoutSubviews];
}

-(void)setPremiumColorEnabled:(BOOL)premiumColorEnabled {
    _premiumColorEnabled = premiumColorEnabled;
    if (premiumColorView) {
        premiumColorView.hidden = !_premiumColorEnabled;
    }
}

- (void)performLayoutFromDeletion:(BOOL)fromDeletion {
    // Setup
    BOOL isLast = NO;
    if(_currentPageIndex == _photos.count)
    {
        _currentPageIndex--;
        isLast = true;
    }
    _performingLayout = YES;
    NSUInteger numberOfPhotos = [self numberOfPhotos];

    // Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];

    // Toolbar
    if (_displayToolbar) {
        [self.view addSubview:_toolbar];
    } else {
        [_toolbar removeFromSuperview];
    }

    // Close button
    if(_displayDoneButton && !self.navigationController.navigationBar)
        [self.view addSubview:_doneButton];

    if(_displayActionRightButton && !self.navigationController.navigationBar)
        [self.view addSubview:_actionRightButton];

    // Toolbar items & navigation
    UIBarButtonItem *fixedLeftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                    target:self action:nil];
    fixedLeftSpace.width = 32; // To balance action button
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:self action:nil];
    NSMutableArray *items = [NSMutableArray new];

    if (_displayActionButton)
        [items addObject:fixedLeftSpace];
    [items addObject:flexSpace];

    if (numberOfPhotos > 1 && _displayArrowButton)
        [items addObject:_previousButton];

    if(_displayCounterLabel) {
        [items addObject:flexSpace];
        [items addObject:_counterButton];
    }

    [items addObject:flexSpace];
    if (numberOfPhotos > 1 && _displayArrowButton)
        [items addObject:_nextButton];
    [items addObject:flexSpace];

    if(_displayActionButton)
        [items addObject:_actionButton];

    [_toolbar setItems:items];
    [self updateToolbar];

    // Content offset
    if(!fromDeletion)
    {
        _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    }
    else
    {
        _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
        CGRect origRect = _pagingScrollView.frame;

        if(isLast)
        {
            _pagingScrollView.frame = CGRectMake(-_pagingScrollView.frame.size.width, _pagingScrollView.frame.origin.y, _pagingScrollView.frame.size.width, _pagingScrollView.frame.size.height);
            [UIView animateWithDuration:_animationDuration animations:^{
                _pagingScrollView.frame = origRect;
            } completion:^(BOOL finished) {
                //complete
            }];
        }
        else
        {
            _pagingScrollView.frame = CGRectMake(_pagingScrollView.frame.size.width, _pagingScrollView.frame.origin.y, _pagingScrollView.frame.size.width, _pagingScrollView.frame.size.height);
            [UIView animateWithDuration:_animationDuration animations:^{
                _pagingScrollView.frame = origRect;
            } completion:^(BOOL finished) {
                //complete
            }];
        }
    }


    [self tilePages];
    _performingLayout = NO;

    if(! _disableVerticalSwipe)
        [self.view addGestureRecognizer:_panGesture];
}

#pragma mark - Data

- (void)reloadDataFromDeletionButton:(BOOL)delBtn {
    // Get data
    // [self releaseAllUnderlyingPhotos];

    // Update
    [self performLayoutFromDeletion:delBtn];

    // Layout
    [self.view setNeedsLayout];
}

- (NSUInteger)numberOfPhotos {
    return _photos.count;
}

- (id<IDMPhoto>)photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) {
        if(![_photos[index] isKindOfClass:[NSNull class]])
            return _photos[index];
    }
    return NULL;
}

- (IDMCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    IDMCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <IDMPhoto> photo = [self photoAtIndex:index];
        if (photo) {
            if ([photo respondsToSelector:@selector(caption)]) {
                if ([photo caption]) captionView = [[IDMCaptionView alloc] initWithPhoto:photo];
            }
        }

    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha

    return captionView;
}

- (UIImage *)imageForPhoto:(id<IDMPhoto>)photo {
    if (photo) {
        // Get image or obtain in background
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
            if ([photo respondsToSelector:@selector(placeholderImage)]) {
                return [photo placeholderImage];
            }
        }
    }

    return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<IDMPhoto>)photo {
    IDMZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <IDMPhoto> photo = [self photoAtIndex:pageIndex-1];
                if (photo) {
                    if (![photo underlyingImage]) {
                        [photo loadUnderlyingImageAndNotify];
                        IDMLog(@"Pre-loading image at index %i", pageIndex-1);
                    }
                }

            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <IDMPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (photo) {
                    if (![photo underlyingImage]) {
                        [photo loadUnderlyingImageAndNotify];
                        IDMLog(@"Pre-loading image at index %i", pageIndex+1);
                    }
                }

            }
        }
    }
}

#pragma mark - IDMPhoto Loading Notification

- (void)handleIDMPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <IDMPhoto> photo = [notification object];
    IDMZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
        }
    }
}

#pragma mark - Paging

- (void)tilePages {
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger) floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger) floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;

    // Recycle no longer needed pages
    NSInteger pageIndex;
    for (IDMZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
            [_recycledPages addObject:page];
            [page prepareForReuse];
            [page removeFromSuperview];
            IDMLog(@"Removed page at index %i", PAGE_INDEX(page));
        }
    }
    [_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];

    // Add missing pages
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            // Add new page
            IDMZoomingScrollView *page;
            page = [[IDMZoomingScrollView alloc] initWithPhotoBrowser:self];
            page.backgroundColor = [UIColor clearColor];
            page.opaque = YES;

            [self configurePage:page forIndex:index];
            [_visiblePages addObject:page];
            [_pagingScrollView addSubview:page];
            IDMLog(@"Added page at index %i", index);

            // Add caption
            IDMCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            captionView.frame = [self frameForCaptionView:captionView atIndex:index];
            [_pagingScrollView addSubview:captionView];
            page.captionView = captionView;
        }
    }
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (IDMZoomingScrollView *page in _visiblePages)
        if (PAGE_INDEX(page) == index) return YES;
    return NO;
}

- (IDMZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
    IDMZoomingScrollView *thePage = nil;
    for (IDMZoomingScrollView *page in _visiblePages) {
        if (PAGE_INDEX(page) == index) {
            thePage = page;
            break;
        }
    }
    return thePage;
}

- (IDMZoomingScrollView *)pageDisplayingPhoto:(id<IDMPhoto>)photo {
    IDMZoomingScrollView *thePage = nil;
    for (IDMZoomingScrollView *page in _visiblePages) {
        if (page.photo == photo) {
            thePage = page;
            break;
        }
    }
    return thePage;
}

- (void)configurePage:(IDMZoomingScrollView *)page forIndex:(NSUInteger)index {
    page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];

    if (page.photo) {
        __block __weak IDMPhoto *photo = (IDMPhoto*)page.photo;
        __weak IDMZoomingScrollView* weakPage = page;
        photo.progressUpdateBlock = ^(CGFloat progress, BOOL complete){
            [weakPage setProgress:progress forPhoto:photo withComplete:complete];
        };
    }

}

- (IDMZoomingScrollView *)dequeueRecycledPage {
    IDMZoomingScrollView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <IDMPhoto> currentPhoto = [self photoAtIndex:index];
    if (currentPhoto) {
        if ([currentPhoto underlyingImage]) {
            // photo loaded so load ajacent now
            [self loadAdjacentPhotosIfNecessary:currentPhoto];
        }
        if ([_delegate respondsToSelector:@selector(photoBrowser:didShowPhotoAtIndex:)]) {
            [_delegate photoBrowser:self didShowPhotoAtIndex:index];
        }
        if (_offsetPageIndex>0) {
            if (_currentPageIndex==_offsetPageIndex-3) {
                //NSLog(@"download photos");
                if ([_delegate respondsToSelector:@selector(photoBrowser:didWillShowPhotoWithOffsetIndex:)]) {
                    [_delegate photoBrowser:self didWillShowPhotoWithOffsetIndex:_offsetPageIndex];
                }
            }
        }
    }
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}

- (BOOL)isLandscape:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsLandscape(orientation);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = _headerHeight;
    return CGRectMake(0, 0, self.view.bounds.size.width, height);
}

- (CGRect)frameForRightActionButtonAtOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBound = self.view.bounds;
    CGFloat screenWidth = screenBound.size.width;

    return CGRectMake(screenWidth - 44, _statusBarHeight, 44, 44);
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    return CGRectMake(0, _statusBarHeight, 44, 44);
}

- (CGRect)frameForCaptionView:(IDMCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];

    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);

    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView  {
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating) return;

    // Tile pages
    [self tilePages];

    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger) (floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];

        if(_arrowButtonsChangePhotosAnimated) [self updateToolbar];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Hide controls when dragging begins
    //[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Update toolbar when page changes
    if(! _arrowButtonsChangePhotosAnimated) [self updateToolbar];
}



#pragma mark - Toolbar

- (void)updateToolbar {
    // Counter
    if ([self numberOfPhotos] > 0) {
        _counterLabel.text = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), @"/", (unsigned long)[self numberOfPhotos]];
    } else {
        _counterLabel.text = nil;
    }

    // Buttons
    _previousButton.enabled = (_currentPageIndex > 0);
    _nextButton.enabled = (_currentPageIndex < [self numberOfPhotos]-1);
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
    // Change page
    if (index < [self numberOfPhotos]) {
        CGRect pageFrame = [self frameForPageAtIndex:index];

        if(_arrowButtonsChangePhotosAnimated)
        {
            [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:YES];
        }
        else
        {
            _pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
            [self updateToolbar];
        }
    }

    // Update timer to give more time
    [self hideControlsAfterDelay];
}

- (void)gotoPreviousPage { [self jumpToPageAtIndex:_currentPageIndex-1]; }
- (void)gotoNextPage     { [self jumpToPageAtIndex:_currentPageIndex+1]; }

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    // Cancel any timers
    [self cancelControlHiding];
    _areControlsHidden = hidden;
    // Captions
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (IDMZoomingScrollView *page in _visiblePages) {
        if (page.captionView) [captionViews addObject:page.captionView];
    }

    // Hide/show bars
    [UIView animateWithDuration:(animated ? _animationDuration : 0) animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        [self.navigationController.navigationBar setAlpha:alpha];
        [_toolbar setAlpha:alpha];
        [_doneButton setAlpha:alpha];
        [headerView setAlpha:alpha];
        [_actionRightButton setAlpha:alpha];
        for (UIView *v in captionViews) v.alpha = alpha;
    } completion:^(BOOL finished) {}];

    // Control hiding timer
    // Will cancel existing timer but only begin hiding if they are visible
    if (!permanent) [self hideControlsAfterDelay];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)cancelControlHiding {
    // If a timer exists then cancel and release
    if (_controlVisibilityTimer) {
        [_controlVisibilityTimer invalidate];
        _controlVisibilityTimer = nil;
    }
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    // return;

    if (![self areControlsHidden]) {
        [self cancelControlHiding];
        _controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    }
}

- (BOOL)areControlsHidden { return _areControlsHidden; }
- (void)hideControls      { if(_autoHide) [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls    { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }


#pragma mark - Properties

- (void)setOffsetForDownloadPageIndex:(NSUInteger)index
{
    _offsetPageIndex = index;
}

- (void)setInitialPageIndex:(NSUInteger)index {
    // Validate
    NSInteger nf =  [self numberOfPhotos];
    if (index >= nf)
    {
        index = MAX(0, nf - 1);
    }
    _initalPageIndex = index;
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) [self tilePages];
    }
}

#pragma mark RNGridMenuDelegate

#pragma mark - Buttons

-(void)abusePhoto
{
    if ([_delegate respondsToSelector:@selector(photoBrowser:didAbuseButtonClickedWithIndex:)]) {
        [_delegate photoBrowser:self didAbuseButtonClickedWithIndex:_currentPageIndex];
    }
}

-(void)blockByPhoto
{
    if ([_delegate respondsToSelector:@selector(photoBrowser:didBlockButtonClickedWithIndex:)]) {
        [_delegate photoBrowser:self didBlockButtonClickedWithIndex:_currentPageIndex];
    }
}

-(void)deletePhoto
{
    [UIView animateWithDuration:_animationDuration animations:^{
        IDMZoomingScrollView*page = [self pageDisplayedAtIndex:_currentPageIndex];
        page.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        page.alpha = 0.1f;

    } completion:^(BOOL finished) {
        [_photos removeObjectAtIndex:_currentPageIndex];
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDeletePhotoAtIndex:)]) {
            [_delegate photoBrowser:self didDeletePhotoAtIndex:_currentPageIndex];
        }
        if(_photos.count == 0)
        {
            _senderViewForAnimation.hidden = NO;
            [self prepareForClosePhotoBrowser];
            [self dismissPhotoBrowserAnimated:YES];
            return ;
        }
        [self reloadDataFromDeletionButton:YES];
    }];
}

- (void)rightActionButtonPressed:(id)sender
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NULL message:NULL preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:^{}];
    }]];

    if (_actionButtonIsAbuseAction) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:reportAbuseString style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self abusePhoto];
        }]];
        [actionSheet addAction:[UIAlertAction actionWithTitle:blockUserString style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self blockByPhoto];
        }]];
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            alertPopoverPresentationController = actionSheet.popoverPresentationController;
            alertPopoverPresentationController.sourceRect = _actionRightButton.frame;
            alertPopoverPresentationController.sourceView = self.view;
        }

    }
    else{
        [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self deletePhoto];

        }]];
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            alertPopoverPresentationController = actionSheet.popoverPresentationController;
            alertPopoverPresentationController.sourceRect = _actionRightButton.frame;
            alertPopoverPresentationController.sourceView = self.view;
        }

    }
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)doneButtonPressed:(id)sender {

    if (_senderViewForAnimation && _currentPageIndex == _initalPageIndex) {
        IDMZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
        [self performCloseAnimationWithScrollView:scrollView];
    }
    else {
        _senderViewForAnimation.hidden = NO;
        [self prepareForClosePhotoBrowser];
        [self dismissPhotoBrowserAnimated:YES];
    }
}

- (void)actionButtonPressed:(id)sender {
    id <IDMPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if (photo) {
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            if(!_actionButtonTitles)
            {
                // Activity view
                NSMutableArray *activityItems = [NSMutableArray arrayWithObject:[photo underlyingImage]];
                if (photo.caption) [activityItems addObject:photo.caption];

                self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

                __typeof__(self) __weak selfBlock = self;

                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
                {
                    [self.activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                        [selfBlock hideControlsAfterDelay];
                        selfBlock.activityViewController = nil;
                    }];
                }
                else
                {
                    [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
                        [selfBlock hideControlsAfterDelay];
                        selfBlock.activityViewController = nil;
                    }];
                }

                [self presentViewController:self.activityViewController animated:YES completion:nil];
            }
            else
            {
                // Action sheet
                self.actionsSheet = [UIActionSheet new];
                self.actionsSheet.delegate = self;
                for(NSString *action in _actionButtonTitles) {
                    [self.actionsSheet addButtonWithTitle:action];
                }

                self.actionsSheet.cancelButtonIndex = [self.actionsSheet addButtonWithTitle:IDMPhotoBrowserLocalizedStrings(@"Cancel")];
                self.actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    [_actionsSheet showFromBarButtonItem:sender animated:YES];
                } else {
                    [_actionsSheet showInView:self.view];
                }
            }

            // Keep controls hidden
            [self setControlsHidden:NO animated:YES permanent:YES];
        }
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {
        self.actionsSheet = nil;

        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:didDismissActionSheetWithButtonIndex:photoIndex:)]) {
                [_delegate photoBrowser:self didDismissActionSheetWithButtonIndex:buttonIndex photoIndex:_currentPageIndex];
                return;
            }
        }
    }

    [self hideControlsAfterDelay]; // Continue as normal...
}

#pragma mark - pop Animation

- (void)animateView:(UIView *)view toFrame:(CGRect)frame completion:(void (^)(void))completion
{
    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    [animation setSpringBounciness:6];
    [animation setDynamicsMass:1];
    [animation setToValue:[NSValue valueWithCGRect:frame]];
    [view pop_addAnimation:animation forKey:nil];

    if (completion)
    {
        [animation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
            completion();
        }];
    }
}

@end
