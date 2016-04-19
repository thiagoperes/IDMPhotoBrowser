# IDMPhotoBrowser ![](http://cocoapod-badges.herokuapp.com/v/IDMPhotoBrowser/badge.png) ![](http://cocoapod-badges.herokuapp.com/p/IDMPhotoBrowser/badge.png)

IDMPhotoBrowser is a new implementation based on [MWPhotoBrowser](https://github.com/mwaterfall/MWPhotoBrowser).

We've added both user experience and technical features inspired by Facebook's and Tweetbot's photo browsers.

## New features:
- Uses ARC
- Uses SDWebImage for image loading
- Image progress shown
- Minimalistic Facebook-like interface, swipe up/down to dismiss
- Ability to add custom actions on the action sheet

## Features

- Can display one or more images by providing either `UIImage` objects, file paths to images on the device, or URLs to images online
- Handles the downloading and caching of photos from the web seamlessly
- Photos can be zoomed and panned, and optional captions can be displayed

## Screenshots

[![Alt][screenshot1_thumb]][screenshot1]    [![Alt][screenshot2_thumb]][screenshot2]    [![Alt][screenshot3_thumb]][screenshot3]    [![Alt][screenshot4_thumb]][screenshot4]    [![Alt][screenshot5_thumb]][screenshot5]
[screenshot1_thumb]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_thumb1.png
[screenshot1]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_ss1.png
[screenshot2_thumb]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_thumb2.png
[screenshot2]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_ss2.png
[screenshot3_thumb]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_thumb3.png
[screenshot3]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_ss3.png
[screenshot4_thumb]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_thumb4.png
[screenshot4]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_ss4.png
[screenshot5_thumb]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_thumb5.png
[screenshot5]: https://raw.github.com/appkraft/IDMPhotoBrowser/master/Screenshots/idmphotobrowser_ss5.png

## Usage

See the code snippet below for an example of how to implement the photo browser.

First create a photos array containing IDMPhoto objects:

``` objective-c
// URLs array
NSArray *photosURL = @[[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"], 
[NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"], 
[NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"], 
[NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]];
    
// Create an array to store IDMPhoto objects
NSMutableArray *photos = [NSMutableArray new];

for (NSURL *url in photosURL) {
	IDMPhoto *photo = [IDMPhoto photoWithURL:url];
	[photos addObject:photo];
}
	
// Or use this constructor to receive an NSArray of IDMPhoto objects from your NSURL objects
NSArray *photos = [IDMPhoto photosWithURLs:photosURL];
````

There are two main ways to presente the photoBrowser, with a fade on screen or with a zooming effect from an existing view.

Using a simple fade transition:

``` objective-c    
IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
``` 

Zooming effect from a view:

``` objective-c    
IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:sender];
```

When using this animation you can set the `scaleImage` property, in case the image from the view is not the same as the one that will be shown on the browser, so it will dynamically scale it:

``` objective-c    
browser.scaleImage = buttonSender.currentImage;
```

Presenting using a modal view controller:

``` objective-c
[self presentViewController:browser animated:YES completion:nil];
```

### Customization

##### Toolbar

You can customize the toolbar. There are three boolean properties you can set: displayActionButton (default is YES), displayArrowButton (default is YES) and displayCounterLabel (default is NO). If you dont want the toolbar at all, you can set displayToolbar = NO.

Toolbar setup example:
``` objective-c     
browser.displayActionButton = NO;
browser.displayArrowButton = YES;
browser.displayCounterLabel = YES;
```

It is possible to use your own image on the toolbar arrows:
``` objective-c     
browser.leftArrowImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeft.png"];
browser.rightArrowImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRight.png"];
browser.leftArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeftSelected.png"];
browser.rightArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRightSelected.png"];
```

If you want to use custom actions, set the actionButtonTitles array with the titles for the actionSheet. Then, implement the photoBrowser:didDismissActionSheetWithButtonIndex:photoIndex: method, from the IDMPhotoBrowser delegate

``` objective-c    
browser.actionButtonTitles = @[@"Option 1", @"Option 2", @"Option 3", @"Option 4"];
```

#### Others

Others customizations you can make are: use white background color, don't display the done button and change the done button background image:
``` objective-c    
browser.useWhiteBackgroundColor = YES;
browser.displayDoneButton = NO;
browser.doneBackgroundImage = [UIImage imageNamed:@"IDMPhotoBrowser_customDoneButton.png"];
```

If you want to keep the interface shown when the user is scrolling :
``` objective-c
browser.autoHideInterface = NO;
```

You can use a smooth [pop](https://github.com/facebook/pop) animation when presenting and dismissing a photo:
``` objective-c
browser.usePopAnimation = YES;
```

If the presenting view controller doesn't have a status bar, in some cases you can force it to be hidden:
``` objective-c
browser.forceHideStatusBar = YES;
```

It's possible to disable the vertical dismiss swipe gesture:
``` objective-c
browser.disableVerticalSwipe = YES;
```

### Photo Captions

Photo captions can be displayed simply by setting the `caption` property on specific photos:
``` objective-c
IDMPhoto *photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
photo.caption = @"Campervan";
```

No caption will be displayed if the caption property is not set.

#### Custom Captions

By default, the caption is a simple black transparent view with a label displaying the photo's caption in white. If you want to implement your own caption view, follow these steps:

1. Optionally use a subclass of `IDMPhoto` for your photos so you can store more data than a simple caption string.
2. Subclass `IDMCaptionView` and override `-setupCaption` and `-sizeThatFits:` (and any other UIView methods you see fit) to layout your own view and set it's size. More information on this can be found in `IDMCaptionView.h`
3. Implement the `-photoBrowser:captionViewForPhotoAtIndex:` IDMPhotoBrowser delegate method (shown below).

Example delegate method for custom caption view:
``` objective-c
- (IDMCaptionView *)photoBrowser:(IDMPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
	IDMPhoto *photo = [self.photos objectAtIndex:index];
	MyIDMCaptionViewSubclass *captionView = [[MyIDMCaptionViewSubclass alloc] initWithPhoto:photo];
	return captionView;
}
```

## Adding to your project

### Using CocoaPods

Just add `pod 'IDMPhotoBrowser'` to your Podfile.

### Including Source Directly Into Your Project

#### Opensource libraries used

- [SDWebImage](https://github.com/rs/SDWebImage)
- [DACircularProgress](https://github.com/danielamitay/DACircularProgress)
- [pop](https://github.com/facebook/pop)

## Licence

This project uses MIT License.
