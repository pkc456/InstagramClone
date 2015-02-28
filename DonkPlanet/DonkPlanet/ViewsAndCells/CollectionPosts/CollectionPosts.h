//
//  CollectionPosts.h
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CollectionPostDelegate <NSObject>

- (void)openPostViewForObject:(PFObject *)objPost;

@end

@interface CollectionPosts : UIView

- (void)setArrayToShow:(NSMutableArray *)arrPosts;

@property (assign, nonatomic) BOOL postsFetched;
@property (assign, nonatomic) id<CollectionPostDelegate> delegate;

@end
