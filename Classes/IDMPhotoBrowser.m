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

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

// Private
@interface IDMPhotoBrowser () {
	// Data
    NSUInteger _photoCount;
    NSMutableArray *_newPhotos;
	NSMutableArray *_actionButtons;
    
    // Gesture
    UIPanGestureRecognizer *_panGesture;
    
	// Views
	UIScrollView *_pagingScrollView;
	
    // Done Button
    UIButton *_doneButton;
    
	// Paging
	NSMutableSet *_visiblePages, *_recycledPages;
	NSUInteger _pageIndexBeforeRotation;
    NSUInteger _currentPageIndex;
	
	// Navigation & controls
	UIToolbar *_toolbar;
	NSTimer *_controlVisibilityTimer;
	UIBarButtonItem *_previousButton, *_nextButton, *_actionButton;
    
    UIActionSheet *_actionsSheet;
    
    UIBarButtonItem *_counterButton;
    UILabel *_counterLabel;
    
    // Appearance
    UIStatusBarStyle _previousStatusBarStyle;
    
    // Present
    UIView *_senderViewForAnimation;
    
    // Misc
    BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _autoHide;
    BOOL _useDefaultActions;
    NSInteger _initalPageIndex;
    
    CGRect _resizableImageViewFrame;
    //UIImage *_backgroundScreenshot;
}

// Private Properties
@property (nonatomic, strong) UIActionSheet *actionsSheet;

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
- (CGRect)frameForCaptionView:(IDMCaptionView *)captionView atIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForToolbarWhenRotationFromOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForDoneButtonWhenRotationFromOrientation:(UIInterfaceOrientation)orientation;

// Navigation
- (void)updateNavigation;
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
@synthesize displayDoneButton = _displayDoneButton, displayToolbar = _displayToolbar, displayActionButton = _displayActionButton, displayCounterLabel = _displayCounterLabel, useWhiteBackgroundColor = _useWhiteBackgroundColor, doneBackgroundImage = _doneBackgroundImage;
@synthesize leftArrowImage = _leftArrowImage, rightArrowImage = _rightArrowImage, leftArrowSelectedImage = _leftArrowSelectedImage, rightArrowSelectedImage = _rightArrowSelectedImage;
@synthesize actionsSheet = _actionsSheet, displayArrowButton = _displayArrowButton, actionButtonTitles = _actionButtonTitles;
@synthesize delegate = _delegate;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        // Defaults
        self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;
        _photoCount = NSNotFound;
        _currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
		_rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [NSMutableSet new];
        _recycledPages = [NSMutableSet new];
        _newPhotos = [NSMutableArray new];

        _displayToolbar = YES;
        _autoHide = YES;
        _useDefaultActions = YES;
        _displayDoneButton = YES;
        _displayActionButton = YES;
        _displayArrowButton = YES;
        _displayCounterLabel = NO;
        _useWhiteBackgroundColor = NO;
        _leftArrowImage = _rightArrowImage = _leftArrowSelectedImage = _rightArrowSelectedImage = nil;
        _doneBackgroundImage = nil;
        _backgroundScaleFactor = 1.0;
        _animationDuration = 0.28;
        _senderViewForAnimation = nil;
        _scaleImage = nil;
        _initalPageIndex = 0;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        rootViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
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
		_newPhotos = [[NSMutableArray alloc] initWithArray:photosArray];
	}
	return self;
}

- (id)initWithPhotos:(NSArray *)photosArray animatedFromView:(UIView*)view;
{
    if ((self = [self init])) {
		_newPhotos = [[NSMutableArray alloc] initWithArray:photosArray];
        _senderViewForAnimation = view;
	}
	return self;
}

- (id)initWithPhotoURLs:(NSArray *)photoURLsArray {
    if ((self = [self init])) {
        NSArray *photosArray = [IDMPhoto photosWithURLs:photoURLsArray];
		_newPhotos = [[NSMutableArray alloc] initWithArray:photosArray];
	}
	return self;
}

- (id)initWithPhotoURLs:(NSArray *)photoURLsArray animatedFromView:(UIView*)view {
    if ((self = [self init])) {
        NSArray *photosArray = [IDMPhoto photosWithURLs:photoURLsArray];
		_newPhotos = [[NSMutableArray alloc] initWithArray:photosArray];        
        _senderViewForAnimation = view;
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos];
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _newPhotos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; } // Release photos
}

