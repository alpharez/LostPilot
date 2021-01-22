//
//  EnemyShip.h
//  OpenGLES5
//
//  Created by Steve Clement on 2/1/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "SpaceObject.h"

@interface EnemyShip : SpaceObject

-(id)initWithPosition:(GLKVector3)position program:(GLuint)program buffer:(GLint)buffer array:(GLint)array;
-(void)move;
-(void)tilt:(GLfloat)amount;
-(CGRect)boundingBox;

@end
