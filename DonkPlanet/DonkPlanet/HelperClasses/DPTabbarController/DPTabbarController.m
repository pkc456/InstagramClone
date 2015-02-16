//
//  DPTabbarController.m
//  DonkPlanet
//
//  Created by Varun on 4/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "DPTabbarController.h"
#import "CameraViewController.h"

@interface DPTabbarController () <UITabBarControllerDelegate>

@end

@implementation DPTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.lastSelectedTab = 0;
    [self setDelegate:self];
    [self setImagesForTabbar];
}

- (void)setImagesForTabbar {
    NSArray *imageUnselected = @[@"homeUnsel", @"searchUnsel",
                                 @"cameraUnsel", @"heartUnsel", @"userUnsel"];
    for (int i = 0; i < [imageUnselected count]; i ++) {
        NSString *imageName = [imageUnselected objectAtIndex:i];
        UITabBarItem *tabBarItem = [self.tabBar.items objectAtIndex:i];
        
        [tabBarItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
        
        UIImage* unselectedImage = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem.image = unselectedImage;
    }
    
    NSArray *imageSelected = @[@"homeSel", @"searchSel",
                               @"cameraSel", @"heartSel", @"userSel"];
    for (int i = 0; i < [imageSelected count]; i ++) {
        NSString *imageName = [imageSelected objectAtIndex:i];
        UITabBarItem *tabBarItem = [self.tabBar.items objectAtIndex:i];
        
        [tabBarItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
        
        UIImage* selectedImage = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem.selectedImage = selectedImage;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TabbarController Delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    
    UINavigationController *selectedNavController = (UINavigationController *)viewController;
    UIViewController *viewControllerAtTop = [selectedNavController topViewController];
    
    BOOL hideStatusBar = NO;
    
    if ([viewControllerAtTop isKindOfClass:[CameraViewController class]])
        hideStatusBar = YES;
    else
        self.lastSelectedTab = tabBarController.selectedIndex;
    
    [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar
                                            withAnimation:UIStatusBarAnimationSlide];
    [self.tabBar setHidden:hideStatusBar];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