- (void)didReceiveMemoryWarning {
	// Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos];
	[_recycledPages removeAllObjects];
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - Pan Gesture

- (void)panGestureRecognized:(id)sender
{
    // Initial Setup
    IDMZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
    //IDMTapDetectingImageView *scrollView.photoImageView = scrollView.photoImageView;
    
    static float firstX, firstY;
    float viewHeight = scrollView.frame.size.height;
    float viewHalfHeight = viewHeight/2;
    
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    // Gesture Began
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan)
    {
        [self setControlsHidden:YES animated:YES permanent:YES];
        
        firstX = [scrollView center].x;
        firstY = [scrollView center].y;
        
        _senderViewForAnimation.hidden = NO;
        
        if (_currentPageIndex == _initalPageIndex)
            _senderViewForAnimation.hidden = YES;
        else
            _senderViewForAnimation.hidden = NO;
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
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded)
    {
        if(scrollView.center.y > viewHalfHeight+40 || scrollView.center.y < viewHalfHeight-40) // Automatic Dismiss View
        {
            if (_senderViewForAnimation != nil  && _currentPageIndex == _initalPageIndex) {
                [self performCloseAnimationWithScrollView:scrollView];
                return;
            }
            
            CGFloat finalX = firstX, finalY;
            
            CGFloat windowsHeigt = [[[[UIApplication sharedApplication] delegate] window] frame].size.height;
            
            if(scrollView.center.y > viewHalfHeight+30) // swipe down
                finalY = windowsHeigt*2;
            else // swipe up
                finalY = -viewHalfHeight;
            
            CGFloat animationDuration = 0.35;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
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
            [UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
            [scrollView setCenter:CGPointMake(finalX, finalY)];
            [UIView commitAnimations];
        }
    }
}

#pragma mark - View General

- (void)setSenderViewForAnimation:(UIView*)senderView{
    
    CGAffineTransform original = [[[UIApplication sharedApplication].delegate window] rootViewController].view.transform;
    
    [[[[UIApplication sharedApplication].delegate window] rootViewController].view setTransform:CGAffineTransformIdentity];
    _senderViewForAnimation.hidden = NO;
    
    _senderViewForAnimation = senderView;
    _resizableImageViewFrame = [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil];
    
    _senderViewForAnimation.hidden = YES;
    [[[[UIApplication sharedApplication].delegate window] rootViewController].view setTransform:original];
    
}

- (UIButton*)customButton:(UIImage*)image imageSelected:(UIImage*)selectedImage action:(SEL)action
{
    UIButton* nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextButton setBackgroundImage:image forState:UIControlStateNormal];
    [nextButton setBackgroundImage:selectedImage forState:UIControlStateDisabled];
    [nextButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [nextButton setContentMode:UIViewContentModeCenter];
    [nextButton setFrame:CGRectMake(0,0, image.size.width, image.size.height)];
    return nextButton;
}

- (UIImage *)getImageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 2); // 4);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static inline double radians (double degrees) {return degrees * M_PI/180;}
- (UIImage*) rotateImage:(UIImage*)src orientation:(UIImageOrientation) orientation
{
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (orientation == UIImageOrientationDown) {
        // notinhg
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}

/*- (UIImage*)takeScreenshot
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}*/

- (void)performAnimation
{
    UIImage *imageFromView = _scaleImage ? _scaleImage : [self getImageFromView:_senderViewForAnimation];
    
    _resizableImageViewFrame = [_senderViewForAnimation.superview convertRect:_senderViewForAnimation.frame toView:nil];
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;
    
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    fadeView.backgroundColor = [UIColor clearColor];
    [[[UIApplication sharedApplication].delegate window] addSubview:fadeView];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = _resizableImageViewFrame;
    resizableImageView.clipsToBounds = YES;
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor) ? 1 : 0 alpha:1];
    [[[UIApplication sharedApplication].delegate window] addSubview:resizableImageView];
    _senderViewForAnimation.hidden = YES;

    [UIView animateWithDuration:_animationDuration animations:^{
        CGAffineTransform zoom = CGAffineTransformScale(CGAffineTransformIdentity, _backgroundScaleFactor
                                                        , _backgroundScaleFactor);
        fadeView.backgroundColor = [UIColor blackColor];
        
        [[[[UIApplication sharedApplication].delegate window] rootViewController].view setTransform:zoom];

        float scaleFactor =  (imageFromView ? imageFromView.size.width : screenWidth) / screenWidth;
        
        resizableImageView.frame = CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2), screenWidth, imageFromView.size.height / scaleFactor);
    } completion:^(BOOL finished) {
        self.view.alpha = 1;
        resizableImageView.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor) ? 1 : 0 alpha:1];
        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];
    }];
}

