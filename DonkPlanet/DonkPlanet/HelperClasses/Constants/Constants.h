//
//  Constants.h
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _DPFunctions [DPFunctions sharedObject]
#define _DPAppDlgate (AppDelegate *)[[UIApplication sharedApplication] delegate]
#define _DPUserDefs  [NSUserDefaults standardUserDefaults]

@interface Constants : NSObject

//  Controller Storyboard IDs

FOUNDATION_EXPORT NSString *const _DP_StoryboardName;
FOUNDATION_EXPORT NSString *const _DP_NavControllerLogin;
FOUNDATION_EXPORT NSString *const _DP_CaptureViewStrbdID;
FOUNDATION_EXPORT NSString *const _DP_PostViewStrbdID;
FOUNDATION_EXPORT NSString *const _DP_ProfileViewStrbdID;

//  Other App Constants

FOUNDATION_EXPORT NSString *const _DP_FontHelveticaNeueLight;
FOUNDATION_EXPORT NSString *const _DP_FontHelveticaNeueBold;
FOUNDATION_EXPORT NSString *const _DP_FontHelveticaNeueMedium;

@end
