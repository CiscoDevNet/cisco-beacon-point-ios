//
//  OrganizationPageViewController.m
//  SampleApp
//
//  Created by Mist on 17/08/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "OrganizationPageViewController.h"
#import "SampleApp-Swift.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "Default.h"
@interface OrganizationPageViewController ()<QRReaderViewControllerDelegate>{
     NSArray * dataSource;
}
@property (nonatomic, strong) NSMutableArray *sectionMapping;
@property (nonatomic, strong) UINavigationController *navVc;
@property (nonatomic, strong) NSMutableDictionary *orgs;
@property (nonatomic, strong) NSMutableDictionary *tableEnvMapping;
@end

@implementation OrganizationPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
       [self refreshData:YES];
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
- (IBAction)addOrgAction:(id)sender {
    UIButton *button=(UIButton*)sender;
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Method to add organization" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    [controller setModalPresentationStyle:UIModalPresentationPopover];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"QR Code" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self displayQRCode];
        [controller dismissViewControllerAnimated:true completion:nil];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [controller dismissViewControllerAnimated:true completion:nil];
    }]];
    //
    UIPopoverPresentationController *popPresenter = [controller
                                                     popoverPresentationController];
    popPresenter.sourceView = button;
    popPresenter.sourceRect = button.bounds;
    [self.view.window.rootViewController presentViewController:controller animated:YES completion:nil];

}

-(void)displayQRCode{
    QRReaderViewController *qr = [[QRReaderViewController alloc] init];
    qr.delegate = self;
    self.navVc = [[UINavigationController alloc] initWithRootViewController:qr];
    [self.view.window.rootViewController presentViewController:self.navVc animated:true completion:nil];
}

-(void)receivedQRContent:(NSString *)secret image:(UIImage *)image{
    __weak OrganizationPageViewController *weakSelf = self;
    [self.navVc dismissViewControllerAnimated:true completion:^{
        OrgsManager *orgManager = [[OrgsManager alloc] init];
        MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hub.userInteractionEnabled = true;
        hub.labelText = @"Enrolling device. Please wait";
        [orgManager addOrgSecrets:secret onComplete:^(NSString *message, BOOL status) {
            [Default performBlockOnMainThread:^{
                hub.labelText = message;
                [hub hide:true afterDelay:1.0];
            }];
            [OrgsManager debugConfigs];
            OrganizationPageViewController *strongSelf = weakSelf;
            [strongSelf refreshData:true];
        }];
    }];
}




 #pragma mark - UITableViewDataSource
 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
     return 1;
 }
 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
     return self.
     sectionMapping.count;
 }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
     static NSString *CellIdentifier = @"homeTableViewCell";
     UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
     if (!cell) {
         cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
     }
 
     cell.textLabel.text =   self.sectionMapping[indexPath.section];
     cell.textLabel.text = [cell.textLabel.text stringByReplacingOccurrencesOfString:@".json" withString:@""];
     cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
     return cell;
 }
 
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  
    NSString *fileName = [self.sectionMapping objectAtIndex:indexPath.row];
    fileName = [fileName stringByReplacingOccurrencesOfString:@".json" withString:@""];
    
    NSString *envType = @"P";
    NSDictionary *orgJSON = [[OrgsManager defaultManager] readOrg:envType filename:fileName];
    NSMutableDictionary *newConfig = [[Default currentSettings] mutableCopy];
    newConfig[@"environment-name"] = fileName;
    newConfig[@"tokenID"] = orgJSON[@"org_id"];
    newConfig[@"tokenSecret"] = orgJSON[@"secret"];
    newConfig[@"tokenFileused"] = @{@"envType":envType,@"filename":fileName};
    newConfig[@"tokenHostname"] = orgJSON[@"hostname"];
    newConfig[@"tokenEnvType"] = orgJSON[@"envType"];
    newConfig[@"tokenTopic"] = orgJSON[@"topic"];
    [Default updateSettings:newConfig withCompletion:nil];
    [self performSegueWithIdentifier:@"demoSegue" sender:nil];
    
}


-(void)refreshData:(bool)reloadTable{
    [[OrgsManager defaultManager] importOrgsIfNeeded];
    self.orgs = [[NSMutableDictionary alloc] init];
    self.orgs = [[[OrgsManager defaultManager] getOrgs] mutableCopy];
    
    self.sectionMapping = [[NSMutableArray alloc] init];
    //    [self.sectionMapping addObjectsFromArray:orgArray];
    if ([self.orgs objectForKey:@"P"]) {
        [self.tableEnvMapping setObject:@"P" forKey:[NSNumber numberWithUnsignedInteger:self.sectionMapping.count]];
        [self.sectionMapping addObjectsFromArray:[self.orgs objectForKey:@"P"]];
    }
    if ([self.orgs objectForKey:@"S"]) {
        [self.tableEnvMapping setObject:@"S" forKey:[NSNumber numberWithUnsignedInteger:self.sectionMapping.count]];
        [self.sectionMapping addObjectsFromArray:[self.orgs objectForKey:@"S"]];
    }
    if ([self.orgs objectForKey:@"D"]) {
        [self.tableEnvMapping setObject:@"D" forKey:[NSNumber numberWithUnsignedInteger:self.sectionMapping.count]];
        [self.sectionMapping addObjectsFromArray:[self.orgs objectForKey:@"D"]];
    }
    if (reloadTable) {
        [Default performBlockOnMainThread:^{
            [orgTableView reloadData];
        }];
    }
}



@end
