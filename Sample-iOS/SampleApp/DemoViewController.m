//
//  DemoViewController.m
//  SampleApp
//
//  Created by Mist on 17/08/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "DemoViewController.h"
#import "FloorPlanViewController.h"

@interface DemoViewController (){
    NSArray * dataSource;
}

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dataSource = [NSArray arrayWithObjects:@"FloorPlan Demo",@"Virtual beacon Notification",nil];
    [demoListTableView reloadData];
    // Do any additional setup after loading the view.
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



 #pragma mark - UITableViewDataSource
 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
  }
 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return dataSource.count;
 }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        static NSString *CellIdentifier = @"homeTableViewCell";
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
 
        cell.textLabel.text =   [dataSource objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
 }
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"floorViewSegue" sender:nil];
        
    }
    else{
         [self performSegueWithIdentifier:@"vbnSegue" sender:nil];
        
    }
    
    
    //    FloorPlanViewController *flr = [[FloorPlanViewController alloc] init];
//    [self.navigationController pushViewController:flr animated:YES];
    

}

@end
