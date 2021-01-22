//
//  ViewController.h
//  LostPilot
//
//  Created by Steve Clement on 2/4/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

@property (weak, nonatomic) IBOutlet UILabel *ScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *GameOverLabel;

@end
