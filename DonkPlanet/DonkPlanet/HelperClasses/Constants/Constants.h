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

@interface Constants : NSObject

//  Controller Storyboard IDs

FOUNDATION_EXPORT NSString *const _DP_StoryboardName;
FOUNDATION_EXPORT NSString *const _DP_NavControllerLogin;
FOUNDATION_EXPORT NSString *const _DP_CaptureViewStrbdID;

//  Other App Constants

FOUNDATION_EXPORT NSString *const _DP_FontHelveticaNeueLight;
FOUNDATION_EXPORT NSString *const _DP_FontHelveticaNeueBold;

@end