- (void)performCloseAnimationWithScrollView:(IDMZoomingScrollView*)scrollView
{
    float fadeAlpha = 1 - abs(scrollView.frame.origin.y)/scrollView.frame.size.height;
    
    UIImage *imageFromView = [scrollView.photo underlyingImage];

    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    CGFloat screenHeight = screenBound.size.height;
    
    float scaleFactor = imageFromView.size.width / screenWidth;
    
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    fadeView.backgroundColor = [UIColor blackColor];
    fadeView.alpha = fadeAlpha;
    [[[UIApplication sharedApplication].delegate window] addSubview:fadeView];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2)+scrollView.frame.origin.y, screenWidth, imageFromView.size.height / scaleFactor);
    resizableImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    resizableImageView.clipsToBounds = YES;
    [[[UIApplication sharedApplication].delegate window] addSubview:resizableImageView];
    self.view.hidden = YES;
    
    [UIView animateWithDuration:_animationDuration animations:^{
        [[[[UIApplication sharedApplication].delegate window] rootViewController].view setTransform:CGAffineTransformIdentity];
        
        resizableImageView.layer.frame = _resizableImageViewFrame;
        fadeView.alpha = 0;
        self.view.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        _senderViewForAnimation.hidden = NO;
        _senderViewForAnimation = nil;
        _scaleImage = nil;
        
        [fadeView removeFromSuperview];
        [resizableImageView removeFromSuperview];
        
        [self doneButtonPressed:nil];
    }];
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
    if(_displayDoneButton) [self.view addSubview:_doneButton];
    
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
    
    if(_displayCounterLabel)
    {
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
	[self updateNavigation];
    
    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
    
    [self.view addGestureRecognizer:_panGesture];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    // Setup animation
    self.view.alpha = 0;
    
    [self performAnimation];
    
    /*if(!_senderViewForAnimation) // Default presentation (withoung animation)
    {
        //PB-TODO : test
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) // ios 7 or greater
            [UIView animateWithDuration:0.0 animations:^{ } completion:^(BOOL finished) {
                [UIView animateWithDuration:_animationDuration animations:^{ self.view.alpha = 1; }];
            }];
        else // ios 6 or less
            [UIView animateWithDuration:_animationDuration animations:^{ self.view.alpha = 1; }];
    }*/
    
    // View
	self.view.backgroundColor = [UIColor colorWithWhite:(_useWhiteBackgroundColor ? 1 : 0) alpha:1];
    
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor clearColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
    
    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    _toolbar.backgroundColor = [UIColor clearColor];
    _toolbar.clipsToBounds = YES;
    _toolbar.translucent = YES;
    [_toolbar setBackgroundImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny
                      barMetrics:UIBarMetricsDefault];
    
    // Close Button
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if(_doneBackgroundImage == nil)
    {
        _doneButton.layer.cornerRadius = 3.0f;
        _doneButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.9].CGColor;
        _doneButton.layer.borderWidth = 1.0f;
        [_doneButton setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
    }
    else
    {
        [_doneButton setBackgroundImage:_doneBackgroundImage forState:UIControlStateNormal];
    }
    
    [_doneButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal|UIControlStateHighlighted];
    [_doneButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    [_doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
    [_doneButton setFrame:[self frameForDoneButtonAtOrientation:self.interfaceOrientation]];
    [_doneButton setAlpha:1.0f];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *leftButtonImage = (_leftArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeft.png"] : _leftArrowImage;
    
    UIImage *rightButtonImage = (_rightArrowImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRight.png"] : _rightArrowImage;
    
    UIImage *leftButtonSelectedImage = (_leftArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeftSelected.png"] : _leftArrowSelectedImage;
    
    UIImage *rightButtonSelectedImage = (_rightArrowSelectedImage == nil) ?
    [UIImage imageNamed:@"IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRightSelected.png"] : _rightArrowSelectedImage;
    
    // Arrows
    _previousButton = [[UIBarButtonItem alloc] initWithCustomView:[self customButton:leftButtonImage
                                                                       imageSelected:leftButtonSelectedImage
                                                                              action:@selector(gotoPreviousPage)]];
    
    _nextButton = [[UIBarButtonItem alloc] initWithCustomView:[self customButton:rightButtonImage
                                                                   imageSelected:rightButtonSelectedImage
                                                                          action:@selector(gotoNextPage)]];
    
    // Counter Label
    _counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 40)];
    _counterLabel.textAlignment = NSTextAlignmentCenter;
    _counterLabel.backgroundColor = [UIColor clearColor];
    _counterLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    
    if(_useWhiteBackgroundColor)
    {
        _counterLabel.textColor = [UIColor blackColor];
    }
    else
    {
        _counterLabel.textColor = [UIColor whiteColor];
        _counterLabel.shadowColor = [UIColor darkTextColor];
        _counterLabel.shadowOffset = CGSizeMake(0, 1);
    }
    
    // Counter Button
    _counterButton = [[UIBarButtonItem alloc] initWithCustomView:_counterLabel];
    
    // Action Button
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                  action:@selector(actionButtonPressed:)];
    
    _useDefaultActions = _actionButtonTitles ? NO : YES;
    
    if(_useDefaultActions)
        _actionButtonTitles = [[NSMutableArray alloc] initWithArray:@[NSLocalizedString(@"Save", @"Save"), @"Email"]];
    
    // Gesture
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [_panGesture setMinimumNumberOfTouches:1];
    [_panGesture setMaximumNumberOfTouches:1];
    
    // Update
    [self reloadData];
    
	// Super
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    //_backgroundScreenshot = [self takeScreenshot];
    
    // Super
	[super viewWillAppear:animated];
	
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    }
    
    // Update UI
	[self hideControlsAfterDelay];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Controls
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }
    
	// Super
	[super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
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

#pragma mark - Layout

//BOOL isFirstViewLoad = YES;

- (void)viewWillLayoutSubviews
{
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
	
	// Flag
	_performingLayout = YES;
    
    //if(!isFirstViewLoad)
    {
        // Toolbar
        //_toolbar.frame = [self frameForToolbarWhenRotationFromOrientation:self.interfaceOrientation];
        _toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
        
        // Done button
        //_doneButton.frame = [self frameForDoneButtonWhenRotationFromOrientation:self.interfaceOrientation];
        _doneButton.frame = [self frameForDoneButtonAtOrientation:self.interfaceOrientation];
    }
    
    //if(isFirstViewLoad) isFirstViewLoad = NO;
    
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
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	// Remember page index before rotation
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	// Perform layout
	_currentPageIndex = _pageIndexBeforeRotation;
    
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
	
	// Delay control holding
	[self hideControlsAfterDelay];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	_rotating = NO;
}

#pragma mark - Data

- (void)reloadData {
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    [self releaseAllUnderlyingPhotos];
    
    // Update
    [self performLayout];
    
    // Layout
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
    else [self.view setNeedsLayout];
}

- (NSUInteger)numberOfPhotos
{
    return _newPhotos.count;
}

- (id<IDMPhoto>)photoAtIndex:(NSUInteger)index
{
    return _newPhotos[index];
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
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
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

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation))
        height = 32;
    
    return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForToolbarWhenRotationFromOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 32;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation))
        height = 44;
    
    return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation))
        screenWidth = screenBound.size.height;
    
    return CGRectMake(screenWidth - 55 - 20, 30, 55, 26);
}

