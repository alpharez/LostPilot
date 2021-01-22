//
//  WallObject.h
//  LostPilot
//
//  Created by Steve Clement on 2/5/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "SpaceObject.h"

@interface WallObject : SpaceObject

-(id)initWithPosition:(GLKVector3)position program:(GLuint)program buffer:(GLint)buffer array:(GLint)array;
-(void)move;
-(CGRect)boundingBox;

@end
