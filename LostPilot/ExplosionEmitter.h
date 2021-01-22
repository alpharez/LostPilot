//
//  ExplosionEmitter.h
//  LostPilot
//
//  Created by Steve Clement on 2/6/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface ExplosionEmitter : NSObject

@property (nonatomic) GLKVector3 position;
@property (nonatomic) GLuint program;
@property (nonatomic) GLuint vertexBuffer;
@property (nonatomic) GLuint vertexArray;
@property (nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (nonatomic) GLKMatrix3 normalMatrix;
@property (nonatomic) GLfloat rotation;
@property (nonatomic) GLKVector3 color;
@property (nonatomic) GLfloat speed;
@property (nonatomic, strong) NSMutableArray *cubes;    // cubes make up the explosion
@property (nonatomic) float lifeTime;   // how long does each cube live?
@property (nonatomic) BOOL finished;

-(id)initWithPosition:(GLKVector3)position program:(GLuint) program buffer:(GLint)buffer array:(GLint)array;
- (void)renderWithProjection:(GLKMatrix4)projectionMatrix;
-(void)move;
-(CGRect)boundingBox;   // return array of bounding boxes instead

@end
