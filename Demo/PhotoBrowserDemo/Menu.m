//
//  Menu.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "Menu.h"

@implementation Menu

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
		self.title = @"IDMPhotoBrowser";
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [self setupTableViewFooterView];
}

#pragma mark - Rotation

/*- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIDeviceOrientationPortrait | UIDeviceOrientationLandscapeLeft | UIDeviceOrientationLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}*/

#pragma mark - General

- (void)setupTableViewFooterView
{
    UIView *tableViewFooter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 426 * 0.9 + 40)];

    UIButton *buttonWithImageOnScreen1 = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonWithImageOnScreen1.frame = CGRectMake(15, 0, 640/3 * 0.9, 426/2 * 0.9);
    buttonWithImageOnScreen1.tag = 101;
    buttonWithImageOnScreen1.adjustsImageWhenHighlighted = NO;
    [buttonWithImageOnScreen1 setImage:[UIImage imageNamed:@"photo1m.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen1.imageView.contentMode = UIViewContentModeScaleAspectFill;
    buttonWithImageOnScreen1.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen1 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tableViewFooter addSubview:buttonWithImageOnScreen1];
    
    UIButton *buttonWithImageOnScreen2 = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonWithImageOnScreen2.frame = CGRectMake(15, 426/2 * 0.9 + 20, 640/2 * 0.9, 426/2 * 0.9);
    buttonWithImageOnScreen2.tag = 102;
    buttonWithImageOnScreen2.adjustsImageWhenHighlighted = NO;
    [buttonWithImageOnScreen2 setImage:[UIImage imageNamed:@"photo3m.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen2.imageView.contentMode = UIViewContentModeScaleAspectFit;
    buttonWithImageOnScreen2.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen2 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tableViewFooter addSubview:buttonWithImageOnScreen2];
    
    self.tableView.tableFooterView = tableViewFooter;
}

#pragma mark - Actions

- (void)buttonWithImageOnScreenPressed:(id)sender
{
    UIButton *buttonSender = (UIButton*)sender;
    
    // Create an array to store IDMPhoto objects
    NSMutableArray *photos = [NSMutableArray new];
    
    IDMPhoto *photo;
    
    if(buttonSender.tag == 101)
    {
        photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"]];
        photo.caption = @"Grotto of the Madonna";
        [photos addObject:photo];
    }
    
    photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo3l" ofType:@"jpg"]];
    photo.caption = @"York Floods";
    [photos addObject:photo];
    
    photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
    photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
    [photos addObject:photo];
    
    photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo4l" ofType:@"jpg"]];
    photo.caption = @"Campervan";
    [photos addObject:photo];
    
    if(buttonSender.tag == 102)
    {
        photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"]];
        photo.caption = @"Grotto of the Madonna";
        [photos addObject:photo];
    }
    
    // Create and setup browser
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:sender]; // using initWithPhotos:animatedFromView: method to use the zoom-in animation
    browser.delegate = self;
    browser.displayActionButton = NO;
    browser.displayArrowButton = YES;
    browser.displayCounterLabel = YES;
    browser.scaleImage = buttonSender.currentImage;
    
    // Show
    [self presentViewController:browser animated:YES completion:nil];
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    if(section == 0)
        rows = 1;
    else if(section == 1)
        rows = 3;
    else if(section == 2)
        rows = 0;
    
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    
    if(section == 0)
        title = @"Single photo";
    else if(section == 1)
        title = @"Multiple photos";
    else if(section == 2)
        title = @"Photos on screen";
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Create
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure
    if(indexPath.section == 0)
    {
        cell.textLabel.text = @"Local photo";
    }
    else if(indexPath.section == 1)
    {
        if(indexPath.row == 0)
            cell.textLabel.text = @"Local photos";
        else if(indexPath.row == 1)
            cell.textLabel.text = @"Photos from Flickr";
        else if(indexPath.row == 2)
            cell.textLabel.text = @"Photos from Flickr - Custom";
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Create an array to store IDMPhoto objects
	NSMutableArray *photos = [NSMutableArray new];
    
    IDMPhoto *photo;
    
    if(indexPath.section == 0) // Local photo
    {
        photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
        photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
        [photos addObject:photo];
	}
    else if(indexPath.section == 1) // Multiple photos
    {
        if(indexPath.row == 0) // Local Photos
        {
            photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"]];
            photo.caption = @"Grotto of the Madonna";
			[photos addObject:photo];
           
            photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
			[photos addObject:photo];
            
            photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo3l" ofType:@"jpg"]];
            photo.caption = @"York Floods";
			[photos addObject:photo];
            
            photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo4l" ofType:@"jpg"]];
            photo.caption = @"Campervan";
			[photos addObject:photo];
        }
        else if(indexPath.row == 1 || indexPath.row == 2) // Photos from Flickr or Flickr - Custom
        {
            NSArray *photosWithURL = [IDMPhoto photosWithURLs:[NSArray arrayWithObjects:[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"], @"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg", [NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"], @"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg", nil]];
            
            photos = [NSMutableArray arrayWithArray:photosWithURL];
        }
    }
    
    // Create and setup browser
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    
    if(indexPath.section == 1) // Multiple photos
    {
        if(indexPath.row == 1) // Photos from Flickr
        {
            browser.displayCounterLabel = YES;
            browser.displayActionButton = NO;
        }
        else if(indexPath.row == 2) // Photos from Flickr - Custom
        {
            browser.actionButtonTitles      = @[@"Option 1", @"Option 2", @"Option 3", @"Option 4"];
            browser.displayCounterLabel     = YES;
            browser.useWhiteBackgroundColor = YES;
            browser.leftArrowImage          = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeft.png"];
            browser.rightArrowImage         = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRight.png"];
            browser.leftArrowSelectedImage  = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeftSelected.png"];
            browser.rightArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRightSelected.png"];
            browser.doneButtonImage         = [UIImage imageNamed:@"IDMPhotoBrowser_customDoneButton.png"];
            browser.view          = [UIColor orangeColor];
            browser.progressTintColor       = [UIColor orangeColor];
            browser.trackTintColor          = [UIColor colorWithWhite:0.8 alpha:1];
        }
    }
    
    // Show
    [self presentViewController:browser animated:YES completion:nil];
    //[self.navigationController pushViewController:browser animated:YES];
    
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IDMPhotoBrowser Delegate

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index
{
    id <IDMPhoto> photo = [photoBrowser photoAtIndex:index];
    NSLog(@"Dissmised with photo index: %d, photo caption: %@", index, photo.caption);
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissActionSheetWithButtonIndex:(NSUInteger)buttonIndex photoIndex:(NSUInteger)photoIndex
{
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Option %d", buttonIndex+1] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    id <IDMPhoto> photo = [photoBrowser photoAtIndex:photoIndex];
    NSLog(@"Dissmised actionSheet with photo index: %d, photo caption: %@", photoIndex, photo.caption);
}

@end
