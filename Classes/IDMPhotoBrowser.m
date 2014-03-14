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
#import "SVProgressHUD.h"

#define kUSE_CURRENT_CONTEXT_PRESENTATION_STYLE 1

#ifndef IDMPhotoBrowserLocalizedStrings
#define IDMPhotoBrowserLocalizedStrings(key) \
NSLocalizedStringFromTableInBundle((key), nil, [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"IDMPBLocalizations" ofType:@"bundle"]], nil)
#endif

// Private
@interface IDMPhotoBrowser () {
	// Data
    NSMutableArray *_photos;
    
	// Views
	UIScrollView *_pagingScrollView;
	
    // Gesture
    UIPanGestureRecognizer *_panGesture;
    
	// Paging
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _pageIndexBeforeRotation;
    NSUInteger _currentPageIndex;
	
    // Buttons
    UIButton *_doneButton;
    
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
    UIStatusBarStyle _previousStatusBarStyle;
	BOOL _statusBarOriginallyHidden;
    
    // Present
    UIView *_senderViewForAnimation;
    
    // Misc
    BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _autoHide;
    NSInteger _initalPageIndex;
    
    CGRect _resizableImageViewFrame;
    //UIImage *_backgroundScreenshot;
    
    UIWindow *_applicationWindow;
    UIViewController *_applicationRootViewController;
}

// Private Properties
@property (nonatomic, strong) UIActionSheet *actionsSheet;
@property (nonatomic, strong) UIActivityViewController *activityViewController;

// Private Methods

// Layout
- (void)performLayout;

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
@synthesize displayDoneButton = _displayDoneButton, displayToolbar = _displayToolbar, displayActionButton = _displayActionButton, displayCounterLabel = _displayCounterLabel, useWhiteBackgroundColor = _useWhiteBackgroundColor, doneButtonImage = _doneButtonImage;
@synthesize leftArrowImage = _leftArrowImage, rightArrowImage = _rightArrowImage, leftArrowSelectedImage = _leftArrowSelectedImage, rightArrowSelectedImage = _rightArrowSelectedImage;
@synthesize displayArrowButton = _displayArrowButton, actionButtonTitles = _actionButtonTitles;
@synthesize arrowButtonsChangePhotosAnimated = _arrowButtonsChangePhotosAnimated;
@synthesize actionsSheet = _actionsSheet, activityViewController = _activityViewController;
@synthesize trackTintColor = _trackTintColor, progressTintColor = _progressTintColor;
@synthesize delegate = _delegate;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        // Defaults
        self.hidesBottomBarWhenPushed = YES;
        _currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
		_rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [NSMutableSet new];
        _recycledPages = [NSMutableSet new];
        _photos = [NSMutableArray new];
        
        _initalPageIndex = 0;
        _autoHide = YES;
        
        _displayDoneButton = YES;
        _doneButtonImage = nil;
        
        _displayToolbar = YES;
        _displayActionButton = YES;
        _displayArrowButton = YES;
        _displayCounterLabel = NO;
        
        _useWhiteBackgroundColor = NO;
        _leftArrowImage = _rightArrowImage = _leftArrowSelectedImage = _rightArrowSelectedImage = nil;
        
        _arrowButtonsChangePhotosAnimated = YES;
        
        _backgroundScaleFactor = 1.0;
        _animationDuration = 0.28;
        _senderViewForAnimation = nil;
        _scaleImage = nil;
        
        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
            self.automaticallyAdjustsScrollViewInsets = NO;
        
        _applicationWindow = [[[UIApplication sharedApplication] delegate] window];
        _applicationRootViewController = [_applicationWindow rootViewController];
        
        // if remove this: rotation works, but screw presentation/animation
        if(kUSE_CURRENT_CONTEXT_PRESENTATION_STYLE) _applicationRootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
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
    [self releaseAllUnderlyingPhotos];
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
        [self setControlsHidden:YES animated:YES permanent:YES];
        
        firstX = [scrollView center].x;
        firstY = [scrollView center].y;
        
        _senderViewForAnimation.hidden = (_currentPageIndex == _initalPageIndex);
    }
    
    translatedPoint = CGPointMake(firstX, firstY+translatedPoint.y);
    [scrollView setCenter:translatedPoint];
    
    float newY = scrollView.center.y - viewHalfHeight;
    float newAlpha = 1 - abs(newY)/viewHeight; //abs(newY)/viewHeight * 1.8;
    
    self.view.opaque = YES;
    
    self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:newAlpha];
    
    /*UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:_backgroundScreenshot];
    backgroundImageView.alpha = 1 - newAlpha;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[self getImageFromView:backgroundImageView]];*/
    
    // Gesture Ended
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(scrollView.center.y > viewHalfHeight+40 || scrollView.center.y < viewHalfHeight-40) // Automatic Dismiss View
        {
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
            
            CGFloat animationDuration = 0.35;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDelegate:self];
            [scrollView setCenter:CGPointMake(finalX, finalY)];
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            //self.view.backgroundColor = [UIColor colorWithPatternImage:[self getImageFromView:backgroundImageView]];
            [UIView commitAnimations];
            
            [self performSelector:@selector(doneButtonPressed:) withObject:self afterDelay:animationDuration];
        }
        else // Continue Showing View
        {
            self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:1];
            //self.view.backgroundColor = [UIColor colorWithPatternImage:[self getImageFromView:backgroundImageView]];
            
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
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        UIImageOrientation orientation = ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) ?UIImageOrientationLeft : UIImageOrientationRight;
        
        UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:image.CGImage
                                                           scale:1.0
                                                     orientation:orientation];
        
        image = rotatedImage;
    }
    
    return image;
}

