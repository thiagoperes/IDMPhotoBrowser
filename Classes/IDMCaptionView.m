//
//  IDMCaptionView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IDMCaptionView.h"
#import "IDMPhoto.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat labelPadding = 10;

// Private
@interface IDMCaptionView () {
    id<IDMPhoto> _photo;
    UILabel *_label;    
}
@end

@implementation IDMCaptionView

- (id)initWithPhoto:(id<IDMPhoto>)photo {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenBound.size.height;
    }
    
    self = [super initWithFrame:CGRectMake(0, 0, screenWidth, 44)]; // Random initial frame
    if (self) {
        _photo = photo;
        self.opaque = NO;
        
        [self setBackground];
        
        [self setupCaption];
    }
    
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = 9999;
    if (_label.numberOfLines > 0) maxHeight = _label.font.leading*_label.numberOfLines;
    CGSize textSize = [_label.text sizeWithFont:_label.font 
                              constrainedToSize:CGSizeMake(size.width - labelPadding*2, maxHeight)
                                  lineBreakMode:_label.lineBreakMode];
    return CGSizeMake(size.width, textSize.height + labelPadding * 2);
}

- (void)setupCaption {
    _label = [[UILabel alloc] initWithFrame:CGRectMake(labelPadding, 0, 
                                                       self.bounds.size.width-labelPadding*2,
                                                       self.bounds.size.height)];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.opaque = NO;
    _label.backgroundColor = [UIColor clearColor];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.numberOfLines = 3;
    _label.textColor = [UIColor whiteColor];
    _label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    _label.shadowOffset = CGSizeMake(0, 1);
    _label.font = [UIFont systemFontOfSize:17];
    if ([_photo respondsToSelector:@selector(caption)]) {
        _label.text = [_photo caption] ? [_photo caption] : @" ";
    }
    
    [self addSubview:_label];
}

- (void)setBackground {
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, 10000, 130+100)]; // Static width, autoresizingMask is not working
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = fadeView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:0.8] CGColor], nil];
    [fadeView.layer insertSublayer:gradient atIndex:0];
    fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; //UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:fadeView];
}

@end
