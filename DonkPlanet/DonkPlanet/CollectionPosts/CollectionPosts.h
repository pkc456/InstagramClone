//
//  CollectionPosts.h
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionPosts : UIView

- (void)setArrayToShow:(NSMutableArray *)arrPosts;

@property (assign, nonatomic) BOOL postsFetched;

@end
