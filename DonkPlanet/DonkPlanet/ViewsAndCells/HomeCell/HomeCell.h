//
//  HomeCell.h
//  DonkPlanet
//
//  Created by Varun on 27/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HomeCellDelegate <NSObject>

- (void)updateLastPlayingIndex:(NSInteger)playingIndex
                  withSeekTime:(CGFloat)seekTime;
- (void)deleteTheObject:(PFObject *)objToDelete;

@end

@interface HomeCell : UITableViewCell

@property (assign, nonatomic) id<HomeCellDelegate> delegate;

- (void)fillHomeCellWithWithObject:(PFObject *)objPost
                     withRowNumber:(NSInteger)rowNumber
              withLastPlayingIndex:(NSInteger)lastIndex;
- (void)removeAVPlayer;

@end
