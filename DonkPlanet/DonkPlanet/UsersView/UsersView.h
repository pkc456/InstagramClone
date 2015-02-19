//
//  UsersView.h
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UsersViewDelegate <NSObject>

- (void)updateFollowingUsers;

@end

@interface UsersView : UIView

@property (assign, nonatomic) BOOL deviceContacts;
@property (assign, nonatomic) BOOL followers;
@property (assign, nonatomic) BOOL fetched;
@property (assign, nonatomic) BOOL errorFetch;

@property (assign, nonatomic) id<UsersViewDelegate> delegate;

- (void)setArrayToShow:(NSMutableArray *)arrUsers;

@end
