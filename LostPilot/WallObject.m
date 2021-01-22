//
//  WallObject.m
//  LostPilot
//
//  Created by Steve Clement on 2/5/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

#import "WallObject.h"

@implementation WallObject

-(id)initWithPosition:(GLKVector3)position  program:(GLuint)program buffer:(GLint)buffer array:(GLint)array {
    if(self = [super init]) {
        self.program = program;
        self.vertexArray = array;
        self.vertexBuffer = buffer;
        self.position = position;
        //[self setupModel];
        self.color = GLKVector3Make(0.6, 0.6, 0.6);
        self.speed = -1.2;
    }
    return self;
}

- (void)renderWithProjection:(GLKMatrix4)projectionMatrix {
    glBindVertexArrayOES(self.vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glUseProgram(self.program);
    
    // Compute the model view matrix for the object rendered with ES2
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, M_PI*2, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, self.rotation, 0.0f, 1.0f, 0.0f);
    
    
    self.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    GLint cubeColor = glGetUniformLocation(self.program, "cubeColor");
    glUniform3f(cubeColor, self.color.r, self.color.g, self.color.b);
    GLint mvprojMatrix = glGetUniformLocation(self.program, "modelViewProjectionMatrix");
    glUniformMatrix4fv(mvprojMatrix, 1, 0, self.modelViewProjectionMatrix.m);
    GLint nrmlMatrix = glGetUniformLocation(self.program, "normalMatrix");
    glUniformMatrix3fv(nrmlMatrix, 1, 0, self.normalMatrix.m);
    
    //glDrawArrays(GL_TRIANGLES, 0, 108);
    glDrawArrays(GL_TRIANGLES, 0, 84);
    glBindVertexArrayOES(0);
}
 

-(void)move {
    self.position = GLKVector3Add(self.position, GLKVector3Make(0.0, self.speed, 0.0));
}

-(CGRect)boundingBox {
    return CGRectMake(self.position.x-8.0, self.position.y-1.5, 16.0, 3.0);
}

@end
