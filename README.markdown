# IDMPhotoBrowser

IDMPhotoBrowser is a new implementation based on [MWPhotoBrowser](https://github.com/mwaterfall/MWPhotoBrowser).

We've added both user experience and technical features inspired by Facebook's and Tweetbot's photo browsers.

## New features:
- Uses ARC
- Uses AFNetworking for image loading
- Image progress shown
- Minimalistic Facebook-like interface, swipe up to dismiss
- Ability to add custom actions on the action sheet

## Features

- Can display one or more images by providing either `UIImage` objects, file paths to images on the device, or URLs to images online
- Handles the downloading and caching of photos from the web seamlessly
- Photos can be zoomed and panned, and optional captions can be displayed

## Usage

See the code snippet below for an example of how to implement the photo browser.

    // URLs array
    NSArray *photosURL = @[[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"], [NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"], [NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"], [NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]];
    
    // Create an array to store IDMPhoto objects
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    for (NSURL *url in photosURL) {
    	IDMPhoto *photo = [IDMPhoto photoWithURL:url];
    	[photos addObject:photo];
    }
    
    // Create and setup browser
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    /* You can customize the toolbar:
     * There are two boolean properties you can set: displayActionButton and displayArrowButton;
     * If you dont want the toolbar at all, you can set displayToolbar = NO.
     */
     
    browser.displayActionButton = YES;
	browser.displayArrowButton = YES;
    
    /* If you want to use custom action:
     * Just set the array actionButtonTitles with the titles for the actionSheet;
     * And then implement the method photoBrowser:didDismissActionSheetWithButtonIndex:, from the IDMPhotoBrowser delegate
     */
    browser.actionButtonTitles = @[@"Option 1", @"Option 2", @"Option 3", @"Option 4"];
    
    // Show
    self.modalPresentationStyle = self.navigationController.modalPresentationStyle = self.tabBarController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self presentModalViewController:browser animated:YES];


### Photo Captions

Photo captions can be displayed simply by setting the `caption` property on specific photos:

    IDMPhoto *photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
    photo.caption = @"Campervan";

No caption will be displayed if the caption property is not set.

#### Custom Captions

By default, the caption is a simple black transparent view with a label displaying the photo's caption in white. If you want to implement your own caption view, follow these steps:

1. Optionally use a subclass of `IDMPhoto` for your photos so you can store more data than a simple caption string.
2. Subclass `IDMCaptionView` and override `-setupCaption` and `-sizeThatFits:` (and any other UIView methods you see fit) to layout your own view and set it's size. More information on this can be found in `IDMCaptionView.h`
3. Implement the `-photoBrowser:captionViewForPhotoAtIndex:` IDMPhotoBrowser delegate method (shown below).

Example delegate method for custom caption view:

    - (IDMCaptionView *)photoBrowser:(IDMPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
        IDMPhoto *photo = [self.photos objectAtIndex:index];
        MyIDMCaptionViewSubclass *captionView = [[MyIDMCaptionViewSubclass alloc] initWithPhoto:photo];
        return [captionView autorelease];
    }


## Adding to your project

### Using CocoaPods

Just add `pod 'IDMPhotoBrowser'` to your Podfile.

### Including Source Directly Into Your Project

Simply add the files inside `IDMPhotoBrowser/Classes` to your Xcode project, copying them to your project's directory if required.

### Opensource libraries used

- [AFNetWorking](https://github.com/AFNetworking/AFNetworking)
- [DACircularProgress](https://github.com/danielamitay/DACircularProgress)
- [SVProgressHUD](https://github.com/samvermette/SVProgressHUD)

## Licence

This project uses MIT License.
