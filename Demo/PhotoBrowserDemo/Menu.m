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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    // Create a button with and image to be shown on screen
    UIButton *buttonWithImageOnScreen = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonWithImageOnScreen.frame = CGRectMake(15 + ((screenWidth > 320) ? 34 : 0), 270+8, 200, 200);
    buttonWithImageOnScreen.tag = 101;
    [buttonWithImageOnScreen setImage:[UIImage imageNamed:@"photo1m.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen.imageView.contentMode = UIViewContentModeScaleAspectFit;
    buttonWithImageOnScreen.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonWithImageOnScreen];
    
    UIButton *buttonWithImageOnScreen2 = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonWithImageOnScreen2.frame = CGRectMake(15 + ((screenWidth > 320) ? 34 : 0), 270+8+220, 200, 200);
    buttonWithImageOnScreen2.tag = 102;
    [buttonWithImageOnScreen2 setImage:[UIImage imageNamed:@"photo2m.jpg"] forState:UIControlStateNormal];
    buttonWithImageOnScreen2.imageView.contentMode = UIViewContentModeScaleAspectFit;
    buttonWithImageOnScreen2.backgroundColor = [UIColor blackColor];
    [buttonWithImageOnScreen2 addTarget:self action:@selector(buttonWithImageOnScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonWithImageOnScreen2];
}

- (void)buttonWithImageOnScreenPressed:(id)sender
{
    UIButton *buttonSender = (UIButton*)sender;
    
    // Create an array to store IDMPhoto objects
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    IDMPhoto *photo;
    if(buttonSender.tag == 101)
    {
        photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo1l" ofType:@"jpg"]];
        photo.caption = @"Grotto of the Madonna";
        [photos addObject:photo];
    }
    photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
    photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
    [photos addObject:photo];
    photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo3l" ofType:@"jpg"]];
    photo.caption = @"York Floods";
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
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:sender]; // using method initWithPhotos:animatedFromView: method to use the zoom-in animation
    browser.delegate = self;
    browser.displayActionButton = YES;
    browser.displayArrowButton = YES;
    browser.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Show
    self.modalPresentationStyle = self.navigationController.modalPresentationStyle = self.tabBarController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentModalViewController:browser animated:YES];
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rows = 0;
    
    if(section == 0)
        rows = 1;
    else if(section == 1)
        rows = 2;
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
        title = @"Images showing on screen";
    
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
        cell.textLabel.text = @"Local photos";
    }
    else if(indexPath.section == 1)
    {
        if(indexPath.row == 0)
            cell.textLabel.text = @"Local photos";
        else if(indexPath.row == 1)
            cell.textLabel.text = @"Photos from Flickr";
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 2) {
        return 440;
    }
    
    return 0;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Create an array to store IDMPhoto objects
	NSMutableArray *photos = [[NSMutableArray alloc] init];

    IDMPhoto *photo;
    if(indexPath.section == 0)
    {
        photo = [IDMPhoto photoWithFilePath:[[NSBundle mainBundle] pathForResource:@"photo2l" ofType:@"jpg"]];
        photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";
        [photos addObject:photo];
	}
    else if(indexPath.section == 1)
    {
        if(indexPath.row == 0)
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
        else if(indexPath.row == 1)
        {
			[photos addObject:[IDMPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"]]];
			[photos addObject:[IDMPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"]]];
			[photos addObject:[IDMPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"]]];
			[photos addObject:[IDMPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]]];
        }
    }
    
    // Create and setup browser
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    browser.displayActionButton = YES;
    browser.displayArrowButton = YES;
    browser.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if(indexPath.section == 1 && indexPath.row == 1) // 'Photos from Flickr' using custom action
        browser.actionButtonTitles = @[@"Option 1", @"Option 2", @"Option 3", @"Option 4"];
    
    // Show
    self.modalPresentationStyle = self.navigationController.modalPresentationStyle = self.tabBarController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentModalViewController:browser animated:YES];
    
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IDMPhotoBrowser Delegate

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissActionSheetWithButtonIndex:(NSUInteger)index
{
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Option %d", index+1] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end