- (CGRect)frameForDoneButtonWhenRotationFromOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.height;
    
    if (//UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation))
        screenWidth = screenBound.size.width;
    
    return CGRectMake(screenWidth - 55 - 20, 30, 55, 26);
}

- (CGRect)frameForCaptionView:(IDMCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    
    captionView.frame = CGRectMake(0, 0, pageFrame.size.width, 44); // set initial frame
    
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    
    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Checks
	if (!_viewIsActive || _performingLayout || _rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
	CGRect visibleBounds = _pagingScrollView.bounds;
	int index = (int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
	if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
	NSUInteger previousCurrentPage = _currentPageIndex;
	_currentPageIndex = index;
	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
	[self updateNavigation];
}

#pragma mark - Navigation

- (void)updateNavigation {
    // Counter
	if ([self numberOfPhotos] > 1) {
		_counterLabel.text = [NSString stringWithFormat:@"%i %@ %i", _currentPageIndex+1, NSLocalizedString(@"of", nil), [self numberOfPhotos]];
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
		_pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
		[self updateNavigation];
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
}

- (void)gotoPreviousPage { [self jumpToPageAtIndex:_currentPageIndex-1]; }
- (void)gotoNextPage { [self jumpToPageAtIndex:_currentPageIndex+1]; }

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    // Cancel any timers
    [self cancelControlHiding];
	
	// Status bar and nav bar positioning
    if (self.wantsFullScreenLayout) {
        // Status Bar
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            // iOS 7
            [self prefersStatusBarHidden];
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
            [[UIApplication sharedApplication] setStatusBarHidden:hidden
                                                    withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
        } else {
            // iOS 6
            [[UIApplication sharedApplication] setStatusBarHidden:hidden
                                                    withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
        }
    }
    
    // Captions
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (IDMZoomingScrollView *page in _visiblePages) {
        if (page.captionView) [captionViews addObject:page.captionView];
    }
	
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    
    CGFloat alpha = hidden ? 0 : 1;
	[_toolbar setAlpha:alpha];
    [_doneButton setAlpha:alpha];
    for (UIView *v in captionViews) v.alpha = alpha;
	if (animated) [UIView commitAnimations];
	
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if
	// they are visible
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

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); /* [UIApplication sharedApplication].isStatusBarHidden; */ }
- (void)hideControls { if(_autoHide) [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }


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

- (void)doneButtonPressed:(id)sender
{
    // Status Bar
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } else {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    
    // Gesture
    [[[[UIApplication sharedApplication] delegate] window] removeGestureRecognizer:_panGesture];
    
    _autoHide = NO;
    
    if (_senderViewForAnimation && _currentPageIndex == _initalPageIndex) {
        IDMZoomingScrollView *scrollView = [self pageDisplayedAtIndex:_currentPageIndex];
        [self performCloseAnimationWithScrollView:scrollView];
    }
    
    [self dismissViewControllerAnimated:[sender isKindOfClass:[UIButton class]] completion:^{
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDismissAtPageIndex:)])
            [_delegate photoBrowser:self didDismissAtPageIndex:_currentPageIndex];
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        rootViewController.modalPresentationStyle = 0;
    }];
}

