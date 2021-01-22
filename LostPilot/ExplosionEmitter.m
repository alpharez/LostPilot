//
//  ExplosionEmitter.m
//  LostPilot
//
//  Created by Steve Clement on 2/6/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "ExplosionEmitter.h"
#import "SpaceObject.h"

@implementation ExplosionEmitter

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array {
    if(self = [super init]) {
        _program = program;
        _vertexBuffer = buffer;
        _vertexArray = array;
        _position = position;
        _finished = NO;
        _lifeTime = 0.0;
        self.cubes = [[NSMutableArray alloc] init];
        [self makeCubes];
    }
    return self;
}

-(void)makeCubes {
    // make some cubes with random speeds and x,y vectors.
    for(int i=0; i<5; i++) {
        SpaceObject *cube = [[SpaceObject alloc] initWithPosition:self.position
                                                          program:self.program
                                                           buffer:self.vertexBuffer
                                                            array:self.vertexArray];
        [self.cubes addObject:cube];
    }
}

-(void)endExplosion {
    [self.cubes removeAllObjects];
    self.finished = YES;
}

-(void)move {
    // call each cube's move method
    // limit space traveled or time before setting finished = YES
    _lifeTime += 0.5;
    if(self.lifeTime > 9.0) {
        [self endExplosion];
    }
    for(SpaceObject *cube in self.cubes) {
        [cube move];
    }
}

- (void)renderWithProjection:(GLKMatrix4)projectionMatrix {
    // go through each cube and render them.
    for(SpaceObject *cube in self.cubes) {
        [cube renderWithProjection:projectionMatrix];
    }
}

-(CGRect)boundingBox {
    return CGRectMake(self.position.x-1.0, self.position.y-1.0, 2.0, 2.0);
}

@end
