//
//  Projectile.h
//  OpenGLES5
//
//  Created by Steve Clement on 1/31/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "SpaceObject.h"

@interface Projectile : SpaceObject

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array speed:(float)speed;

@end
