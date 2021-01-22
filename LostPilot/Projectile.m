//
//  Projectile.m
//  OpenGLES5
//
//  Created by Steve Clement on 1/31/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "Projectile.h"

@interface Projectile() {
    
}
@end

@implementation Projectile

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array speed:(float)speed {
    if(self = [super init]) {
        self.program = program;
        self.vertexArray = array;
        self.vertexBuffer = buffer;
        self.position = position;
        //[self setupModel];
        self.color = GLKVector3Make(0.6, 0.6, 0.6);
        //self.speed = 1.0;
        self.speed = speed;
    }
    return self;
}

-(void)move {
    self.rotation += 0.3;
    self.position = GLKVector3Add(self.position, GLKVector3Make(0.0, self.speed, 0.0));
}

@end
