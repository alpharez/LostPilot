//
//  SpaceObject.m
//  OpenGLES5
//
//  Created by Steve Clement on 1/31/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "SpaceObject.h"

@interface SpaceObject() {

}

@end

@implementation SpaceObject

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array {
    if(self = [super init]) {
        _program = program;
        _vertexBuffer = buffer;
        _vertexArray = array;
        _position = position;
        _speed = [self randomValueBetween:-2.0 andValue:2.0];
        [self setupModel];
        switch (arc4random() % 6 ) {
            case 0:
                _color = GLKVector3Make(1.0, 0.0, 0.0);
                _dropspeed = -0.3;
                break;
            case 1:
                _color = GLKVector3Make(0.0, 1.0, 0.0);
                _dropspeed = -0.4;
                break;
            case 2:
                _color = GLKVector3Make(1.0, 1.0, 0.0);
                _dropspeed = -0.2;
                break;
            case 3:
                _color = GLKVector3Make(0.0, 1.0, 1.0);
                _dropspeed = -0.6;
                break;
            case 4:
                _color = GLKVector3Make(1.0, 0.0, 1.0);
                _dropspeed = -0.7;
                break;
            case 5:
                _color = GLKVector3Make(0.5, 0.5, 0.5);
                _dropspeed = -0.9;
                break;
            default:
                _color = GLKVector3Make(0.0, 1.0, 0.0);
                _dropspeed = -0.5;
                break;
        }
    }
    return self;
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)setupModel {
    
    //glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    //glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    //glBufferData(GL_ARRAY_BUFFER, sizeof(gSpaceObjectVertexData), gSpaceObjectVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, ((char *)NULL + (12)));
    
    glBindVertexArrayOES(0);
    
}

-(void)move {
    _rotation += 0.1;
    _position = GLKVector3Add(_position, GLKVector3Make(_speed, _dropspeed, 0.0));
}

- (void)renderWithProjection:(GLKMatrix4)projectionMatrix {
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glUseProgram(_program);
    
    // Compute the model view matrix for the object rendered with ES2
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    //modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    GLint cubeColor = glGetUniformLocation(_program, "cubeColor");
    glUniform3f(cubeColor, _color.r, _color.g, _color.b);
    GLint mvprojMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    glUniformMatrix4fv(mvprojMatrix, 1, 0, _modelViewProjectionMatrix.m);
    GLint nrmlMatrix = glGetUniformLocation(_program, "normalMatrix");
    glUniformMatrix3fv(nrmlMatrix, 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    //glBindVertexArrayOES(0);
}

-(CGRect)boundingBox {
    return CGRectMake(self.position.x-1.0, self.position.y-1.0, 2.0, 2.0);
}

@end
