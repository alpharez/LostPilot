//
//  Shader.fsh
//  LostPilot
//
//  Created by Steve Clement on 2/4/14.
//  Copyright (c) 2014 Alpharez. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
