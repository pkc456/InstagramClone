//
//  CommonFunctions.h
//  DonkPlanet
//
//  Created by Varun on 26/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, Device) {
    iPhone4,
    iPhone5
};

typedef NS_ENUM(NSUInteger, MyiOS) {
    iOS6,
    iOS7
};

typedef NS_ENUM(NSUInteger, PostType) {
    PostTypeImage,
    PostTypeVideo
};

typedef NS_ENUM(NSUInteger, FollowType) {
    TypeFollow,
    TypeFollowing,
    TypeFollowed
};

@interface DPFunctions : NSObject {
    CGRect screenRect;
}

#pragma mark - Shared Instance

+ (id)sharedObject;

#pragma mark - Device Methods

- (Device)currentDevice;
- (MyiOS)currentiOS;

#pragma mark - App Methods

- (UIColor *)colorWithR:(int)red g:(int)green b:(int)blue alpha:(float)alpha;
- (UIImageView *)leftViewForTextFieldWithImage:(NSString *)imageName;
- (BOOL)validateEmail:(NSString *)email;
- (UIView *)showLoadingViewWithText:(NSString *)strMessage inView:(UIView *)view;
- (void)hideLoadingView:(UIView *)loadingView;

- (NSString *)setTimeElapsedForDate:(NSDate *)startDate;

@end
