//
//  CollectionPosts.m
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "CollectionPosts.h"
#import "SearchCollectionCell.h"

static NSString *REUSEPostCell = @"REUSECollectionSearch";

@interface CollectionPosts () {
    
    __weak IBOutlet UICollectionView *collectionPosts;
    __weak IBOutlet UIActivityIndicatorView *activityLoading;
    __weak IBOutlet UILabel *lblNoPosts;
    
    NSMutableArray *arrPosts;
}

@end

@implementation CollectionPosts

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    
    UINib *collCellNib = [UINib nibWithNibName:@"SearchCollectionCell" bundle:nil];
    [collectionPosts registerNib:collCellNib forCellWithReuseIdentifier:REUSEPostCell];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(104, 104)];
    [flowLayout setMinimumInteritemSpacing:2.0f];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setSectionInset:UIEdgeInsetsMake(2, 2, 2, 2)];
    
    [collectionPosts setCollectionViewLayout:flowLayout];
}

- (void)setArrayToShow:(NSMutableArray *)arrFetched {
    
    if (self.postsFetched) {
        [activityLoading stopAnimating];
        [lblNoPosts setHidden:[arrFetched count]];
        [collectionPosts setHidden:![arrFetched count]];
        if ([arrFetched count]) {
            arrPosts = arrFetched;
            [collectionPosts reloadData];
        }
    }
}

#pragma mark - UICollectionView Delegate & DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [arrPosts count];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SearchCollectionCell *cellSearch = (SearchCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:REUSEPostCell forIndexPath:indexPath];
    [cellSearch fillSearchCellWithObject:(PFObject *)[arrPosts objectAtIndex:indexPath.row]];
    return cellSearch;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
