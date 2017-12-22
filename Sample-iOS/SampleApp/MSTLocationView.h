//
//  MSTLocationView.h
//  MistSDK
//
//  Created by Mist on 8/6/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static const CGSize kMSTLocationViewSize = {5, 5};

@interface MSTLocationView : UIView

@property (nonatomic, strong) UIImageView *locationImageView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIImageView *headingView;
@property (nonatomic, strong) UIImageView *sphereView;
@property (nonatomic, assign) BOOL hasMoved;
@property (nonatomic, assign) BOOL isMainDot;
@property (nonatomic, assign) bool isMotioning;

-(void)start;
-(void)stop;

-(void)showMotion:(bool)show;
-(void)renderColor:(UIColor *)color;

@end
