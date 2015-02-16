//
//  NewsViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "NewsViewController.h"
#import "InfoCell.h"

static NSString *REUSENewsCell = @"InfoCell";

@interface NewsViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    __weak IBOutlet UITableView *tblNews;
    
    NSArray *arrUsers;
}

@end

@implementation NewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setTitle:@"Activity"];
    [self setupNewsView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Setup View

- (void)setupNewsView {
    [tblNews registerNib:[UINib nibWithNibName:@"InfoCell" bundle:nil] forCellReuseIdentifier:REUSENewsCell];
    [tblNews setSeparatorInset:UIEdgeInsetsZero];
    [tblNews setLayoutMargins:UIEdgeInsetsZero];
    
    arrUsers = [[NSArray alloc] initWithObjects:@"Martha", @"Mary", @"Alice", @"Sean", @"Thomas", nil];
}

#pragma mark - UITableView Delegate & DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *strFollow = [NSString stringWithFormat:@"%@ is following you.", [arrUsers objectAtIndex:indexPath.row]];
    InfoCell *cellInfo = [tableView dequeueReusableCellWithIdentifier:REUSENewsCell];
//    [cellInfo fillCellInfoWithInfo:[dictProfileInfo objectForKey:strKeyName]
//                           keyName:strKeyName];
    [cellInfo fillCellWithNews:strFollow];
    [cellInfo setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cellInfo;
}

@end