- (void)actionButtonPressed:(id)sender {
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
    } else {
        id <IDMPhoto> photo = [self photoAtIndex:_currentPageIndex];
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            
            // Keep controls hidden
            [self setControlsHidden:NO animated:YES permanent:YES];
            
            // Action sheet
            self.actionsSheet = [UIActionSheet new];
            self.actionsSheet.delegate = self;
            for(NSString *action in _actionButtonTitles) {
                [self.actionsSheet addButtonWithTitle:action];
            }
            
            self.actionsSheet.cancelButtonIndex = [self.actionsSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            self.actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [_actionsSheet showFromBarButtonItem:sender animated:YES];
            } else {
                [_actionsSheet showInView:self.view];
            }
        }
    }
}


#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        self.actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if(_useDefaultActions)
            {
                if(buttonIndex == 0) {
                    [self savePhoto]; return;
                } else if(buttonIndex == 1) {
                    [self emailPhoto];  return;
                }
            }
            else
            {
                if ([_delegate respondsToSelector:@selector(photoBrowser:didDismissActionSheetWithButtonIndex:photoIndex:)])
                    [_delegate photoBrowser:self didDismissActionSheetWithButtonIndex:buttonIndex photoIndex:_currentPageIndex];
            }
        }
    }
    
    [self hideControlsAfterDelay]; // Continue as normal...
}


#pragma mark - Actions

- (void)savePhoto {
    id <IDMPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Saving", @"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<IDMPhoto>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"Failed", @"Informing the user a process has failed") : NSLocalizedString(@"Saved", @"Informing the user an item has been saved")];
    [self hideControlsAfterDelay]; // Continue as normal...
}

- (void)emailPhoto {
    id <IDMPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Preparing", @"Displayed with ellipsis as 'Preparing...' when an item is in the process of being prepared")]];
        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyEmailPhoto:(id<IDMPhoto>)photo {
    if ([photo underlyingImage]) {
        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
        emailer.mailComposeDelegate = self;
        [emailer setSubject:NSLocalizedString(@"Photo", nil)];
        [emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self presentModalViewController:emailer animated:YES];
        [self hideProgressHUD:NO];
    }
}

#pragma mark Mail Compose Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
                                                         message:NSLocalizedString(@"Email failed to send. Please try again.", nil)
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
    }
	[self dismissModalViewControllerAnimated:YES];
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