- (void)performPresentAnimation {
    self.view.alpha = 0.0f;
    
    UIImage *imageFromView = _scaleImage ? _scaleImage : [self getImageFromView:_senderViewForAnimation];
    imageFromView = [self rotateImageToCurrentOrientation:imageFromView];
    
    _resizableImageViewFrame = [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil];
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;
    
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    fadeView.backgroundColor = [UIColor clearColor];
    [_applicationWindow addSubview:fadeView];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = _resizableImageViewFrame;
    resizableImageView.clipsToBounds = YES;
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor) ? 1 : 0 alpha:1];
    [_applicationWindow addSubview:resizableImageView];
    _senderViewForAnimation.hidden = YES;
    
    [UIView animateWithDuration:_animationDuration animations:^{
        /*CGAffineTransform zoom = CGAffineTransformScale(CGAffineTransformIdentity, _backgroundScaleFactor, _backgroundScaleFactor);
        [_applicationRootViewController.view setTransform:zoom];*/
        
        fadeView.backgroundColor = self.useWhiteBackgroundColor ? [UIColor whiteColor] : [UIColor blackColor];

        float scaleFactor = (imageFromView ? imageFromView.size.width : screenWidth) / screenWidth;
        
        resizableImageView.frame = CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2), screenWidth, imageFromView.size.height / scaleFactor);
    } completion:^(BOOL finished) {
        self.view.alpha = 1.0f;
        resizableImageView.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor) ? 1 : 0 alpha:1];
        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];
    }];
}

- (void)performCloseAnimationWithScrollView:(IDMZoomingScrollView*)scrollView {
    float fadeAlpha = 1 - abs(scrollView.frame.origin.y)/scrollView.frame.size.height;
    
    UIImage *imageFromView = [scrollView.photo underlyingImage];
    //imageFromView = [self rotateImageToCurrentOrientation:imageFromView];

    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;
    
    float scaleFactor = imageFromView.size.width / screenWidth;
    
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    fadeView.backgroundColor = self.useWhiteBackgroundColor ? [UIColor whiteColor] : [UIColor blackColor];
    fadeView.alpha = fadeAlpha;
    [_applicationWindow addSubview:fadeView];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = (imageFromView) ? CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2)+scrollView.frame.origin.y, screenWidth, imageFromView.size.height / scaleFactor) : CGRectZero;
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    resizableImageView.clipsToBounds = YES;
    [_applicationWindow addSubview:resizableImageView];
    self.view.hidden = YES;
    
    [UIView animateWithDuration:_animationDuration animations:^{
        //[_applicationRootViewController.view setTransform:CGAffineTransformIdentity];
        
        resizableImageView.layer.frame = _resizableImageViewFrame;
        fadeView.alpha = 0;
        self.view.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        _senderViewForAnimation.hidden = NO;
        _senderViewForAnimation = nil;
        _scaleImage = nil;
        
        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];
        
        [self prepareForClosePhotoBrowser];
        [self dismissPhotoBrowserAnimated:YES];
    }];
}

