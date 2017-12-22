//
//  FloorPlanViewController.h
//  SampleApp
//
//  Created by Mist on 17/08/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FloorPlanViewController : UIViewController{
    
    IBOutlet UISwitch *snapToPathSwitch;
    IBOutlet UISwitch *showPathSwitch;
    IBOutlet UISwitch *wayFindingSwitch;
}

@property (strong, nonatomic) IBOutlet UIView *mainFlrView;
- (IBAction)snapToPathToggle:(id)sender;
- (IBAction)allPathToggle:(id)sender;
- (IBAction)wayfindingToggle:(id)sender;

@end
