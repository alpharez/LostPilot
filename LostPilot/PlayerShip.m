//
//  PlayerShip.m
//  OpenGLES5
//
//  Created by Steve Clement on 1/31/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "PlayerShip.h"

@interface PlayerShip() {
    GLuint _vertexShipBuffer;
    GLuint _vertexShipArray;
}
@end

@implementation PlayerShip

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array {
    if(self = [super init]) {
        self.program = program;
        self.vertexBuffer = buffer;
        self.vertexArray = array;
        self.position = position;
        //[self setupModel];
        self.color = GLKVector3Make(0.75, 0.75, 0.75); // green
        self.speed = 0.0;
    }
    return self;
}

-(void)setupModel {
    
    //glGenVertexArraysOES(1, &_vertexShipArray);
    //glBindVertexArrayOES(self.vertexArray);
    
    //glGenBuffers(1, &_vertexShipBuffer);
    //glBindBuffer(GL_ARRAY_BUFFER, _vertexShipBuffer);
    //glBufferData(GL_ARRAY_BUFFER, sizeof(gShip1VertexData), gShip1VertexData, GL_STATIC_DRAW);
    
    //glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, ((char *)NULL + (12)));
    
    glBindVertexArrayOES(0);
    
}

- (void)renderWithProjection:(GLKMatrix4)projectionMatrix {
    glBindVertexArrayOES(self.vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glUseProgram(self.program);
    
    // Compute the model view matrix for the object rendered with ES2
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI/2, 1.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, self.rotation, 0.0f, 0.0f, 1.0f);
    
    self.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    GLint cubeColor = glGetUniformLocation(self.program, "cubeColor");
    glUniform3f(cubeColor, self.color.r, self.color.g, self.color.b);
    GLint mvprojMatrix = glGetUniformLocation(self.program, "modelViewProjectionMatrix");
    glUniformMatrix4fv(mvprojMatrix, 1, 0, self.modelViewProjectionMatrix.m);
    GLint nrmlMatrix = glGetUniformLocation(self.program, "normalMatrix");
    glUniformMatrix3fv(nrmlMatrix, 1, 0, self.normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 2358);
    glBindVertexArrayOES(0);
}

-(void)tilt:(GLfloat)amount {
    // only tilt so much.. about 45 degrees, don't flip over!
    if( (amount > 0 && self.rotation > -M_PI/4) || (amount < 0 && self.rotation < M_PI/4) ) {
        self.rotation -= amount;
    }
}

-(void)move:(GLKVector3)vector {
    self.position = GLKVector3Add(self.position, vector);
}

-(CGRect)boundingBox {
    return CGRectMake(self.position.x-1.5, self.position.y-1.5, 3.0, 3.0);
}

@end
