//
//  MyPhotoBrowser.m
//  PhotoBrowserDemo
//
//  Created by Fedya Skitsko on 06.08.13.
//
//

#import "MyPhotoBrowser.h"

@interface MyPhotoBrowser ()

@end

@implementation MyPhotoBrowser

-(id)init{
    self = [super init];
    
    if(self){
//        self.displayDoneButton = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIBarButtonItem *customizationButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(buttonPressed:)];
    customizationButton.tag = 1;
    [self addTopToolBarItem:customizationButton];

    
    UIBarButtonItem *customizationButton2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(buttonPressed:)];
    customizationButton2.tag = 2;
    [self addToolBarItem:customizationButton2 atPosition:0];
}

-(void)buttonPressed:(UIBarButtonItem *)button{
    NSLog(@"Custom button pressed (barButton) %i", button.tag);
}

@end
