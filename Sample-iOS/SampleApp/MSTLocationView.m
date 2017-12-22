//
//  MSTLocationView.m
//  MistSDK
//
//  Created by Mist on 8/6/15.
//  Copyright (c) 2015 Mist. All rights reserved.
//

#import "MSTLocationView.h"

@interface MSTLocationView () {
    dispatch_source_t timer;
    UIImageView *glowingCircle;
    UIImageView *glowingCircleWithMotion;
}
@end

@implementation MSTLocationView

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

-(void)setLocationLabel:(UILabel *)locationLabel{
    _locationLabel = locationLabel;
    [self addSubview:_locationLabel];
}

-(void)setLocationImageView:(UIImageView *)locationImageView{
    _locationImageView = locationImageView;
    [self addSubview:_locationImageView];
}

-(void)showMotion:(bool)show{
    if (show) {
        _isMotioning = true;
        glowingCircle.hidden = true;
        glowingCircleWithMotion.hidden = false;
        [self renderColor:[UIColor colorWithRed:1 green:0.855 blue:0.247 alpha:1]];
    } else {
        _isMotioning = false;
        glowingCircle.hidden = false;
        glowingCircleWithMotion.hidden = true;
        [self renderColor:[UIColor colorWithRed:0.072 green:0.593 blue:0.997 alpha:1.000]];
    }
}

-(void)renderColor:(UIColor *)color{
    [UIView animateWithDuration:0.5 animations:^{
        self.sphereView.layer.backgroundColor = color.CGColor;
        self.sphereView.layer.shadowColor = color.CGColor;
    }];
}

-(void)initialize{
    self.frame = CGRectMake(0, 0, kMSTLocationViewSize.width, kMSTLocationViewSize.height);
    
    _isMotioning = false;
    
    self.headingView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"heading_arrow_gradient_inverse"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.headingView.tintColor = [UIColor colorWithRed:0.072 green:0.593 blue:0.997 alpha:1.000];
    self.headingView.hidden = true;
    [self addSubview:self.headingView];
    self.headingView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headingView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headingView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headingView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headingView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50]];
    self.headingView.layer.anchorPoint = CGPointMake(0.5, 1);
    
    glowingCircle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"active_grouped"]];
    glowingCircle.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
    glowingCircle.layer.opacity = 0;
    glowingCircle.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    glowingCircle.layer.shouldRasterize = true;
    [self addSubview:glowingCircle];
    glowingCircle.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircle attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircle attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    glowingCircleWithMotion = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"active_grouped_yellow"]];
    glowingCircleWithMotion.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
    glowingCircleWithMotion.layer.opacity = 0;
    glowingCircleWithMotion.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    glowingCircleWithMotion.layer.shouldRasterize = true;
    [self addSubview:glowingCircleWithMotion];
    glowingCircleWithMotion.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircleWithMotion attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircleWithMotion attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircleWithMotion attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:glowingCircleWithMotion attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    self.sphereView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    self.sphereView.layer.borderWidth = 2;
    self.sphereView.layer.shadowRadius = 5;
    self.sphereView.backgroundColor = [UIColor colorWithRed:0.072 green:0.593 blue:0.997 alpha:1.000];
    self.sphereView.layer.cornerRadius = 9;
    self.sphereView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.sphereView.layer.shadowOpacity = 1;
    self.sphereView.layer.shadowColor = [UIColor colorWithRed:0 green:0.545 blue:0.655 alpha:1].CGColor;
    self.sphereView.layer.shadowOffset = CGSizeMake(0, 0);
    self.sphereView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.sphereView.layer.shouldRasterize = true;
    [self setLocationImageView:self.sphereView];
    self.sphereView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sphereView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sphereView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sphereView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:18]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sphereView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:18]];
    
    UILabel *label = [[UILabel alloc] init];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:10];
    [label setTextColor:[UIColor blackColor]];
    [self setLocationLabel:label];
    label.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:-10]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:80]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:15]];
}

-(void)start{
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("com.mist.mist.bluedot", DISPATCH_QUEUE_SERIAL));
    if (timer) {
        dispatch_source_set_timer(timer, 0, 2*NSEC_PER_SEC, 1*NSEC_PER_SEC/10);
        dispatch_source_set_event_handler(timer, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_isMotioning) {
                    [UIView animateWithDuration:1.8 animations:^{
//                        glowingCircleWithMotion.alpha = 0;
//                        glowingCircleWithMotion.transform = CGAffineTransformMakeScale(0.8, 0.8);
                        glowingCircleWithMotion.layer.opacity = 0;
                        glowingCircleWithMotion.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
                    } completion:^(BOOL finished) {
//                        glowingCircleWithMotion.alpha = 1;
//                        glowingCircleWithMotion.transform = CGAffineTransformMakeScale(0.1, 0.1);
                        glowingCircleWithMotion.layer.opacity = 1;
                        glowingCircleWithMotion.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);

                    }];
                } else {
                    [UIView animateWithDuration:1.8 animations:^{
                        glowingCircle.alpha = 0;
                        glowingCircle.transform = CGAffineTransformMakeScale(0.8, 0.8);
//                        glowingCircle.layer.opacity = 0;
//                        glowingCircle.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
                    } completion:^(BOOL finished) {
                        glowingCircle.alpha = 1;
                        glowingCircle.transform = CGAffineTransformMakeScale(0.1, 0.1);
                        glowingCircle.layer.opacity = 1;
                        glowingCircle.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
                    }];
                }
            });
        });
        dispatch_resume(timer);
    }
}

-(void)stop{
    dispatch_source_cancel(timer);
    timer = nil;
}

-(void)dealloc{
    [self stop];
}

@end