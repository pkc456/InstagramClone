//
//  SecondViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchCollectionCell.h"

static NSString *REUSESearchCell = @"REUSECollectionSearch";

@interface SearchViewController () <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    
    __weak IBOutlet UILabel *lblNoSearchResults;
    __weak IBOutlet UICollectionView *collectionViewSearch;
    
    UISearchBar *searchBarPosts;
    NSMutableArray *arrSearchedPosts;
}

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.navigationItem setTitle:@"Search"];
    [self setupSearchView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setting up View

- (void)setupSearchView {
    
    searchBarPosts = [[UISearchBar alloc]initWithFrame:CGRectMake(10, 10, self.navigationController.navigationBar.bounds.size.width - 20, self.navigationController.navigationBar.bounds.size.height/2)];
    searchBarPosts.delegate = self;
    [self.navigationController.navigationBar addSubview:searchBarPosts];
    
    UINib *collCellNib = [UINib nibWithNibName:@"SearchCollectionCell" bundle:nil];
    [collectionViewSearch registerNib:collCellNib forCellWithReuseIdentifier:REUSESearchCell];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(104, 104)];
    [flowLayout setMinimumInteritemSpacing:2.0f];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setSectionInset:UIEdgeInsetsMake(2, 2, 2, 2)];
    
    [collectionViewSearch setCollectionViewLayout:flowLayout];
}

#pragma mark - Search Bar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [arrSearchedPosts removeAllObjects];
    [collectionViewSearch reloadData];
    
    PFQuery *searchQuery = [PFQuery queryWithClassName:@"Post"];
    [searchQuery whereKey:@"fileDesc" containsString:searchBar.text];
    [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [lblNoSearchResults setHidden:YES];
            arrSearchedPosts = nil;
            arrSearchedPosts = [[NSMutableArray alloc] initWithArray:objects];
            [collectionViewSearch performSelectorOnMainThread:@selector(reloadData)
                                                   withObject:nil waitUntilDone:YES];
//            [collectionViewSearch reloadData];
        }
        else {
            [lblNoSearchResults setHidden:NO];
            [lblNoSearchResults setText:@"No posts found for your search query"];
        }
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
}

#pragma mark - UICollectionView Delegate & DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [arrSearchedPosts count];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SearchCollectionCell *cellSearch = (SearchCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:REUSESearchCell forIndexPath:indexPath];
    [cellSearch fillSearchCellWithObject:(PFObject *)[arrSearchedPosts objectAtIndex:indexPath.row]];
    return cellSearch;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

@end
