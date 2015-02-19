//
//  UsersView.h
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersView : UIView

@property (assign, nonatomic) BOOL deviceContacts;
@property (assign, nonatomic) BOOL followers;
@property (assign, nonatomic) BOOL fetched;
@property (assign, nonatomic) BOOL errorFetch;

- (void)setArrayToShow:(NSMutableArray *)arrUsers;

@end
