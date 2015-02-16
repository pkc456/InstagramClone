//
//  CommonFunctions.m
//  DonkPlanet
//
//  Created by Varun on 26/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "DPFunctions.h"

@implementation DPFunctions

#pragma mark - Shared Instance

+ (id)sharedObject {
    static DPFunctions *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Init Method

- (id)init {
    self = [super init];
    if (self) {
        screenRect = [UIScreen mainScreen].bounds;
    }
    return self;
}

#pragma mark - Device Methods

- (Device)currentDevice {
    return ((screenRect.size.height >= 568) ? iPhone5 : iPhone4);
}

- (MyiOS)currentiOS {
    return (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) ? iOS7 : iOS7);
}

- (CGRect)screenRect {
    return [UIScreen mainScreen].bounds;
}

#pragma mark - App Methods

- (UIColor *)colorWithR:(int)red g:(int)green b:(int)blue alpha:(float)alpha {
    return [UIColor colorWithRed:red/255.0f
                           green:green/255.0f
                            blue:blue/255.0f
                           alpha:alpha];
}

- (UIImageView *)leftViewForTextFieldWithImage:(NSString *)imageName {

    UIImage *imageForLeftMode = [UIImage imageNamed:imageName];
    
    UIImageView *imgViewLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    [imgViewLeft setImage:imageForLeftMode];
    [imgViewLeft setContentMode:UIViewContentModeCenter];
    
    return imgViewLeft;
}

- (BOOL)validateEmail:(NSString *)email {
    
    NSString *emailRegEx=@"[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest=[NSPredicate predicateWithFormat:@"SELF MATCHES  %@",emailRegEx];
    return [emailTest evaluateWithObject:email];
}

- (UIView *)showLoadingViewWithText:(NSString *)strMessage inView:(UIView *)view {
    
    if (!strMessage || !strMessage.length)
        strMessage = @"Loading";
    
    CGSize scrSize = screenRect.size;
    UIView *viewBackGround = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrSize.width, scrSize.height)];
    
    [viewBackGround setBackgroundColor:[UIColor clearColor]];
    [viewBackGround setTag:100];

    UIView *viewWhite = [[UIView alloc] initWithFrame:CGRectMake(90, 100, 120, 110)];
    [viewWhite setTag:200];
    [viewWhite setCenter:CGPointMake(scrSize.width/2, scrSize.height/2 - 30)];
    [viewWhite setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.9f]];
    [viewBackGround addSubview:viewWhite];
    
    [viewWhite.layer setCornerRadius:6.0f];
    [viewWhite.layer setBorderColor:[self colorWithR:49 g:190 b:218 alpha:0.5f].CGColor];
    [viewWhite.layer setBorderWidth:1.0f];
    
    [GMDCircleLoader setOnView:viewWhite withTitle:strMessage animated:YES];
    
    viewWhite = nil;
    [view addSubview:viewBackGround];
    
    return viewBackGround;
}

- (void)hideLoadingView:(UIView *)loadingView {
    
    UIView *viewWhite = [loadingView viewWithTag:200];
    [GMDCircleLoader hideFromView:viewWhite animated:YES];
    [[loadingView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [loadingView removeFromSuperview];
    loadingView = nil;
}

@end
