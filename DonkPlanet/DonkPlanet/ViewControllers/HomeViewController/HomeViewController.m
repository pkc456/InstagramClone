//
//  FirstViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "HomeViewController.h"
#import "LoginViewController.h"
#import "HomeCell.h"

@interface HomeViewController () <UITableViewDataSource, UITableViewDelegate, HomeCellDelegate> {
    
    __weak IBOutlet UIImageView *imgSplash;
    __weak IBOutlet UITableView *tblViewPost;
    __weak IBOutlet UISegmentedControl *segmentPosts;
    
    UIView *viewLoading;
    NSMutableArray *arrPosts;
    NSMutableDictionary *dictPosts;
    NSInteger lastPlayingIndex;
    NSMutableDictionary *dictLastPlayingInfo;
}

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [tblViewPost registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil]
      forCellReuseIdentifier:@"PostCell"];
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkUserLogin];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar {
    
    [self.navigationItem setTitle:@"Home"];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setShadowImage:[UIImage imageNamed:@"TransparentPixel"]];
    // "Pixel" is a solid white 1x1 image.
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"Pixel"] forBarMetrics:UIBarMetricsDefault];
}

#pragma mark - Check User Login

- (void)checkUserLogin {
    
    PFUser *currentUser = [PFUser currentUser];

    if (!currentUser) {
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:_DP_StoryboardName
                                                                 bundle:nil];
        LoginViewController *objLoginView = (LoginViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:_DP_NavControllerLogin];
        [self.navigationController presentViewController:objLoginView animated:NO completion:nil];
    }
    else {
        [self fetchUserPosts];
        [imgSplash setHidden:YES];
    }
}

#pragma mark - Fetch User Posts

- (void)fetchUserPosts {
    
    if (!dictPosts)
        dictPosts = [[NSMutableDictionary alloc] init];
    
    viewLoading = [_DPFunctions showLoadingViewWithText:@"Fetching..." inView:self.view];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query whereKey:@"fileUserID" equalTo:[PFUser currentUser].objectId];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [_DPFunctions hideLoadingView:viewLoading];
            // The find succeeded.
            NSLog(@"Successfully retrieved %d scores.", objects.count);
            // Do something with the found objects
            arrPosts = nil;
            
            NSMutableArray *arrImages = [[NSMutableArray alloc] init];
            NSMutableArray *arrVideos = [[NSMutableArray alloc] init];
            
            for (NSInteger i = 0; i < [objects count]; i ++) {
                PFObject *objAtIndex = (PFObject *)[objects objectAtIndex:i];
                if ([[objAtIndex objectForKey:@"fileType"] intValue] == PostTypeImage)
                    [arrImages addObject:objAtIndex];
                else
                    [arrVideos addObject:objAtIndex];
            }
            [dictPosts removeAllObjects];
            [dictPosts setObject:arrImages forKey:[NSNumber numberWithInt:PostTypeImage]];
            [dictPosts setObject:arrVideos forKey:[NSNumber numberWithInt:PostTypeVideo]];
            
            arrPosts = [dictPosts objectForKey:[NSNumber numberWithInt:segmentPosts.selectedSegmentIndex]];
            [tblViewPost reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Unable to fetch any posts right now"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil] show];
        }
    }];
}

#pragma mark - Bar Button Action

- (IBAction)fetchUserPostsFromParse:(id)sender {
    [self fetchUserPosts];
}

#pragma mark - Segment Methods

- (IBAction)segmentValueChanged:(UISegmentedControl *)segmentControl {
    arrPosts = [dictPosts objectForKey:[NSNumber numberWithInt:segmentControl.selectedSegmentIndex]];
    [tblViewPost reloadData];
}

#pragma mark - HomeCell Delegate

- (void)updateLastPlayingIndex:(NSInteger)playingIndex
                  withSeekTime:(CGFloat)seekTime {
    
    lastPlayingIndex = playingIndex;
    
//    if (!dictLastPlayingInfo)
//        dictLastPlayingInfo = [[NSMutableDictionary alloc] init];
//    else
//        [dictLastPlayingInfo removeAllObjects];
//    
//    [dictLastPlayingInfo setObject:[NSNumber numberWithFloat:seekTime]
//                            forKey:[NSNumber numberWithInteger:playingIndex]];
}

#pragma mark - UITableView Delegate & DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([[UIScreen mainScreen] bounds].size.width + 124);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [arrPosts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HomeCell *cellHome = [tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    [cellHome setDelegate:self];
    PFObject *objPosted = (PFObject *)[arrPosts objectAtIndex:indexPath.row];
    [cellHome fillHomeCellWithWithObject:objPosted
                           withRowNumber:indexPath.row
                     withLastPlayingIndex:lastPlayingIndex];
    return cellHome;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
