//
//  PlayerShip.h
//  OpenGLES5
//
//  Created by Steve Clement on 1/31/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "SpaceObject.h"

@interface PlayerShip : SpaceObject

-(void)move:(GLKVector3)vector;
-(void)tilt:(GLfloat)amount;
-(CGRect)boundingBox;

@end