#pragma mark - Genaral

- (void)prepareForClosePhotoBrowser {
    // Status Bar
    /*if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        //[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        [UIView animateWithDuration:0.3 animations:^(void) {
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {}];
    }*/
    
    /*if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:YES];
    }*/
    
    // Gesture
    [_applicationWindow removeGestureRecognizer:_panGesture];
    
    _autoHide = NO;
    
    // Controls
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
}

- (void)dismissPhotoBrowserAnimated:(BOOL)animated {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self dismissViewControllerAnimated:animated completion:^{
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDismissAtPageIndex:)])
            [_delegate photoBrowser:self didDismissAtPageIndex:_currentPageIndex];
        
        _applicationRootViewController.modalPresentationStyle = 1;
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
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 2);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/*- (UIImage*)takeScreenshot {
    UIGraphicsBeginImageContext(_applicationWindow.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}*/

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    // Transition animation
    [self performPresentAnimation];
    
    /*if(!_senderViewForAnimation) // Default presentation (withoung animation) {
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) // ios 7 or greater
            [UIView animateWithDuration:0.0 animations:^{ } completion:^(BOOL finished) {
                [UIView animateWithDuration:_animationDuration animations:^{ self.view.alpha = 1; }];
            }];
        else // ios 6 or less
            [UIView animateWithDuration:_animationDuration animations:^{ self.view.alpha = 1; }];
    }*/
    
    // View
	self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:1];
    
    self.view.clipsToBounds = YES;
    
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    //_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor clearColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:currentOrientation]];
    _toolbar.backgroundColor = [UIColor clearColor];
    _toolbar.clipsToBounds = YES;
    _toolbar.translucent = YES;
    [_toolbar setBackgroundImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny
                      barMetrics:UIBarMetricsDefault];
    
    // Close Button
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    [_doneButton setAlpha:1.0f];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if(!_doneButtonImage) {
        [_doneButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal|UIControlStateHighlighted];
        [_doneButton setTitle:IDMPhotoBrowserLocalizedStrings(@"Done") forState:UIControlStateNormal];
        [_doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
        [_doneButton setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
        _doneButton.layer.cornerRadius = 3.0f;
        _doneButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.9].CGColor;
        _doneButton.layer.borderWidth = 1.0f;
    }
    else {
        [_doneButton setBackgroundImage:_doneButtonImage forState:UIControlStateNormal];
        _doneButton.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    UIImage *leftButtonImage = (_leftArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeft.png"]          : _leftArrowImage;
    
    UIImage *rightButtonImage = (_rightArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRight.png"]         : _rightArrowImage;
    
    UIImage *leftButtonSelectedImage = (_leftArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeftSelected.png"]  : _leftArrowSelectedImage;
    
    UIImage *rightButtonSelectedImage = (_rightArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRightSelected.png"] : _rightArrowSelectedImage;
    
    // Arrows
    _previousButton = [[UIBarButtonItem alloc] initWithCustomView:[self customToolbarButtonImage:leftButtonImage
                                                                                   imageSelected:leftButtonSelectedImage
                                                                                          action:@selector(gotoPreviousPage)]];
    
    _nextButton = [[UIBarButtonItem alloc] initWithCustomView:[self customToolbarButtonImage:rightButtonImage
                                                                               imageSelected:rightButtonSelectedImage
                                                                                      action:@selector(gotoNextPage)]];
    
    // Counter Label
    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 40)];
    _counterLabel.textAlignment = NSTextAlignmentCenter;
    _counterLabel.backgroundColor = [UIColor clearColor];
    _counterLabel.font = [UIFont fontWithName:@"Helvetica" size:17];
    
    if(_useWhiteBackgroundColor == NO) {
        _counterLabel.textColor = [UIColor whiteColor];
        _counterLabel.shadowColor = [UIColor darkTextColor];
        _counterLabel.shadowOffset = CGSizeMake(0, 1);
    }
    else {
        _counterLabel.textColor = [UIColor blackColor];
    }
    
    // Counter Button
    _counterButton = [[UIBarButtonItem alloc] initWithCustomView:_counterLabel];
    
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
    
	// Super
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    //_backgroundScreenshot = [self takeScreenshot];
    
    // Update
    [self reloadData];
    
    // Super
	[super viewWillAppear:animated];
    
    // Status Bar
    /*if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    }*/
    
    // Update UI
	[self hideControlsAfterDelay];
	
	_statusBarOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;
	[[UIApplication sharedApplication] setStatusBarHidden:YES
											withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[UIApplication sharedApplication] setStatusBarHidden:_statusBarOriginallyHidden
											withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
	_currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    _toolbar = nil;
    _doneButton = nil;
    _previousButton = nil;
    _nextButton = nil;
    
    [super viewDidUnload];
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _useWhiteBackgroundColor ? 1 : 0;
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationFade;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    //NSLog(@"viewDidLayoutSubviews  IDMPB  |  statusBarOrientation = %d", [[UIApplication sharedApplication] statusBarOrientation]);
}

- (void)viewWillLayoutSubviews {
    //NSLog(@"viewWillLayoutSubviews IDMPB  |  statusBarOrientation = %d", [[UIApplication sharedApplication] statusBarOrientation]);

	// Flag
	_performingLayout = YES;
    
    /*static BOOL isFirstViewLoad = YES;
    if(isFirstViewLoad) {
        // Toolbar
        _toolbar.frame = [self frameForToolbarFirstTimeAtOrientation:self.interfaceOrientation];
        
        // Done button
        _doneButton.frame = [self frameForDoneButtonFirstTimeAtOrientation:self.interfaceOrientation];

        isFirstViewLoad = NO;
    }
    else {
     // Toolbar
        _toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
        
        // Done button
        _doneButton.frame = [self frameForDoneButtonAtOrientation:self.interfaceOrientation];
    }*/
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;

    // Toolbar
    _toolbar.frame = [self frameForToolbarAtOrientation:currentOrientation];
    
    // Done button
    _doneButton.frame = [self frameForDoneButtonAtOrientation:currentOrientation];

    
    // Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
	_pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
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

- (void)performLayout {
    // Setup
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
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
    
    [self.view addGestureRecognizer:_panGesture];
}

#pragma mark - Interface Orientation

- (BOOL)shouldAutorotate
{
    //NSLog(@"before = %d  |  current = %d", _pageIndexBeforeRotation, _currentPageIndex);
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    //return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

/*- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    //return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}*/

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //NSLog(@"IDMPB willRotateToInterfaceOrientation");
    //NSLog(@"before = %d  |  current = %d", _pageIndexBeforeRotation, _currentPageIndex);

    // Remember page index before rotation
    _pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
    
    /*if ([self areControlsHidden]) {
        self.navigationController.navigationBarHidden = YES;
    }*/
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	_rotating = NO;
    
    /*if ([self areControlsHidden]) {
        self.navigationController.navigationBarHidden = NO;
        self.navigationController.navigationBar.alpha = 0;
    }*/
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //NSLog(@"IDMPB willAnimateRotationToInterfaceOrientation");
    //NSLog(@"before = %d  |  current = %d", _pageIndexBeforeRotation, _currentPageIndex);
    
    _currentPageIndex = _pageIndexBeforeRotation;
	
	// Delay control holding
	[self hideControlsAfterDelay];
}

#pragma mark - Data

- (void)reloadData {
    // Get data
    [self releaseAllUnderlyingPhotos];
    
    // Update
    [self performLayout];
    
    // Layout
    [self.view setNeedsLayout];
}

- (NSUInteger)numberOfPhotos {
    return _photos.count;
}

- (id<IDMPhoto>)photoAtIndex:(NSUInteger)index {
    return _photos[index];
}

- (IDMCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    IDMCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <IDMPhoto> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) captionView = [[IDMCaptionView alloc] initWithPhoto:photo];
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
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    IDMLog(@"Pre-loading image at index %i", pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <IDMPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    IDMLog(@"Pre-loading image at index %i", pageIndex+1);
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
			thePage = page; break;
		}
	}
	return thePage;
}

- (IDMZoomingScrollView *)pageDisplayingPhoto:(id<IDMPhoto>)photo {
	IDMZoomingScrollView *thePage = nil;
	for (IDMZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (void)configurePage:(IDMZoomingScrollView *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];
    
    __block __weak IDMPhoto *photo = (IDMPhoto*)page.photo;
    photo.progressUpdateBlock = ^(CGFloat progress){
        [page setProgress:progress forPhoto:photo];
    };
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
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    if ([_delegate respondsToSelector:@selector(photoBrowser:didShowPhotoAtIndex:)]) {
        [_delegate photoBrowser:self didShowPhotoAtIndex:index];
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
    CGFloat height = 44;
    
    if ([self isLandscape:orientation])
        height = 32;
    
    return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBound = self.view.bounds;
    CGFloat screenWidth = screenBound.size.width;
    
    // if ([self isLandscape:orientation]) screenWidth = screenBound.size.height;
    
    return CGRectMake(screenWidth - 75, 30, 55, 26);
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
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update toolbar when page changes
	if(! _arrowButtonsChangePhotosAnimated) [self updateToolbar];
}

#pragma mark - Toolbar

- (void)updateToolbar {
    // Counter
	if ([self numberOfPhotos] > 1) {
		_counterLabel.text = [NSString stringWithFormat:@"%i %@ %i", _currentPageIndex+1, IDMPhotoBrowserLocalizedStrings(@"of"), [self numberOfPhotos]];
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
    
    /*if (self.wantsFullScreenLayout) {
        // Status Bar
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            //[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
            [UIView animateWithDuration:0.3 animations:^(void) {
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:^(BOOL finished) {}];
        }
    }*/
    
    // Captions
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (IDMZoomingScrollView *page in _visiblePages) {
        if (page.captionView) [captionViews addObject:page.captionView];
    }
    
    // Hide/show bars
    [UIView animateWithDuration:(animated ? 0.35 : 0) animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        [self.navigationController.navigationBar setAlpha:alpha];
        [_toolbar setAlpha:alpha];
        [_doneButton setAlpha:alpha];
        for (UIView *v in captionViews) v.alpha = alpha;
    } completion:^(BOOL finished) {}];
	
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if they are visible
	if (!permanent) [self hideControlsAfterDelay];
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

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); }
- (void)hideControls      { if(_autoHide) [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls    { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }


#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    // Validate
    if (index >= [self numberOfPhotos]) index = [self numberOfPhotos]-1;
    _initalPageIndex = index;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) [self tilePages]; // Force tiling if view is not visible
    }
}

#pragma mark - Buttons

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
    
    if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
        if(!_actionButtonTitles)
        {
            // Activity view
            NSMutableArray *activityItems = [NSMutableArray arrayWithObject:[photo underlyingImage]];
            if (photo.caption) [activityItems addObject:photo.caption];
            
            self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            
            __typeof__(self) __weak selfBlock = self;
            [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
                [selfBlock hideControlsAfterDelay];
                selfBlock.activityViewController = nil;
            }];
            
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

#pragma mark - SVProgressHUD

- (void)showProgressHUDWithMessage:(NSString *)message {
    [SVProgressHUD showWithStatus:message];
}

- (void)hideProgressHUD:(BOOL)animated {
    [SVProgressHUD dismiss];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        [SVProgressHUD showSuccessWithStatus:message];
    } else {
        [SVProgressHUD dismiss];
    }
}

@end
